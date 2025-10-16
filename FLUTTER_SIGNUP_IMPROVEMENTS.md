# 📱 Flutter Signup Improvements - Implementation Guide

## 🎯 Requirements

1. ✅ **Remove Admin from signup** - Only Passenger and Driver roles
2. ✅ **Phone verification with SMS** - Verify phone numbers during registration

---

## 🔧 Part 1: Remove Admin Role from Signup

### Current Issue
Line 33 in `signup_screen.dart`:
```dart
final List<String> _roles = ['PASSAGER', 'CONDUCTEUR', 'ADMIN'];
```

### ✅ Solution: Update signup_screen.dart

**File**: `covoiturage_app/lib/screens/auth/signup_screen.dart`

**Change line 33 from:**
```dart
final List<String> _roles = ['PASSAGER', 'CONDUCTEUR', 'ADMIN'];
```

**To:**
```dart
final List<String> _roles = ['PASSAGER', 'CONDUCTEUR'];
```

**That's it!** Admin role will no longer appear in signup.

---

## 📱 Part 2: Phone Verification with SMS

### Architecture Overview

```
User enters phone → Send OTP via SMS → User enters code → Verify → Complete signup
```

### Recommended Services for SMS

#### Option 1: Twilio (Most Popular) ⭐
- **Pros**: Reliable, global coverage, easy to integrate
- **Pricing**: Pay-as-you-go ($0.0075 per SMS)
- **Setup**: 15 minutes

#### Option 2: Firebase Phone Auth (Recommended for Flutter) ⭐⭐
- **Pros**: Built for Flutter, free tier, automatic verification
- **Pricing**: Free for reasonable usage
- **Setup**: 20 minutes

#### Option 3: AWS SNS
- **Pros**: AWS integration, scalable
- **Pricing**: $0.00645 per SMS
- **Setup**: 25 minutes

**My Recommendation**: **Firebase Phone Auth** (easiest for Flutter)

---

## 🚀 Implementation: Firebase Phone Auth

### Step 1: Add Dependencies

**File**: `covoiturage_app/pubspec.yaml`

Add these dependencies:
```yaml
dependencies:
  # Existing dependencies...
  
  # Add Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  
  # For SMS code input UI
  pin_code_fields: ^8.0.1
```

Run:
```bash
flutter pub get
```

---

### Step 2: Firebase Setup

#### A. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Create new project: "Covoiturage"
3. Enable Phone Authentication:
   - Go to Authentication → Sign-in method
   - Enable "Phone"
4. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

#### B. Configure Android
Place `google-services.json` in:
```
covoiturage_app/android/app/google-services.json
```

Update `android/app/build.gradle`:
```gradle
dependencies {
    // Add this
    implementation 'com.google.firebase:firebase-auth'
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // Add this
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

---

### Step 3: Create Phone Verification Service

**Create new file**: `covoiturage_app/lib/services/phone_verification_service.dart`

```dart
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
        phoneNumber: phoneNumber, // Format: +21612345678 (Tunisia)
        timeout: const Duration(seconds: 60),
        
        // Auto-verification (Android only)
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Auto-verification successful');
          if (onAutoVerified != null) {
            onAutoVerified();
          }
        },
        
        // Verification failed
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          onError(e.message ?? 'Verification failed');
        },
        
        // Code sent successfully
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent to $phoneNumber');
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        
        // Timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto-retrieval timeout');
          _verificationId = verificationId;
        },
        
        // For resending
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

      // Sign in with credential (just to verify, we'll sign out after)
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Verification successful
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

  // Resend OTP
  Future<void> resendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }
}
```

---

### Step 4: Create Phone Verification Screen

**Create new file**: `covoiturage_app/lib/screens/auth/phone_verification_screen.dart`

```dart
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
  String? _verificationId;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  void _sendOTP() {
    setState(() => _isLoading = true);

    // Format phone number: +216 12 345 678 → +21612345678
    String formattedPhone = widget.phoneNumber.replaceAll(' ', '');
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+216$formattedPhone'; // Tunisia country code
    }

    _phoneVerificationService.sendOTP(
      phoneNumber: formattedPhone,
      onCodeSent: (verificationId) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
          _verificationId = verificationId;
        });
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code sent to ${widget.phoneNumber}'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onError: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      },
      onAutoVerified: () {
        // Auto-verification successful (Android only)
        widget.onVerificationSuccess();
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
      widget.onVerificationSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Phone icon
            Icon(
              Icons.phone_android,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Verification Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Enter the 6-digit code sent to',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            Text(
              widget.phoneNumber,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // PIN Code input
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _codeController,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 45,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: Colors.grey,
                selectedColor: Theme.of(context).primaryColor,
              ),
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: true,
              onCompleted: (code) => _verifyCode(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),
            
            // Verify button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Resend code
            TextButton(
              onPressed: _resendTimer == 0 && !_isLoading
                  ? () {
                      setState(() => _resendTimer = 60);
                      _sendOTP();
                    }
                  : null,
              child: Text(
                _resendTimer > 0
                    ? 'Resend code in $_resendTimer seconds'
                    : 'Resend code',
              ),
            ),
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
```

---

### Step 5: Update Signup Screen

**File**: `covoiturage_app/lib/screens/auth/signup_screen.dart`

**Add at the top:**
```dart
import 'phone_verification_screen.dart';
```

**Replace the existing `_signup()` method (around line 52):**

```dart
Future<void> _signup() async {
  if (!_formKey.currentState!.validate()) return;

  // Step 1: Verify phone number first
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PhoneVerificationScreen(
        phoneNumber: _phoneController.text.trim(),
        onVerificationSuccess: () async {
          // Phone verified, now create account
          Navigator.pop(context); // Close verification screen
          await _createAccount();
        },
      ),
    ),
  );
}

