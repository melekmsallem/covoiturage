import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class PaymentInfoScreen extends StatefulWidget {
  final String role;
  final String phoneNumber;
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? licenseNumber;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehiclePlate;
  final int? maxPassengers;

  const PaymentInfoScreen({
    super.key,
    required this.role,
    required this.phoneNumber,
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.licenseNumber,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlate,
    this.maxPassengers,
  });

  @override
  State<PaymentInfoScreen> createState() => _PaymentInfoScreenState();
}

class _PaymentInfoScreenState extends State<PaymentInfoScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String? _selectedPaymentMethod;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'CASH',
      'name': 'Cash',
      'description': 'Pay with cash',
      'icon': Icons.money,
    },
    {
      'id': 'DEBIT_CARD',
      'name': 'Debit Card',
      'description': 'Pay with debit card',
      'icon': Icons.credit_card,
    },
    {
      'id': 'CREDIT_CARD',
      'name': 'Credit Card',
      'description': 'Pay with credit card',
      'icon': Icons.credit_card,
    },
    {
      'id': 'MOBILE_PAYMENT',
      'name': 'Mobile Payment',
      'description': 'Pay with mobile wallet',
      'icon': Icons.phone_android,
    },
  ];

  Future<void> _createAccount() async {
    setState(() => _isLoading = true);

    try {
      final response = await _authService.signUp(
        username: widget.username,
        email: widget.email,
        password: widget.password,
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: widget.phoneNumber,
        role: widget.role,
        licenseNumber: widget.licenseNumber,
        vehicleModel: widget.vehicleModel,
        vehicleColor: widget.vehicleColor,
        vehiclePlate: widget.vehiclePlate,
        maxPassengers: widget.maxPassengers,
        preferredPaymentMethod: _selectedPaymentMethod,
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

        // Navigate to home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.payment,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your preferred payment method',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Payment methods
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Select Payment Method',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      ..._paymentMethods.map((method) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = method['id'];
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPaymentMethod == method['id']
                                    ? colorScheme.primary
                                    : Colors.grey[300]!,
                                width: _selectedPaymentMethod == method['id'] ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedPaymentMethod == method['id']
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  method['icon'],
                                  color: _selectedPaymentMethod == method['id']
                                      ? colorScheme.primary
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method['name'],
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _selectedPaymentMethod == method['id']
                                              ? colorScheme.primary
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        method['description'],
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedPaymentMethod == method['id'])
                                  Icon(
                                    Icons.check_circle,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: 32),

                      // Create account button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading || _selectedPaymentMethod == null ? null : _createAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: colorScheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

