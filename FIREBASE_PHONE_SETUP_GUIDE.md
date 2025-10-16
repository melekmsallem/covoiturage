# 🔥 Firebase Phone Authentication - Complete Setup Guide

**Estimated Time**: 30 minutes  
**Difficulty**: Easy  
**Cost**: FREE

---

## 📋 Prerequisites Checklist

- [ ] Google account (for Firebase)
- [ ] Flutter app running (`covoiturage_app`)
- [ ] Internet connection

---

## 🚀 Part 1: Firebase Console Setup (10 minutes)

### Step 1: Create Firebase Project

1. **Go to**: https://console.firebase.google.com
2. Click **"Add project"** or **"Create a project"**
3. **Project name**: `Covoiturage`
4. Click **Continue**
5. **Google Analytics**: Disable (toggle off) - not needed for now
6. Click **Create project**
7. Wait ~30 seconds for setup
8. Click **Continue**

✅ **Checkpoint**: You should see the Firebase project dashboard

---

### Step 2: Enable Phone Authentication

1. In left sidebar, click **"Authentication"**
2. Click **"Get started"** button
3. Go to **"Sign-in method"** tab at the top
4. Scroll to find **"Phone"** provider
5. Click on **"Phone"**
6. Toggle **"Enable"** to ON
7. Click **"Save"**

✅ **Checkpoint**: Phone should show "Enabled" in the list

---

### Step 3: Add Android App

1. Click ⚙️ icon (Settings) → **"Project settings"**
2. Scroll down to **"Your apps"** section
3. Click **Android icon** (robot)
4. Fill in the form:
   - **Android package name**: `com.example.covoiturage_app`
     - (To verify: check `covoiturage_app/android/app/build.gradle`, find `applicationId`)
   - **App nickname** (optional): `Covoiturage App`
   - **Debug signing certificate** (optional): Leave empty for now
5. Click **"Register app"**
6. **IMPORTANT**: Click **"Download google-services.json"**
   - Save this file, you'll need it in the next step
7. Click **"Next"** → **"Next"** → **"Continue to console"**

✅ **Checkpoint**: You have `google-services.json` file downloaded

---

## 📱 Part 2: Flutter Project Setup (15 minutes)

### Step 4: Place google-services.json

1. **Copy** the downloaded `google-services.json` file
2. **Paste** it to: `covoiturage_app/android/app/google-services.json`

**Path should be**:
```
covoiturage_app/
  android/
    app/
      google-services.json  ← Put it here!
      build.gradle
      src/
```

✅ **Checkpoint**: File is in the correct location

---

### Step 5: Update Android Build Files

#### File 1: `android/build.gradle`

**Location**: `covoiturage_app/android/build.gradle`

**Find** this section (around line 6-12):
```gradle
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

**Add** this line in dependencies:
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:7.3.0'
    classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    classpath 'com.google.gms:google-services:4.4.0'  // ← ADD THIS LINE
}
```

---

#### File 2: `android/app/build.gradle`

**Location**: `covoiturage_app/android/app/build.gradle`

**At the very bottom** of the file, **add**:
```gradle
apply plugin: 'com.google.gms.google-services'  // ← ADD THIS LINE
```

---

### Step 6: Add Flutter Dependencies

**File**: `covoiturage_app/pubspec.yaml`

**Find** the `dependencies:` section and **add**:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies...
  cupertino_icons: ^1.0.8
  http: ^1.1.0
  provider: ^6.1.1
  # ... other existing dependencies ...
  
  # Add these NEW dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  pin_code_fields: ^8.0.1
```

**Run** in terminal:
```bash
cd covoiturage_app
flutter pub get
```

✅ **Checkpoint**: Dependencies installed without errors

---

### Step 7: Initialize Firebase in Flutter

**File**: `covoiturage_app/lib/main.dart`

**Add** import at the top:
```dart
import 'package:firebase_core/firebase_core.dart';
```

**Update** the `main()` function:
```dart
// OLD:
void main() {
  runApp(const CovoiturageApp());
}