Future<void> _createAccount() async {
  setState(() => _isLoading = true);

  try {
    final response = await _authService.signUp(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      role: _selectedRole,
      licenseNumber: _selectedRole == 'CONDUCTEUR' ? _licenseController.text.trim() : null,
      vehicleModel: _selectedRole == 'CONDUCTEUR' ? _vehicleModelController.text.trim() : null,
      vehicleColor: _selectedRole == 'CONDUCTEUR' ? _vehicleColorController.text.trim() : null,
      vehiclePlate: _selectedRole == 'CONDUCTEUR' ? _vehiclePlateController.text.trim() : null,
      maxPassengers: _selectedRole == 'CONDUCTEUR' ? int.tryParse(_maxPassengersController.text) : null,
      preferredPaymentMethod: _selectedRole == 'PASSAGER' ? _paymentMethodController.text.trim() : null,
    );

    if (mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(response['token'], response);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Phone verified ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

---

## 🎨 Alternative: Backend SMS Implementation

If you prefer backend-controlled SMS (more secure):

### Backend Approach (Twilio)

#### 1. Add Twilio to Spring Boot

**File**: `build.gradle`

```gradle
dependencies {
    implementation 'com.twilio.sdk:twilio:9.14.1'
}
```

#### 2. Create SMS Service

**File**: `src/main/java/esprit/pfe/covoiturage_final/services/SmsService.java`

```java
@Service
public class SmsService {
    
    @Value("${twilio.account.sid}")
    private String accountSid;
    
    @Value("${twilio.auth.token}")
    private String authToken;
    
    @Value("${twilio.phone.number}")
    private String twilioPhoneNumber;
    
    @PostConstruct
    public void init() {
        Twilio.init(accountSid, authToken);
    }
    
    public String sendVerificationCode(String phoneNumber) {
        // Generate 6-digit code
        String code = String.format("%06d", new Random().nextInt(999999));
        
        // Send SMS
        Message message = Message.creator(
            new PhoneNumber(phoneNumber), // To
            new PhoneNumber(twilioPhoneNumber), // From
            "Your Covoiturage verification code is: " + code
        ).create();
        
        // Store code in Redis/Cache with expiration
        // redisTemplate.opsForValue().set("verify:" + phoneNumber, code, 5, TimeUnit.MINUTES);
        
        return code; // Return for verification
    }
    
    public boolean verifyCode(String phoneNumber, String code) {
        // Check against stored code
        // String storedCode = redisTemplate.opsForValue().get("verify:" + phoneNumber);
        // return code.equals(storedCode);
        return true; // Implement your logic
    }
}
```

#### 3. Add API Endpoints

```java
@PostMapping("/api/auth/send-verification")
public ResponseEntity<?> sendVerification(@RequestBody Map<String, String> request) {
    String phoneNumber = request.get("phoneNumber");
    String code = smsService.sendVerificationCode(phoneNumber);
    return ResponseEntity.ok(Map.of("message", "Code sent"));
}

@PostMapping("/api/auth/verify-phone")
public ResponseEntity<?> verifyPhone(@RequestBody Map<String, String> request) {
    String phoneNumber = request.get("phoneNumber");
    String code = request.get("code");
    boolean verified = smsService.verifyCode(phoneNumber, code);
    return ResponseEntity.ok(Map.of("verified", verified));
}
```

---

## 📋 Summary of Changes

### Quick Fixes (5 minutes)

**File 1**: `signup_screen.dart` line 33
```dart
// Remove 'ADMIN' from this line:
final List<String> _roles = ['PASSAGER', 'CONDUCTEUR'];
```

### Phone Verification (Full Implementation - 1-2 hours)

1. ✅ Add Firebase dependencies to `pubspec.yaml`
2. ✅ Setup Firebase project and download config files
3. ✅ Create `PhoneVerificationService` class
4. ✅ Create `PhoneVerificationScreen` widget
5. ✅ Update signup flow to include phone verification

---

## 🚀 Recommended Implementation Order

### Phase 1: Quick Win (Now)
1. Remove ADMIN from signup roles
2. Test signup works for Passenger/Driver only

### Phase 2: Phone Verification (This Week)
1. Choose SMS provider (Firebase recommended)
2. Setup Firebase project
3. Add dependencies
4. Implement phone verification service
5. Add verification screen
6. Update signup flow
7. Test end-to-end

---

## 💰 Cost Estimate

### Firebase Phone Auth
- **Free tier**: 10K verifications/month
- **After free tier**: $0.01 per verification
- **Your needs**: ~100-500 users = FREE

### Twilio (Alternative)
- **Cost**: $0.0075 per SMS
- **Your needs**: ~100-500 users = $0.75 - $3.75

**Recommendation**: Start with Firebase (free)

---

## ✅ Testing Checklist

After implementation:
- [ ] Admin role removed from signup
- [ ] Only Passenger and Driver options visible
- [ ] Phone number field validates format (+216...)
- [ ] SMS code sent successfully
- [ ] Code verification works
- [ ] Resend code after 60 seconds
- [ ] Auto-verification on Android
- [ ] Account created after phone verification
- [ ] Error handling for invalid codes
- [ ] Error handling for network issues

---

**Would you like me to:**
1. ✅ **Remove admin role now** (5 minutes)
2. ✅ **Set up full phone verification** (guided step-by-step)
3. ✅ **Create backend SMS service** (Twilio approach)
4. Something else?

Choose option 1 for quick fix, or option 2 for complete phone verification!


















