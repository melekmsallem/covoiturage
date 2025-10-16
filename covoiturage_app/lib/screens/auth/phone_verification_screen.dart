import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/phone_verification_service.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerificationSuccess;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerificationSuccess,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneVerificationService = PhoneVerificationService();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;
  bool _codeSent = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  void _sendOTP() {
    setState(() => _isLoading = true);

    // Format phone number for Tunisia: +216XXXXXXXX
    String formattedPhone = widget.phoneNumber.replaceAll(' ', '').replaceAll('-', '');
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+216$formattedPhone';
    }

    _phoneVerificationService.sendOTP(
      phoneNumber: formattedPhone,
      onCodeSent: (verificationId) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code sent to ${widget.phoneNumber}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onError: (error) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      onAutoVerified: () {
        // Auto-verification successful (Android only)
        if (mounted) {
          widget.onVerificationSuccess();
        }
      },
    );
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool verified = await _phoneVerificationService.verifyOTP(_codeController.text);

    setState(() => _isLoading = false);

    if (verified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verified successfully! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        // Add a small delay to ensure UI is stable before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          widget.onVerificationSuccess();
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        _codeController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Phone icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Verification Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Enter the 6-digit code sent to',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.phoneNumber,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 40),
            
            // Loading indicator while sending
            if (_isLoading && !_codeSent)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sending verification code...'),
                ],
              ),
            
            // PIN Code input
            if (_codeSent)
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _codeController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 55,
                  fieldWidth: 45,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.grey[100]!,
                  selectedFillColor: Colors.white,
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor: Colors.grey[300]!,
                  selectedColor: Theme.of(context).primaryColor,
                  borderWidth: 2,
                ),
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                onCompleted: (code) => _verifyCode(),
                onChanged: (value) {},
              ),
            const SizedBox(height: 32),
            
            // Verify button
            if (_codeSent)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Resend code
            if (_codeSent)
              TextButton.icon(
                onPressed: _resendTimer == 0 && !_isLoading
                    ? () {
                        setState(() => _resendTimer = 60);
                        _sendOTP();
                      }
                    : null,
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: _resendTimer == 0 ? Theme.of(context).primaryColor : Colors.grey,
                ),
                label: Text(
                  _resendTimer > 0
                      ? 'Resend code in $_resendTimer seconds'
                      : 'Resend code',
                  style: TextStyle(
                    color: _resendTimer == 0 ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Didn\'t receive the code? Check your SMS messages or try resending.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}













