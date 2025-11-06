import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/company_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Company Logo with white text for splash screen
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: CompanyLogo(
                size: 220,
                showTagline: true,
                tagline: 'Your Journey, Connected',
                lightVariant: true,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Share rides. Save money. Meet people.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: colorScheme.onPrimary,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}











































