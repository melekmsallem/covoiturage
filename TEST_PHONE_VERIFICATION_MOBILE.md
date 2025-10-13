# 📱 Testing Phone Verification on Mobile - Complete Guide

**Goal**: Test SMS verification on a real Android phone or emulator

---

## 🎯 Two Testing Options

### Option 1: Android Emulator (Easier - No Real Phone Needed)
### Option 2: Real Android Phone (Full Real-World Test)

---

## 🤖 OPTION 1: Test with Android Emulator (Recommended)

### Step 1: Start Android Emulator

**In Android Studio**:
1. Open Android Studio
2. Click **"Device Manager"** (phone icon in toolbar)
3. Click **"Create Device"** or select existing device
4. Start the emulator

**Or via Command Line**:
```bash
# List available emulators
emulator -list-avds

# Start an emulator
emulator -avd Pixel_5_API_33 &
```

### Step 2: Check Emulator is Detected
```bash
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app
flutter devices
```

**Expected output**:
```
Android SDK built for x86 (mobile) • emulator-5554 • android-x86 • Android 13 (API 33) (emulator)
Chrome (web)                        • chrome        • web-javascript • Google Chrome 118.0
```

### Step 3: Run Flutter App on Emulator
```bash
flutter run -d emulator-5554
```

**Or just**:
```bash
flutter run
# Select option for Android emulator
```

### Step 4: Set Up Test Phone Number in Firebase

Since emulator can't receive real SMS, use Firebase test phone numbers:

