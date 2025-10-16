# 📱 Flutter App Testing Guide

**Date**: October 10, 2025  
**Backend**: Running on http://localhost:8081  
**Flutter App**: covoiturage_app

---

## ✅ Prerequisites Check

### 1. Backend Status
- ✅ Spring Boot running on port **8081**
- ✅ Admin dashboard working
- ✅ API endpoints secured and functional
- ✅ Test data populated

### 2. Flutter Configuration
- ✅ **App Name**: Covoiturage App
- ✅ **SDK**: Dart ^3.9.0
- ✅ **API URL**: http://localhost:8081/api (for web/emulator)
- ✅ **API URL**: http://192.168.1.14:8081/api (for physical devices)

### 3. Dependencies Installed
- ✅ Provider (State management)
- ✅ HTTP client
- ✅ SharedPreferences (Local storage)
- ✅ Google Maps
- ✅ Geolocator
- ✅ WebSocket support
- ✅ URL launcher (for Stripe payments)

---

## 🚀 How to Run the Flutter App

### Option 1: Run on Chrome (Web - Easiest)

```powershell
# Open new PowerShell window
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app

# Get dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

**Advantages**:
- No emulator needed
- Fast startup
- Easy debugging
- Uses localhost:8081 backend

### Option 2: Run on Android Emulator

```powershell
# Open new PowerShell window
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app

# List available devices
flutter devices

# Run on Android emulator
flutter run -d emulator-5554
```

**Note**: Make sure Android Emulator is running first

### Option 3: Run on Physical Device

```powershell
# Connect device via USB
# Enable USB debugging on device

# Check if device is detected
flutter devices

# Run on device
flutter run
```

**Important**: Update API URL in `lib/services/api_service.dart` line 10 to your PC's IP address:
```dart
: 'http://YOUR_PC_IP:8081/api';
```

---

## 📱 Flutter App Features

### Authentication Screens
1. **Login Screen** (`/login`)
   - Login with username/email
   - Password authentication
   - JWT token storage

2. **Signup Screen** (`/signup`)
   - User registration
   - Role selection (Driver/Passenger)
   - Form validation

### Main Features

#### For All Users:
- **Home Screen** - Dashboard with user stats
- **Profile Management** - View/edit profile
- **Notifications** - Real-time notifications
- **Ratings** - View and give ratings

#### For Passengers:
- **Trip Search** (`/trip-search`)
  - Search trips by city, date, price
  - Filter available trips
  - View trip details
- **Book Trip** - Reserve seats
- **My Bookings** - View booking history
- **Payments** - Make payments via Stripe

#### For Drivers:
- **Create Trip** (`/create-trip`)
  - Set departure/arrival cities
  - Set date, time, price
  - Set available seats
  - Add trip options
- **My Trips** - View and manage trips
- **Trip Bookings** - See who booked
- **Start/Complete Trip** - Manage trip status

---

## 🧪 Test Scenarios

### Test 1: User Registration & Login

**Steps**:
1. Click "Sign Up"
2. Fill registration form:
   - Email: `test@example.com`
   - Password: `password123`
   - Role: Select "Driver" or "Passenger"
3. Click "Register"
4. Login with credentials
5. Verify JWT token stored
6. Check dashboard loads

**Expected**: User registered and logged in successfully

---

### Test 2: Driver - Create Trip

**Prerequisites**: Login as driver

**Steps**:
1. Navigate to "Create Trip"
2. Select departure city (e.g., Tunis)
3. Select arrival city (e.g., Sfax)
4. Set departure date/time
5. Set price per seat: 15 TND
6. Set available seats: 3
7. Add trip options (optional)
8. Click "Create Trip"

**Expected**: Trip created and visible in "My Trips"

---

### Test 3: Passenger - Search & Book Trip

**Prerequisites**: Login as passenger, ensure trips exist

**Steps**:
1. Navigate to "Search Trips"
2. Enter departure city: Tunis
3. Enter arrival city: Sfax
4. Select date
5. Click "Search"
6. View available trips
7. Select a trip
8. Choose number of seats: 1
9. Click "Book"

**Expected**: Booking created, driver notified

---

### Test 4: Payment Flow

**Prerequisites**: Have a pending booking

**Steps**:
1. Go to "My Bookings"
2. Select pending booking
3. Click "Pay Now"
4. Redirected to Stripe Checkout
5. Complete payment (use test card: 4242 4242 4242 4242)
6. Return to app
7. Verify payment status updated

**Expected**: Payment successful, booking confirmed

---

### Test 5: Real-time Notifications

**Prerequisites**: Two users logged in (different devices/browsers)

**Steps**:
1. **User A (Driver)**: Create a trip
2. **User B (Passenger)**: Book the trip
3. **User A**: Should receive booking notification
4. **User A**: Confirm booking
5. **User B**: Should receive confirmation notification

**Expected**: Both users receive real-time notifications via WebSocket

---

### Test 6: Rating System

**Prerequisites**: Completed trip

**Steps**:
1. Navigate to completed trips
2. Click "Rate" on a trip
3. Select rating (1-5 stars)
4. Add comment
5. Submit rating
6. View in "My Ratings"

**Expected**: Rating saved and visible to rated user

---

## 🔌 API Connection Testing

### Test Backend Connection

**From Flutter App**:
1. Open app
2. Try to login
3. Check console logs for API requests
4. Verify requests go to http://localhost:8081/api

**Debug Console Output**:
```
GET request to: http://localhost:8081/api/cities
Headers: {Content-Type: application/json}
Response: 200 OK
```

### Common Issues:

#### Issue 1: "Failed to connect to backend"
**Solution**: 
- Verify Spring Boot is running on port 8081
- Check `api_service.dart` has correct URL
- For web: Use `http://localhost:8081`
- For emulator: Use `http://10.0.2.2:8081`
- For device: Use your PC's IP address

