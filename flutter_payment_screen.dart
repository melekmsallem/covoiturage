import 'package:flutter/material.dart';
import 'flutter_payment_service.dart';

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
  PaymentService.PaymentMethod _selectedPaymentMethod = PaymentService.PaymentMethod.CREDIT_CARD;
  bool _isProcessing = false;
  bool _isLoading = true;
  PaymentService.Payment? _existingPayment;

  @override
  void initState() {
    super.initState();
    _checkExistingPayment();
  }

  Future<void> _checkExistingPayment() async {
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
    setState(() {
      _isProcessing = true;
    });

    try {
      PaymentService.Payment payment;
      
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

      // Process payment
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
        backgroundColor: Colors.blue,
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
                child: RadioListTile<PaymentService.PaymentMethod>(
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
                      : (PaymentService.PaymentMethod? value) {
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