// NEW:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CovoiturageApp());
}
```

✅ **Checkpoint**: Firebase initialization added

---

## 📁 Part 3: Create Phone Verification Files (20 minutes)

### Step 8: Create Phone Verification Service

**Create new file**: `covoiturage_app/lib/services/phone_verification_service.dart`

**Copy this entire code**:
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
```

✅ **Checkpoint**: Service file created

---

### Step 9: Create Phone Verification Screen

**Create new file**: `covoiturage_app/lib/screens/auth/phone_verification_screen.dart`

**Copy this entire code**:
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
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  void _sendOTP() {
    setState(() => _isLoading = true);

    String formattedPhone = widget.phoneNumber.replaceAll(' ', '');
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
            Icon(
              Icons.phone_android,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Verification Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
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

✅ **Checkpoint**: Verification screen created

---

### Step 10: Update Signup Screen

**File**: `covoiturage_app/lib/screens/auth/signup_screen.dart`

**Add import** at the top (around line 4):
```dart
import 'phone_verification_screen.dart';
```

**Find** the `_signup()` method (around line 52) and **replace it** with:
```dart
Future<void> _signup() async {
  if (!_formKey.currentState!.validate()) return;

  // Navigate to phone verification
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PhoneVerificationScreen(
        phoneNumber: _phoneController.text.trim(),
        onVerificationSuccess: () async {
          Navigator.pop(context);
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
          content: Text('Account created! Phone verified ✓'),
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

✅ **Checkpoint**: Signup flow updated

---

## ✅ Final Checklist

- [ ] Firebase project created
- [ ] Phone auth enabled in Firebase
- [ ] Android app added to Firebase
- [ ] `google-services.json` in correct location
- [ ] `android/build.gradle` updated
- [ ] `android/app/build.gradle` updated
- [ ] Dependencies added to `pubspec.yaml`
- [ ] `flutter pub get` run successfully
- [ ] Firebase initialized in `main.dart`
- [ ] `phone_verification_service.dart` created
- [ ] `phone_verification_screen.dart` created
- [ ] `signup_screen.dart` updated

---

## 🧪 Testing

### Test 1: Run the App
```bash
cd covoiturage_app
flutter run
```

### Test 2: Try Signup
1. Open app
2. Go to signup
3. Fill in details
4. Enter phone number: `+216 12 345 678` (Tunisia format)
5. Click signup
6. **Should see**: Verification screen
7. **Should receive**: SMS with 6-digit code
8. Enter code
9. **Should see**: Account created message

---

## 🐛 Common Issues & Fixes

### Issue 1: "google-services.json not found"
**Fix**: Ensure file is at `android/app/google-services.json`

### Issue 2: "Firebase not initialized"
**Fix**: Check `main.dart` has `Firebase.initializeApp()`

### Issue 3: "SMS not received"
**Fix**: 
- Check phone number format (+216...)
- Verify Firebase Phone auth is enabled
- Check Firebase Console for quota limits

### Issue 4: "Invalid code"
**Fix**: 
- Wait for SMS (can take 30 seconds)
- Check you entered all 6 digits
- Try resend code

---

## 💰 Cost Info

- **Firebase Phone Auth**: FREE for 10,000 verifications/month
- **Your expected usage**: ~100-500 users = **FREE**
- **After free tier**: $0.01 per verification

---

## 🎉 Success!

When it works, you'll see:
1. User enters phone number
2. Gets SMS code instantly
3. Enters code
4. Phone verified ✓
5. Account created ✓

**Admin role is already removed from signup!** ✅

---

## 📞 Need Help?

If you get stuck:
1. Check the specific error message
2. Verify all files are in correct locations
3. Ensure Firebase project is properly configured
4. Check Firebase Console logs

**Ready to implement? Follow these steps one by one!** 🚀


















