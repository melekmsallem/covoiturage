import 'package:flutter/material.dart';
// import removed
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/trips/trip_search_screen.dart';
import 'screens/trips/trip_creation_wizard.dart';
import 'screens/rating/rating_screen.dart';
import 'screens/rating/my_ratings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/phone_input_screen.dart';
import 'screens/coins/coin_purchase_screen.dart';
import 'screens/auth/driver_verification_screen.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Reset API base URL cache to force re-detection on app start
  ApiService.resetBaseUrl();
  
  try {
    // Check if Firebase is already initialized to avoid duplicate app error
    if (Firebase.apps.isEmpty) {
      // Initialize Firebase on all platforms (web requires proper config)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } else {
      print('Firebase already initialized, skipping...');
    }
  } catch (e) {
    // Check if error is due to duplicate app (ignore it)
    if (e.toString().contains('duplicate-app')) {
      print('Firebase app already exists (expected during hot reload)');
    } else {
      print('Firebase initialization error: $e');
      // Continue without Firebase for now
    }
  }
  
  runApp(const CovoiturageApp());
}

class CovoiturageApp extends StatelessWidget {
  const CovoiturageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'RideShare',
        debugShowCheckedModeBanner: false,
        // Globally control scaling on small screens to avoid overflowing UIs
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          // Clamp text scale to a reasonable range for consistent layouts
          final clamped = mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.00);
          return MediaQuery(
            data: mq.copyWith(textScaler: clamped),
            child: child ?? const SizedBox.shrink(),
          );
        },
        theme: ThemeData(
          useMaterial3: true,
          visualDensity: VisualDensity.compact,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
          // Keep default text sizes; scaling is controlled via MediaQuery builder above
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            toolbarHeight: 52,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            elevation: 8,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/trip-search': (context) => const TripSearchScreen(),
          '/create-trip': (context) => const TripCreationWizard(),
          '/welcome': (context) => const WelcomeScreen(),
          '/role-select': (context) => const RoleSelectionScreen(),
          '/phone-input': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
            final role = (args?['role'] as String?) ?? 'PASSAGER';
            return PhoneInputScreen(role: role);
          },
          '/rating': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            // Safely cast arguments to Map<String, dynamic>
            final argsMap = args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{};
            
            // Safely cast trip and userToRate
            final trip = argsMap['trip'] is Map 
                ? Map<String, dynamic>.from(argsMap['trip']) 
                : <String, dynamic>{};
            
            final userToRate = argsMap['userToRate'] is Map 
                ? Map<String, dynamic>.from(argsMap['userToRate']) 
                : <String, dynamic>{};
            
            return RatingScreen(
              trip: trip,
              userToRate: userToRate,
              ratingType: argsMap['ratingType'] as String? ?? '',
            );
          },
          '/my-ratings': (context) => const MyRatingsScreen(),
          '/coin-purchase': (context) => const CoinPurchaseScreen(),
          '/driver-verification': (context) => DriverVerificationScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}