1. Go to **Firebase Console** (https://console.firebase.google.com)
2. Select your **Covoiturage** project
3. Click **Authentication** → **Sign-in method**
4. Click on **"Phone"**
5. Scroll to **"Phone numbers for testing"**
6. Click **"Add phone number"**
7. Add:
   - **Phone number**: `+21612345678`
   - **SMS code**: `123456`
8. Click **"Add"**

### Step 5: Test in Emulator
1. App opens in emulator
2. Click **"Sign Up"**
3. Fill all fields
4. **Phone number**: Enter `+21612345678` (the test number)
5. **Role**: Select Passenger or Driver (no Admin!)
6. Click **"Sign Up"**
7. **Verification screen appears** 🎉
8. Enter code: `123456` (the test code you configured)
9. ✅ Phone verified!
10. ✅ Account created!

**Advantage**: Infinite testing without SMS costs! 🎊

---

## 📱 OPTION 2: Test with Real Android Phone

### Step 1: Enable USB Debugging on Phone

**On your Android phone**:
1. Go to **Settings**
2. Scroll to **"About phone"**
3. Tap **"Build number"** 7 times (unlocks Developer options)
4. Go back to **Settings**
5. Find **"Developer options"**
6. Enable **"USB debugging"**

### Step 2: Connect Phone to PC
1. Connect phone via USB cable
2. Allow USB debugging when prompted on phone
3. Select **"File Transfer"** or **"PTP"** mode

### Step 3: Verify Phone is Detected
```bash
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app
flutter devices
```

**Expected**:
```
SM G975F (mobile) • RZ8M71ABCDE • android-arm64 • Android 13 (API 33)
```

### Step 4: Update API URL for Real Phone

**File**: `covoiturage_app/lib/services/api_service.dart`

**Find line 10** and update with your PC's IP address:

```dart
// Current (works for emulator):
static final String baseUrl = kIsWeb
    ? 'http://localhost:8081/api'
    : 'http://192.168.1.14:8081/api';

// Update to your PC's actual IP:
static final String baseUrl = kIsWeb
    ? 'http://localhost:8081/api'
    : 'http://YOUR_PC_IP:8081/api';  // Example: 192.168.1.100
```

**To find your PC's IP**:
```powershell
ipconfig
# Look for "IPv4 Address" under your WiFi/Ethernet adapter
```

### Step 5: Run App on Phone
```bash
flutter run
# Select your phone from the list
```

### Step 6: Test with Real SMS
1. App opens on your phone
2. Click **"Sign Up"**
3. Fill all fields
4. **Phone number**: Enter your REAL Tunisian number: `+216 12 34 56 78`
5. **Role**: Select Passenger or Driver
6. Click **"Sign Up"**
7. **Verification screen appears**
8. **SMS arrives on your phone** 📱
9. Enter the 6-digit code from SMS
10. ✅ Phone verified!
11. ✅ Account created!

---

## 🔥 OPTION 3: Test Without Real Phone (Web for Now)

For quick testing right now (web):

1. App is running in Chrome
2. Click "Sign Up"
3. Verify admin role is NOT in the dropdown
4. Create account (no SMS verification on web)
5. Later test on mobile for SMS

---

## 💰 Cost Comparison

| Method | Cost | SMS Received | Best For |
|--------|------|--------------|----------|
| Emulator + Test Numbers | **FREE** | No (fake code) | Development |
| Real Phone + Test Numbers | **FREE** | No (fake code) | Development |
| Real Phone + Real SMS | **FREE** | Yes (real SMS) | Production testing |

**Firebase Phone Auth FREE Tier**: 10,000 verifications/month

---

## 🧪 Recommended Testing Flow

### Phase 1: Test on Web First (Now)
```bash
# Already running!
# Just test signup without SMS
```

### Phase 2: Test with Emulator + Firebase Test Numbers
```bash
# Setup:
1. Start Android Emulator
2. Add test phone number in Firebase Console
3. Run: flutter run -d emulator-5554
4. Test signup with test number: +21612345678
5. Enter test code: 123456
```

### Phase 3: Test on Real Phone (Final Testing)
```bash
# Setup:
1. Connect real phone
2. Update API URL with PC's IP
3. Run: flutter run
4. Test signup with real phone number
5. Receive and enter real SMS code
```

---

## 📝 Quick Start Commands

### For Emulator Testing:
```powershell
# 1. Check Flutter can see emulator
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app
flutter devices

# 2. Run on emulator
flutter run -d emulator-5554

# 3. In app, use test number: +21612345678
# 4. Enter test code: 123456
```

### For Real Phone Testing:
```powershell
# 1. Connect phone via USB
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app

# 2. Check phone is detected
flutter devices

# 3. Get your PC's IP
ipconfig

# 4. Update api_service.dart with your IP (line 10)

# 5. Run on phone
flutter run

# 6. Use your real phone number
# 7. Enter real SMS code
```

---

## 🔧 Setup Firebase Test Phone Numbers (For Emulator)

This lets you test SMS without real phones or costs!

### Steps:
1. **Firebase Console**: https://console.firebase.google.com
2. Select **"Covoiturage"** project
3. **Authentication** → **Sign-in method** tab
4. Click **"Phone"** provider
5. Scroll to **"Phone numbers for testing"**
6. Click **"+ Add phone number"**
7. Enter:
   - Phone: `+21612345678`
   - Code: `123456`
8. Click **"Add"**
9. **(Optional)** Add more test numbers:
   - `+21698765432` → code: `654321`
   - `+21611111111` → code: `111111`

### Test:
- Use `+21612345678` in signup
- Enter code `123456`
- Works perfectly without real SMS! ✨

---

## 🐛 Troubleshooting

### Issue: "No devices found"
**Fix**:
- Start Android emulator first
- Or connect real phone via USB
- Run `flutter devices` to verify

### Issue: "Can't connect to backend"
**Fix for real phone**:
- Get your PC's IP: `ipconfig`
- Update `api_service.dart` line 10
- Make sure phone and PC on same WiFi network

### Issue: "SMS not received" (real phone)
**Fix**:
- Check phone number format (+216...)
- Verify Firebase Phone auth enabled
- Check Firebase Console for errors
- Try with test phone numbers first

### Issue: "Invalid code"
**Fix**:
- For test numbers: Use exact code from Firebase Console
- For real SMS: Wait 30-60 seconds for SMS to arrive
- Check SMS inbox for code
- Code is case-sensitive (usually all numbers)

---

## ⚡ Quick Test (Right Now)

### Easiest Way - Use Web (Already Running)
The app is running in Chrome now. Just test:
1. Click "Sign Up"
2. Verify only Passenger/Driver roles (no Admin!)
3. Create account
4. Works without SMS on web

### Later - Test SMS on Emulator
1. Start Android emulator
2. Add test phone in Firebase
3. Run `flutter run -d emulator-5554`
4. Test with test phone number

---

## 📊 Comparison

| Platform | SMS Verification | Setup Time | Best For |
|----------|-----------------|------------|----------|
| **Web (Chrome)** | ❌ Skipped | 0 min | Quick testing now |
| **Emulator + Test Numbers** | ✅ Simulated | 5 min | Development |
| **Real Phone + Test Numbers** | ✅ Simulated | 10 min | Development |
| **Real Phone + Real SMS** | ✅ Real | 10 min | Production testing |

---

## ✅ My Recommendation

**For Now (Testing)**:
1. ✅ Test on web (already running) - Verify admin removal
2. ✅ Set up Firebase test phone numbers
3. ✅ Test on Android emulator with test numbers
4. Later: Test on real phone with real SMS

**For Production**:
- Real phone with real SMS verification
- Gives best security and user experience

---

## 🚀 Next Step Commands

### Test on Emulator (After setting up test numbers):
```powershell
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app

# Start emulator (or do it in Android Studio)
# Then run:
flutter run -d emulator-5554

# In app:
# Phone: +21612345678
# Code: 123456
```

### Test on Real Phone:
```powershell
# 1. Connect phone via USB
# 2. Get your PC IP:
ipconfig

# 3. Update api_service.dart with your IP

# 4. Run:
flutter run

# In app:
# Phone: Your real number (+216...)
# Code: Real SMS code you receive
```

---

**The web app should be opening in Chrome right now!** 

**Test the signup and verify admin role is removed!** Then you can test SMS on mobile later. 🎉



