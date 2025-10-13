import 'package:firebase_auth/firebase_auth.dart';

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
      onError('Failed to send OTP: ${e.toString()}');
    }
  }

  // Verify OTP code
  Future<bool> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('No verification ID available');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
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