#### Issue 2: "401 Unauthorized"
**Solution**:
- Login again to get fresh JWT token
- Check token is being sent in Authorization header
- Verify token hasn't expired (24 hours)

#### Issue 3: CORS errors (web only)
**Solution**:
- Spring Boot already has `@CrossOrigin(origins = "*")`
- If issues persist, check browser console
- Try disabling browser security (dev only)

---

## 📊 Available Test Users

### Admin User
```
Username: admin
Password: admin123
Role: ADMIN
```

### Test Driver
```
Email: driver@example.com
Password: password123
Role: DRIVER
```

### Test Passenger
```
Email: passenger@example.com
Password: password123
Role: PASSENGER
```

**Note**: You may need to create these users via signup first

---

## 🔧 Development Commands

### Install Dependencies
```bash
cd covoiturage_app
flutter pub get
```

### Run on Specific Platform
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS (Mac only)
flutter run -d ios

# Windows
flutter run -d windows
```

### Hot Reload
- Press `r` in terminal during run
- Or save files (auto hot reload)

### Full Restart
- Press `R` in terminal
- Or stop and rerun

### Build Release
```bash
# Android APK
flutter build apk

# Web
flutter build web

# Windows
flutter build windows
```

---

## 📱 Screens Overview

### 1. Login Screen
- Email/username input
- Password input
- "Remember me" checkbox
- Sign up link

### 2. Signup Screen
- Personal info (name, email, phone)
- Password (with confirmation)
- Role selection (Driver/Passenger)
- Driver-specific fields (vehicle info, license)

### 3. Home Screen
- User dashboard
- Quick stats
- Recent trips/bookings
- Navigation menu

### 4. Trip Search Screen (Passengers)
- City autocomplete (departure/arrival)
- Date picker
- Price range filter
- Search results list
- Trip details modal

### 5. Create Trip Screen (Drivers)
- City selection
- Date/time picker
- Price per seat input
- Available seats input
- Trip options (smoking, pets, AC, etc.)
- Create button

### 6. My Trips Screen (Drivers)
- List of created trips
- Trip status badges
- View bookings button
- Start/Complete/Cancel actions

### 7. My Bookings Screen (Passengers)
- List of bookings
- Booking status
- Trip details
- Payment button
- Cancel booking

### 8. Rating Screen
- Star rating (1-5)
- Comment textarea
- Submit button

---

## 🎯 Key API Endpoints Used by Flutter

### Authentication
- `POST /api/auth/signup` - User registration
- `POST /api/auth/signin` - User login

### Trips
- `POST /api/trips` - Create trip (Driver)
- `POST /api/trips/search` - Search trips (Passenger)
- `GET /api/trips/my-trips` - Get driver's trips
- `GET /api/trips/{id}` - Get trip details
- `POST /api/trips/{id}/start` - Start trip
- `POST /api/trips/{id}/complete` - Complete trip

### Bookings
- `POST /api/bookings` - Create booking
- `GET /api/bookings/my-bookings` - Get user's bookings
- `POST /api/bookings/{id}/confirm` - Confirm booking (Driver)
- `POST /api/bookings/{id}/cancel` - Cancel booking

### Payments
- `POST /api/payments` - Create payment
- `GET /api/payments/create-checkout-session/{reservationId}` - Stripe session
- `POST /api/payments/{id}/process` - Process payment

### Notifications
- `GET /api/notifications` - Get notifications
- `GET /api/notifications/unread` - Get unread count
- `PUT /api/notifications/{id}/read` - Mark as read

### Cities
- `GET /api/cities` - Get all cities (for autocomplete)

### Ratings
- `POST /api/ratings/driver` - Rate driver
- `POST /api/ratings/passenger` - Rate passenger
- `GET /api/ratings/user/{id}/statistics` - Get user ratings

### WebSocket
- `ws://localhost:8081/ws` - WebSocket connection
- `/topic/notifications` - Notifications channel
- `/user/queue/notifications` - User-specific notifications

