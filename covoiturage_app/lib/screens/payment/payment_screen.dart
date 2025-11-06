import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
        print('DEBUG: Attempting to launch Stripe URL: $checkoutUrl');
        
        bool launchSuccess = false;
        
        // Try to launch the URL directly without checking canLaunchUrl first
        try {
          if (kIsWeb) {
            // For web, try platformDefault first (opens in same tab)
            try {
              await launchUrl(uri, mode: LaunchMode.platformDefault);
              launchSuccess = true;
              print('DEBUG: Successfully launched Stripe URL on web (platformDefault)');
            } catch (e) {
              print('DEBUG: PlatformDefault failed on web, trying externalApplication: $e');
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                launchSuccess = true;
                print('DEBUG: Successfully launched Stripe URL on web (externalApplication)');
              } catch (e2) {
                print('DEBUG: Both launch modes failed on web: $e2');
              }
            }
          } else {
            // For mobile, try externalApplication first (opens in browser app)
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              launchSuccess = true;
              print('DEBUG: Successfully launched Stripe URL on mobile (externalApplication)');
            } catch (e) {
              print('DEBUG: ExternalApplication failed on mobile, trying platformDefault: $e');
              try {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
                launchSuccess = true;
                print('DEBUG: Successfully launched Stripe URL on mobile (platformDefault)');
              } catch (e2) {
                print('DEBUG: Both launch modes failed on mobile: $e2');
              }
            }
          }
        } catch (e) {
          print('DEBUG: URL launch failed: $e');
        }
        
        // If all attempts failed, show the URL dialog as fallback
        if (!launchSuccess) {
          print('DEBUG: All launch attempts failed, showing URL dialog');
          _showStripeUrlDialog(checkoutUrl);
          return;
        }

        // Show dialog to check payment status after user returns
        _showPaymentCheckDialog();
        return;
      }

      // Fallback for non-card methods: simulate local processing
      final processedPayment = await PaymentService.processPayment(
        paymentId: payment.id,
        paymentMethod: _selectedPaymentMethod,
      );

      if (processedPayment.isCompleted) {
        Navigator.of(context).pop(true); // Return success
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

  void _showStripeUrlDialog(String checkoutUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.blue),
            SizedBox(width: 8),
            Text('Complete Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please complete your payment by clicking the link below or copying it to your browser:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                checkoutUrl,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'After completing payment, return to this app and the status will update automatically.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              // Try multiple launch modes to ensure it opens
              try {
                await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.platformDefault);
              } catch (e) {
                try {
                  await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
                } catch (e2) {
                  print('DEBUG: Failed to open URL: $e2');
                }
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentCheckDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.blue),
            SizedBox(width: 8),
            Text('Complete Payment'),
          ],
        ),
        content: const Text(
          'Please complete your payment in the browser window that opened.\n\n'
          'After completing payment, click "Check Payment Status" below to verify your payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _checkPaymentAfterStripe();
            },
            child: const Text('Check Payment Status'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentAfterStripe() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Check payment status
      final refreshed = await PaymentService.getPaymentForReservation(widget.reservationId);
      if (refreshed != null && refreshed.isCompleted) {
        _showSuccessDialog();
      } else {
        // Try a few more times with delays
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(seconds: 3));
          final polled = await PaymentService.getPaymentForReservation(widget.reservationId);
          if (polled != null && polled.isCompleted) {
            _showSuccessDialog();
            return;
          }
        }
        
        // Show manual check dialog
        _showManualCheckDialog();
      }
    } catch (e) {
      print('DEBUG: Error checking payment status: $e');
      _showErrorDialog('Failed to check payment status: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showManualCheckDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.orange),
            SizedBox(width: 8),
            Text('Payment Status'),
          ],
        ),
        content: const Text(
          'Payment not confirmed yet. This can happen if:\n\n'
          '• Payment is still being processed\n'
          '• You haven\'t completed the payment yet\n'
          '• There was an issue with the payment\n\n'
          'If you completed the payment, it should update shortly. '
          'You can also refresh this screen to check again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkExistingPayment(); // Refresh the payment status
            },
            child: const Text('Refresh Status'),
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
