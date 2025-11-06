import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/file_upload_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final _apiService = ApiService.instance;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  String? _emailError;
  Map<String, dynamic>? _fetchedUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user != null) {
      _firstNameController.text = user['firstName'] ?? '';
      _lastNameController.text = user['lastName'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['phoneNumber'] ?? '';
      final userId = user['id'];
      if (userId != null) {
        _fetchFullUser(userId);
      }
    }
  }

  Future<void> _fetchFullUser(int userId) async {
    try {
      final result = await _apiService.get('/users/$userId');
      if (mounted) {
        setState(() {
          _fetchedUser = result is Map<String, dynamic> ? result : null;
        });
        
        // Update all fields from fetched user data (this ensures we have the latest data)
        if (_fetchedUser != null) {
          // Update firstName and lastName from server (may have been updated during verification)
          if (_fetchedUser!['firstName'] != null && _fetchedUser!['firstName'].toString().isNotEmpty) {
            _firstNameController.text = _fetchedUser!['firstName'].toString();
          }
          if (_fetchedUser!['lastName'] != null && _fetchedUser!['lastName'].toString().isNotEmpty) {
            _lastNameController.text = _fetchedUser!['lastName'].toString();
          }
          if (_fetchedUser!['email'] != null && _fetchedUser!['email'].toString().isNotEmpty) {
            _emailController.text = _fetchedUser!['email'].toString();
          }
          
          // If phone number wasn't in auth state, populate it from fetched user
          final fetchedPhone = _fetchedUser!['phoneNumber']?.toString();
          if ((_phoneController.text.isEmpty || _phoneController.text.trim().isEmpty) &&
              fetchedPhone != null && fetchedPhone.isNotEmpty) {
            _phoneController.text = fetchedPhone;
          }
          
          // Also update AuthProvider with latest data
          final authProvider = context.read<AuthProvider>();
          authProvider.updateUserData({
            ...?authProvider.user,
            ..._fetchedUser!,
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch full user data: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailAvailability() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isCheckingEmail = true;
      _emailError = null;
    });

    try {
      // Use public API call without authentication
      final response = await _apiService.getPublic('/users/check-email/$email');
      final emailExists = response as bool;
      
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          if (emailExists) {
            _emailError = 'Email is already in use';
          } else {
            _emailError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _emailError = 'Error checking email';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_emailError != null) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?['id'];
      
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      };

      await _apiService.put('/users/$userId', updateData);
      
      if (mounted) {
        // Update the user data in AuthProvider
        final updatedUser = {
          ...authProvider.user!,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
        };
        
        // Save updated user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('firstName', updatedUser['firstName']);
        await prefs.setString('lastName', updatedUser['lastName']);
        await prefs.setString('email', updatedUser['email']);
        await prefs.setString('phoneNumber', updatedUser['phoneNumber']);
        
        // Update AuthProvider
        authProvider.updateUserData(updatedUser);
        
        // Profile updated successfully
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
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
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Driver License Info (read-only, shown if available for drivers)
                          if (_fetchedUser != null &&
                              ((_fetchedUser!['role']?.toString().toUpperCase() == 'CONDUCTEUR') ||
                               (_fetchedUser!['user_type']?.toString().toUpperCase() == 'CONDUCTEUR')) &&
                              (
                                _fetchedUser!['licenseNumber'] != null ||
                                _fetchedUser!['licenseVerified'] != null ||
                                _fetchedUser!['licenseVerificationDate'] != null ||
                                _fetchedUser!['licenseImagePath'] != null
                              ))
                            Card(
                              margin: const EdgeInsets.only(top: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Driver License',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_fetchedUser!['licenseNumber'] != null)
                                      _ReadOnlyRow(label: 'License Number', value: _fetchedUser!['licenseNumber'].toString()),
                                    if (_fetchedUser!['licenseVerified'] != null)
                                      _ReadOnlyRow(label: 'Verified', value: (_fetchedUser!['licenseVerified'] as bool) ? 'Yes' : 'No'),
                                    if (_fetchedUser!['licenseVerificationDate'] != null)
                                      _ReadOnlyRow(label: 'Verified At', value: _fetchedUser!['licenseVerificationDate'].toString()),
                                    if (_fetchedUser!['licenseImagePath'] != null && _fetchedUser!['licenseImagePath'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          FileUploadService.getLicenseImageUrl(_fetchedUser!['licenseImagePath'].toString().split('/').last),
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 140,
                                            alignment: Alignment.center,
                                            color: Colors.grey.shade200,
                                            child: const Text('License image unavailable'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                          // First Name
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Last Name
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              suffixIcon: _isCheckingEmail
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.primary),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              if (_emailError != null) {
                                return _emailError;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                            onFieldSubmitted: (_) => _checkEmailAvailability(),
                          ),
                          const SizedBox(height: 16),

                          // Phone Number
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Save Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Updating...'),
                                    ],
                                  )
                                : const Text(
                                    'Update Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