---

## 🐛 Debugging Tips

### Enable Debug Logging
Add to `main.dart`:
```dart
void main() {
  debugPrint('Starting Covoiturage App...');
  runApp(const CovoiturageApp());
}
```

### Check API Responses
In `api_service.dart`, responses are already logged:
```dart
debugPrint('GET request to: $url');
debugPrint('Response: ${response.statusCode}');
```

### Inspect Network Traffic
1. Open Flutter DevTools
2. Navigate to Network tab
3. See all HTTP requests/responses

### Common Debug Commands
```bash
# See logs
flutter logs

# Clear build cache
flutter clean
flutter pub get

# Check for issues
flutter doctor -v

# Analyze code
flutter analyze
```

---

## ✅ Testing Checklist

### Before Testing
- [ ] Backend running on port 8081
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Device/emulator ready or Chrome available
- [ ] Test users created or ready to register

### During Testing
- [ ] User can register successfully
- [ ] User can login and get JWT token
- [ ] Dashboard loads with user data
- [ ] Driver can create trips
- [ ] Passenger can search trips
- [ ] Passenger can book trips
- [ ] Payment flow works (Stripe)
- [ ] Notifications appear in real-time
- [ ] Rating system works
- [ ] Trip lifecycle (start/complete) works

### After Testing
- [ ] Check for console errors
- [ ] Verify data in database (via admin dashboard)
- [ ] Test on multiple platforms (web, mobile)
- [ ] Document any bugs found

---

## 🚀 Quick Start (Recommended)

### Easiest Way to Test:

1. **Keep Spring Boot running** (already running on port 8081)

2. **Open new PowerShell/Terminal**:
```powershell
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app
flutter pub get
flutter run -d chrome
```

3. **Wait for app to open in Chrome**

4. **Test the flow**:
   - Register a new user (passenger)
   - Search for trips (Tunis → Sfax)
   - Book a trip
   - Make payment
   - Rate the driver

---

## 📝 Expected Results

### Successful App Launch:
- ✅ Flutter app opens in Chrome/emulator
- ✅ Login screen displays
- ✅ No console errors
- ✅ API connects to backend

### Successful User Flow:
- ✅ User registers and logs in
- ✅ Dashboard shows user stats
- ✅ Trip search returns results from backend
- ✅ Booking creates reservation in database
- ✅ Payment processes via Stripe
- ✅ Notifications received in real-time
- ✅ Ratings saved successfully

---

## 🎉 Success Criteria

Your Flutter app is working correctly if:

1. ✅ App launches without errors
2. ✅ Authentication works (login/signup)
3. ✅ API calls succeed (check network tab)
4. ✅ Data displays correctly from backend
5. ✅ User actions reflect in database (verify via admin dashboard)
6. ✅ Real-time features work (WebSocket notifications)
7. ✅ Payment integration functional
8. ✅ No critical bugs or crashes

---

**Ready to test? Run this command in a new terminal:**
```powershell
cd C:\Users\msall\IdeaProjects\covoiturage_final\covoiturage_app && flutter run -d chrome
```

**Backend URL**: http://localhost:8081  
**Admin Dashboard**: http://localhost:8081/admin-dashboard.html  
**Admin Login**: admin / admin123


















