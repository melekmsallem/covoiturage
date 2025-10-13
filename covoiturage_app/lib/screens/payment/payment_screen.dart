import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final int reservationId;
  final double amount;
  final String tripInfo;
  final String driverName;

  const PaymentScreen({
    Key? key,
    required this.reservationId,
    required this.amount,
    required this.tripInfo,
    required this.driverName,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.CREDIT_CARD;
  bool _isProcessing = false;
  bool _isLoading = true;
  Payment? _existingPayment;

  @override
  void initState() {
    super.initState();
    _checkExistingPayment();
  }

  Future<void> _checkExistingPayment() async {
    // Check if user is authenticated
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Please log in to access payment information');
      return;
    }

    try {
      final payment = await PaymentService.getPaymentForReservation(widget.reservationId);
      setState(() {
        _existingPayment = payment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to check payment status: $e');
    }
  }

  Future<void> _processPayment() async {
    // Check if user is authenticated
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showErrorDialog('Please log in to process payments');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      Payment payment;
      
      if (_existingPayment == null) {
        // Create new payment
        payment = await PaymentService.createPayment(
          reservationId: widget.reservationId,
          paymentMethod: _selectedPaymentMethod,
          amount: widget.amount,
        );
      } else {
        payment = _existingPayment!;
      }

      // If user selected CASH or BANK_TRANSFER, do not attempt online processing.
      // Keep payment as PENDING and inform the user clearly.
      if (_selectedPaymentMethod == PaymentMethod.CASH) {
        await _showCashInfoDialog();
        return;
      }

      if (_selectedPaymentMethod == PaymentMethod.BANK_TRANSFER) {
        await _showBankTransferDialog();
        return;
      }

      if (_selectedPaymentMethod == PaymentMethod.CREDIT_CARD) {
        // Launch Stripe Checkout
        final checkoutUrl = await PaymentService.createStripeCheckoutSession(
          reservationId: widget.reservationId,
        );

        if (checkoutUrl == null) {
          _showErrorDialog('Unable to start Stripe Checkout.');
          return;
        }

        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showErrorDialog('Cannot open browser for payment.');
          return;
        }

        // After user returns, re-check payment status
        await Future.delayed(const Duration(seconds: 2));
        final refreshed = await PaymentService.getPaymentForReservation(widget.reservationId);
        if (refreshed != null && refreshed.isCompleted) {
          _showSuccessDialog();
        } else {
          // Optionally keep polling a couple of times
          for (int i = 0; i < 3; i++) {
            await Future.delayed(const Duration(seconds: 2));
            final polled = await PaymentService.getPaymentForReservation(widget.reservationId);
            if (polled != null && polled.isCompleted) {
              _showSuccessDialog();
              return;
            }
          }
          _showErrorDialog('Payment not confirmed yet. If charged, it will update shortly.');
        }
        return;
      }

      // Fallback for non-card methods: simulate local processing
      final processedPayment = await PaymentService.processPayment(
        paymentId: payment.id,
        paymentMethod: _selectedPaymentMethod,
      );

      if (processedPayment.isCompleted) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Payment failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Payment failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showCashInfoDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Cash Payment Selected'),
          ],
        ),
        content: const Text(
          'You chose to pay with cash.\n\nYou will pay the driver when the trip starts. '
          'Your booking shows payment as PENDING until the driver confirms receiving cash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBankTransferDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Colors.blue),
            SizedBox(width: 8),
            Text('Bank Transfer Selected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please make a bank transfer using the details below:'),
            const SizedBox(height: 12),
            const Text('Beneficiary: Covoiturage TN'),
            const Text('IBAN: TN59 1000 0000 0000 0000 0000'),
            const Text('BIC/SWIFT: BNTETNTT'),
            const SizedBox(height: 8),
            Text('Reference: Reservation #${widget.reservationId}'),
            const SizedBox(height: 12),
            const Text(
              'Your payment will remain PENDING until the transfer is received and validated.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment of ${PaymentService.formatAmount(widget.amount)} has been processed successfully.'),
            const SizedBox(height: 16),
            Text('Trip: ${widget.tripInfo}'),
            Text('Driver: ${widget.driverName}'),
            const SizedBox(height: 8),
            const Text(
              'You will receive a confirmation email shortly.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to previous screen with success
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Information Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Trip: ${widget.tripInfo}'),
                    Text('Driver: ${widget.driverName}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount to Pay:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          PaymentService.formatAmount(widget.amount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Status (if payment exists)
            if (_existingPayment != null) ...[
              Card(
                color: _existingPayment!.isCompleted 
                    ? Colors.green.shade50 
                    : _existingPayment!.isFailed 
                        ? Colors.red.shade50 
                        : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _existingPayment!.isCompleted 
                            ? Icons.check_circle 
                            : _existingPayment!.isFailed 
                                ? Icons.error 
                                : Icons.pending,
                        color: _existingPayment!.isCompleted 
                            ? Colors.green 
                            : _existingPayment!.isFailed 
                                ? Colors.red 
                                : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _existingPayment!.isCompleted 
                                  ? 'Payment Completed' 
                                  : _existingPayment!.isFailed 
                                      ? 'Payment Failed' 
                                      : 'Payment Pending',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Status: ${_existingPayment!.status}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Payment Method Selection
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...PaymentService.getAvailablePaymentMethods().map((method) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<PaymentMethod>(
                  title: Row(
                    children: [
                      Text(PaymentService.getPaymentMethodIcon(method)),
                      const SizedBox(width: 8),
                      Text(PaymentService.getPaymentMethodDisplayName(method)),
                    ],
                  ),
                  value: method,
                  groupValue: _selectedPaymentMethod,
                  onChanged: _existingPayment?.isCompleted == true 
                      ? null 
                      : (PaymentMethod? value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _existingPayment?.isCompleted == true 
                    ? null 
                    : _isProcessing 
                        ? null 
                        : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing Payment...'),
                        ],
                      )
                    : Text(
                        _existingPayment?.isCompleted == true 
                            ? 'Payment Completed' 
                            : 'Pay ${PaymentService.formatAmount(widget.amount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Security Notice
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your payment is secure and encrypted. We never store your payment details.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
