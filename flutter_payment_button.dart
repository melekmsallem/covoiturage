import 'package:flutter/material.dart';
import 'flutter_payment_service.dart';
import 'flutter_payment_screen.dart';

class PaymentButton extends StatefulWidget {
  final int reservationId;
  final double amount;
  final String tripInfo;
  final String driverName;
  final String bookingStatus;
  final VoidCallback? onPaymentCompleted;

  const PaymentButton({
    Key? key,
    required this.reservationId,
    required this.amount,
    required this.tripInfo,
    required this.driverName,
    required this.bookingStatus,
    this.onPaymentCompleted,
  }) : super(key: key);

  @override
  State<PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends State<PaymentButton> {
  bool _isLoading = false;
  PaymentService.Payment? _payment;
  PaymentService.PaymentStatus? _paymentStatus;

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    if (widget.bookingStatus != 'CONFIRMED') return;

    setState(() {
      _isLoading = true;
    });

    try {
      final payment = await PaymentService.getPaymentForReservation(widget.reservationId);
      final status = await PaymentService.getPaymentStatus(widget.reservationId);
      
      setState(() {
        _payment = payment;
        _paymentStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _shouldShowPaymentButton {
    // Only show payment button for confirmed bookings
    if (widget.bookingStatus != 'CONFIRMED') return false;
    
    // Show if no payment exists or payment is pending/failed
    return _payment == null || 
           _payment!.isPending || 
           _payment!.isFailed;
  }

  bool get _isPaymentCompleted {
    return _paymentStatus == PaymentService.PaymentStatus.COMPLETED;
  }

  bool get _isPaymentPending {
    return _paymentStatus == PaymentService.PaymentStatus.PENDING;
  }

  bool get _isPaymentFailed {
    return _paymentStatus == PaymentService.PaymentStatus.FAILED;
  }

  String get _buttonText {
    if (_isPaymentCompleted) {
      return 'Payment Completed';
    } else if (_isPaymentPending) {
      return 'Complete Payment';
    } else if (_isPaymentFailed) {
      return 'Retry Payment';
    } else {
      return 'Pay Now';
    }
  }

  IconData get _buttonIcon {
    if (_isPaymentCompleted) {
      return Icons.check_circle;
    } else if (_isPaymentPending) {
      return Icons.payment;
    } else if (_isPaymentFailed) {
      return Icons.refresh;
    } else {
      return Icons.payment;
    }
  }

  Color get _buttonColor {
    if (_isPaymentCompleted) {
      return Colors.green;
    } else if (_isPaymentFailed) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  Future<void> _navigateToPayment() async {
    if (_isPaymentCompleted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          reservationId: widget.reservationId,
          amount: widget.amount,
          tripInfo: widget.tripInfo,
          driverName: widget.driverName,
        ),
      ),
    );

    if (result == true) {
      // Payment was successful, refresh status
      await _checkPaymentStatus();
      
      // Notify parent widget
      if (widget.onPaymentCompleted != null) {
        widget.onPaymentCompleted!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (!_shouldShowPaymentButton && !_isPaymentCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: _isPaymentCompleted ? null : _navigateToPayment,
        icon: Icon(_buttonIcon, size: 18),
        label: Text(_buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: _buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

// Payment status indicator widget for use in lists
class PaymentStatusIndicator extends StatelessWidget {
  final PaymentService.PaymentStatus? status;
  final double amount;

  const PaymentStatusIndicator({
    Key? key,
    this.status,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              PaymentService.formatAmount(amount),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String statusText;

    switch (status!) {
      case PaymentService.PaymentStatus.COMPLETED:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        statusText = 'Paid';
        break;
      case PaymentService.PaymentStatus.PENDING:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.pending;
        statusText = 'Pending';
        break;
      case PaymentService.PaymentStatus.FAILED:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.error;
        statusText = 'Failed';
        break;
      case PaymentService.PaymentStatus.REFUNDED:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.refresh;
        statusText = 'Refunded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$statusText - ${PaymentService.formatAmount(amount)}',
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}








