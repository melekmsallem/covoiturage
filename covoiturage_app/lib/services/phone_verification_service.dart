import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneVerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _verificationId;
  int? _resendToken;

  // Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    Function()? onAutoVerified,
  }) async {
    try {
      // For web, we need to handle reCAPTCHA
      if (kIsWeb) {
        // Use a mock verification for web development
        print('Web phone verification - using mock for development');
        await Future.delayed(const Duration(seconds: 2));
        _verificationId = 'mock_verification_id_${DateTime.now().millisecondsSinceEpoch}';
        onCodeSent(_verificationId!);
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Auto-verification successful');
          if (onAutoVerified != null) {
            onAutoVerified();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent to $phoneNumber');
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto-retrieval timeout');
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      print('Phone verification error: $e');
      onError('Failed to send OTP: ${e.toString()}');
    }
  }

  // Verify OTP code
  Future<bool> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('No verification ID available');
      }

      // For web development, accept any 6-digit code
      if (kIsWeb) {
        print('Web OTP verification - accepting any 6-digit code for development');
        if (smsCode.length == 6 && RegExp(r'^\d{6}$').hasMatch(smsCode)) {
          return true;
        }
        return false;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Sign out from Firebase (we use our own backend auth)
        await _auth.signOut();
        return true;
      }
      
      return false;
    } catch (e) {
      print('OTP verification failed: $e');
      return false;
    }
  }
}








