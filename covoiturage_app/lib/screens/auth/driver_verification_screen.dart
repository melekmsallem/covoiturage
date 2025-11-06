import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/license_ocr_service.dart';
import '../../services/file_upload_service.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  bool _isSubmitting = false;
  bool _isScanningLicense = false;
  String? _licenseImagePath;
  DriverLicenseInfo? _extractedLicenseInfo;
  final LicenseOCRService _licenseOcrService = LicenseOCRService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isVerified = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final apiService = ApiService.instance;
      final verificationStatus = await apiService.get('/users/verification-status');
      
      if (mounted) {
        final isVerified = verificationStatus['isVerified'] == true;
        setState(() {
          _isVerified = isVerified;
          _isLoadingStatus = false;
        });
        
        // If verified, update AuthProvider with latest data
        if (isVerified) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.updateUserData({
            ...?authProvider.user,
            'isVerified': true,
            'firstName': verificationStatus['firstName'],
            'lastName': verificationStatus['lastName'],
            'email': verificationStatus['email'],
            'licenseNumber': verificationStatus['licenseNumber'],
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to check verification status: $e');
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _emailController.text = user['email'] ?? '';
      _firstNameController.text = user['firstName'] ?? '';
      _lastNameController.text = user['lastName'] ?? '';
      // License number might already exist if user started verification
      _licenseNumberController.text = user['licenseNumber'] ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _licenseNumberController.dispose();
    _licenseOcrService.dispose();
    super.dispose();
  }

  Future<void> _scanLicenseFromPhoto() async {
    setState(() {
      _isScanningLicense = true;
    });

    try {
      // Show dialog to choose camera or gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        setState(() {
          _isScanningLicense = false;
        });
        return;
      }

      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        setState(() {
          _isScanningLicense = false;
        });
        return;
      }

      _licenseImagePath = image.path;

      // Extract text using OCR
      final extractedText = await _licenseOcrService.extractTextFromImage(image.path);
      
      // Parse license information
      final licenseInfo = await _licenseOcrService.parseLicenseInfo(extractedText);

      if (mounted) {
        setState(() {
          _extractedLicenseInfo = licenseInfo;
          _isScanningLicense = false;
        });

        bool hasExtractedData = false;
        String extractedFields = '';

        // Auto-fill license number
        if (licenseInfo?.licenseNumber != null && licenseInfo!.licenseNumber!.isNotEmpty) {
          _licenseNumberController.text = licenseInfo.licenseNumber!;
          extractedFields += 'License Number: ${licenseInfo.licenseNumber}';
          hasExtractedData = true;
        }

        // Auto-fill first name and last name from extracted license info
        // Always override existing values with extracted data
        if (licenseInfo?.lastName != null && licenseInfo!.lastName!.isNotEmpty) {
          _lastNameController.text = licenseInfo.lastName!;
          if (extractedFields.isNotEmpty) extractedFields += '\n';
          extractedFields += 'Last Name (Nom): ${licenseInfo.lastName}';
          hasExtractedData = true;
          print('✅ Overrode last name field with: ${licenseInfo.lastName}');
        }
        
        if (licenseInfo?.firstName != null && licenseInfo!.firstName!.isNotEmpty) {
          _firstNameController.text = licenseInfo.firstName!;
          if (extractedFields.isNotEmpty) extractedFields += '\n';
          extractedFields += 'First Name (Prenom): ${licenseInfo.firstName}';
          hasExtractedData = true;
          print('✅ Overrode first name field with: ${licenseInfo.firstName}');
        }
        
        // Fallback: if we have fullName but no separate firstName/lastName, try to parse it
        if ((licenseInfo?.firstName == null || licenseInfo!.firstName!.isEmpty) &&
            (licenseInfo?.lastName == null || licenseInfo!.lastName!.isEmpty) &&
            licenseInfo?.fullName != null && licenseInfo!.fullName!.isNotEmpty) {
          final fullName = licenseInfo.fullName!.trim();
          final nameParts = fullName.split(RegExp(r'\s+'));
          
          if (nameParts.length >= 2) {
            // For Tunisian names, typically: LASTNAME FIRSTNAME
            // So first part is usually last name (nom), rest is first name (prenom)
            _lastNameController.text = nameParts[0];
            _firstNameController.text = nameParts.sublist(1).join(' ');
            
            if (extractedFields.isNotEmpty) extractedFields += '\n';
            extractedFields += 'Name: ${_lastNameController.text} ${_firstNameController.text}'.trim();
            hasExtractedData = true;
          } else if (nameParts.length == 1) {
            // Single word - assume it's the last name (nom)
            _lastNameController.text = fullName;
            if (extractedFields.isNotEmpty) extractedFields += '\n';
            extractedFields += 'Last Name: $fullName';
            hasExtractedData = true;
          }
        }

        if (hasExtractedData) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Extracted information:\n$extractedFields'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not extract information from license. Please enter it manually.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanningLicense = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan license: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = ApiService.instance;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['id'] as int?;

      // Upload license image if available
      String? licenseImagePath;
      if (_licenseImagePath != null && userId != null) {
        try {
          final uploadResult = await FileUploadService.uploadLicenseImage(
            imageFile: File(_licenseImagePath!),
            userId: userId,
          );
          licenseImagePath = uploadResult['filePath'] ?? uploadResult['path'];
        } catch (e) {
          debugPrint('Warning: Failed to upload license image: $e');
          // Continue without image upload
        }
      }

      // Submit verification data
      await apiService.put('/users/submit-verification', {
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        if (licenseImagePath != null) 'licenseImagePath': licenseImagePath,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification data submitted successfully! Please wait for admin approval.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Refresh user data from server to get updated information
        try {
          final userId = authProvider.user?['id'] as int?;
          if (userId != null) {
            final updatedUserData = await apiService.get('/users/$userId');
            if (updatedUserData is Map<String, dynamic>) {
              // Update AuthProvider with fresh data from server
              authProvider.updateUserData({
                ...?authProvider.user,
                ...updatedUserData,
                'email': _emailController.text.trim(),
                'firstName': _firstNameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
                'licenseNumber': _licenseNumberController.text.trim(),
              });
            }
          }
        } catch (e) {
          debugPrint('Failed to refresh user data: $e');
          // Still update local data even if refresh fails
          final updatedUser = {...?authProvider.user};
          updatedUser['email'] = _emailController.text.trim();
          updatedUser['firstName'] = _firstNameController.text.trim();
          updatedUser['lastName'] = _lastNameController.text.trim();
          updatedUser['licenseNumber'] = _licenseNumberController.text.trim();
          authProvider.updateUserData(updatedUser);
        }
        
        // Navigate back or to home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit verification: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Account Verification'),
        centerTitle: true,
      ),
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator())
          : _isVerified
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.verified_user,
                        size: 100,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Account Verified',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your driver account has been verified successfully!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Go to Home',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          size: 80,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Complete Your Driver Profile',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please provide your information to verify your driver account. You can update this later in settings.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
              
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'your.email@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // First Name (Nom)
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name (Nom) *',
                  hintText: 'Enter your first name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Last Name (Prenom)
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name (Prenom) *',
                  hintText: 'Enter your last name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // License Number
              TextFormField(
                controller: _licenseNumberController,
                decoration: InputDecoration(
                  labelText: 'Driver License Number *',
                  hintText: 'Enter your license number or scan from photo',
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixIcon: _isScanningLicense
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.camera_alt),
                          tooltip: 'Scan from license photo',
                          onPressed: _scanLicenseFromPhoto,
                        ),
                  border: const OutlineInputBorder(),
                  helperText: 'Tap the camera icon to scan your license automatically',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your driver license number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Show extracted license info if available
              if (_extractedLicenseInfo != null) ...[
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'License Information Extracted',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (_extractedLicenseInfo!.fullName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Name: ${_extractedLicenseInfo!.fullName}',
                            style: TextStyle(fontSize: 11, color: Colors.green[900]),
                          ),
                        ],
                        if (_extractedLicenseInfo!.dateOfBirth != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Date of Birth: ${_extractedLicenseInfo!.dateOfBirth}',
                            style: TextStyle(fontSize: 11, color: Colors.green[900]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Info card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can scan your driver license photo to automatically extract the license number. Make sure the photo is clear and well-lit.',
                          style: TextStyle(color: Colors.blue[900], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Verification',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Skip for now button
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                child: const Text('Skip for now (I\'ll complete this later)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

