import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/ocr/license_ocr_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/car_model_service.dart';
import '../../services/color_service.dart';
import '../../services/file_upload_service.dart';
import '../../widgets/color_picker_widget.dart';
import '../home/home_screen.dart';

class VehicleInfoScreen extends StatefulWidget {
  final String role;
  final String phoneNumber;
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? licenseNumber;
  final String? licenseImagePath;

  const VehicleInfoScreen({
    super.key,
    required this.role,
    required this.phoneNumber,
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.licenseNumber,
    this.licenseImagePath,
  });

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _maxPassengersController = TextEditingController();
  
  // Car models data
  List<Map<String, dynamic>> _carModels = [];
  List<String> _filteredModels = [];
  bool _isLoadingModels = false;
  
  // Color data
  List<Map<String, dynamic>> _colors = [];
  List<Map<String, dynamic>> _filteredColors = [];
  bool _isLoadingColors = false;
  
  bool _isLoading = false;
  final _imagePicker = ImagePicker();
  final _licenseOcrService = LicenseOcrService();

  @override
  void initState() {
    super.initState();
    // Initialize license controller with scanned license number if available
    if (widget.licenseNumber != null && widget.licenseNumber!.isNotEmpty) {
      _licenseController.text = widget.licenseNumber!;
    }
    _loadCarModels();
    _loadColors();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehiclePlateController.dispose();
    _maxPassengersController.dispose();
    _licenseOcrService.close();
    super.dispose();
  }

  Future<void> _loadCarModels() async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      debugPrint('Loading car models...');
      final models = await CarModelService.getAllCarModels();
      debugPrint('Loaded ${models.length} car models');
      
      if (models.isNotEmpty) {
        debugPrint('First model: ${models.first}');
      }
      
      setState(() {
        _carModels = models;
        _filteredModels = models.map((model) => '${model['brand']} ${model['model']}').toList();
        _isLoadingModels = false;
      });
      debugPrint('Filtered models: ${_filteredModels.length}');
      if (_filteredModels.isNotEmpty) {
        debugPrint('First filtered model: ${_filteredModels.first}');
      }
    } catch (e) {
      setState(() {
        _isLoadingModels = false;
      });
      debugPrint('Failed to load car models: $e');
    }
  }

  Future<void> _scanLicenseFromImage() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      final file = File(picked.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Running OCR...')),
      );

      final result = await _licenseOcrService.scanImage(file);

      if (result.licenseNumber != null && result.licenseNumber!.isNotEmpty) {
        _licenseController.text = result.licenseNumber!;
      }
      if (result.vehiclePlate != null && result.vehiclePlate!.isNotEmpty) {
        _vehiclePlateController.text = result.vehiclePlate!;
      }

      if ((result.licenseNumber == null || result.licenseNumber!.isEmpty) &&
          (result.vehiclePlate == null || result.vehiclePlate!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR done, no license fields found. Check lighting/angle or try another photo.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR fields filled from image.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR failed: $e')),
      );
    }
  }

  void _filterCarModels(String query) {
    debugPrint('Filtering car models with query: "$query"');
    if (query.isEmpty) {
      setState(() {
        _filteredModels = _carModels.map((model) => '${model['brand']} ${model['model']}').toList();
      });
      debugPrint('Empty query, showing all ${_filteredModels.length} models');
      return;
    }

    final filtered = _carModels
        .where((model) {
          final brand = model['brand']?.toString().toLowerCase() ?? '';
          final modelName = model['model']?.toString().toLowerCase() ?? '';
          final fullName = '${model['brand']} ${model['model']}'.toLowerCase();
          final queryLower = query.toLowerCase();
          
          return brand.contains(queryLower) || 
                 modelName.contains(queryLower) || 
                 fullName.contains(queryLower);
        })
        .map((model) => '${model['brand']} ${model['model']}')
        .toList();

    setState(() {
      _filteredModels = filtered;
    });
    debugPrint('Filtered to ${_filteredModels.length} models');
  }

  Future<void> _loadColors() async {
    setState(() {
      _isLoadingColors = true;
    });

    try {
      debugPrint('Loading colors...');
      final colors = ColorService.getAllColors();
      debugPrint('Loaded ${colors.length} colors');
      
      if (colors.isNotEmpty) {
        debugPrint('First color: ${colors.first}');
      }
      
      setState(() {
        _colors = colors;
        _filteredColors = colors;
        _isLoadingColors = false;
      });
      debugPrint('Filtered colors: ${_filteredColors.length}');
      if (_filteredColors.isNotEmpty) {
        debugPrint('First filtered color: ${_filteredColors.first}');
      }
    } catch (e) {
      setState(() {
        _isLoadingColors = false;
      });
      debugPrint('Failed to load colors: $e');
    }
  }

  void _filterColors(String query) {
    debugPrint('Filtering colors with query: "$query"');
    if (query.isEmpty) {
      setState(() {
        _filteredColors = _colors;
      });
      debugPrint('Empty query, showing all ${_filteredColors.length} colors');
      return;
    }

    final filtered = _colors
        .where((color) {
          final name = color['name']?.toString().toLowerCase() ?? '';
          final category = color['category']?.toString().toLowerCase() ?? '';
          final queryLower = query.toLowerCase();
          
          return name.contains(queryLower) || category.contains(queryLower);
        })
        .toList();

    setState(() {
      _filteredColors = filtered;
    });
    debugPrint('Filtered to ${filtered.length} colors');
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    _createAccountDirectly();
  }

  Future<void> _createAccountDirectly() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authService = AuthService();
      final response = await authService.signUp(
        username: widget.username,
        email: widget.email,
        password: widget.password,
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: widget.phoneNumber,
        role: widget.role,
        licenseNumber: _licenseController.text.trim(),
        vehicleModel: _vehicleModelController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim(),
        vehiclePlate: _vehiclePlateController.text.trim(),
        maxPassengers: int.tryParse(_maxPassengersController.text),
      );

      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        // Clear any existing authentication before setting new one
        print('DEBUG: Logging out current user before signup');
        await authProvider.logout();
        print('DEBUG: Logging in new user with ID: ${response['id']}');
        await authProvider.login(response['token'], response);
        print('DEBUG: New user logged in successfully');
        
        // Account created successfully
        
        // Upload license image if provided
        if (widget.licenseImagePath != null && widget.role == 'CONDUCTEUR') {
          try {
            final userId = response['id'] as int;
            await FileUploadService.uploadLicenseImage(
              imageFile: File(widget.licenseImagePath!),
              userId: userId,
            );
            print('License image uploaded successfully');
          } catch (e) {
            print('Warning: Failed to upload license image: $e');
            // Don't fail the signup if image upload fails
          }
        }
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Navigate to home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Information'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                        Icons.directions_car,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vehicle Information',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tell us about your vehicle',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // License Number
                        TextFormField(
                          controller: _licenseController,
                          decoration: InputDecoration(
                            labelText: 'Driver\'s License Number',
                            prefixIcon: const Icon(Icons.credit_card),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'License number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Scan License Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _scanLicenseFromImage,
                            icon: const Icon(Icons.document_scanner),
                            label: const Text('Scan from license photo'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Vehicle Model with Autocomplete
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _filteredModels.take(10); // Show first 10 options when empty
                            }
                            return _filteredModels.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            }).take(10); // Limit to 10 suggestions
                          },
                          onSelected: (String selection) {
                            _vehicleModelController.text = selection;
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              onChanged: (value) {
                                _filterCarModels(value);
                              },
                              decoration: InputDecoration(
                                labelText: 'Vehicle Model',
                                hintText: 'Start typing to search...',
                                prefixIcon: _isLoadingModels 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.directions_car),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vehicle model is required';
                                }
                                return null;
                              },
                            );
                          },
                          optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(12),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Container(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            option,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Vehicle Color with Autocomplete
                        Autocomplete<Map<String, dynamic>>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _filteredColors.take(10); // Show first 10 options when empty
                            }
                            return _filteredColors.where((Map<String, dynamic> color) {
                              final name = color['name']?.toString().toLowerCase() ?? '';
                              final category = color['category']?.toString().toLowerCase() ?? '';
                              final query = textEditingValue.text.toLowerCase();
                              return name.contains(query) || category.contains(query);
                            }).take(10); // Limit to 10 suggestions
                          },
                          onSelected: (Map<String, dynamic> selection) {
                            _vehicleColorController.text = selection['name'];
                          },
                          displayStringForOption: (Map<String, dynamic> option) => option['name'],
                          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              onChanged: (value) {
                                _filterColors(value);
                              },
                              decoration: InputDecoration(
                                labelText: 'Vehicle Color',
                                hintText: 'Start typing to search...',
                                prefixIcon: _isLoadingColors 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.palette),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vehicle color is required';
                                }
                                return null;
                              },
                            );
                          },
                          optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Map<String, dynamic>> onSelected, Iterable<Map<String, dynamic>> options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final color = options.elementAt(index);
                                      return ColorPickerWidget(
                                        colorName: color['name'],
                                        hexColor: color['hex'],
                                        onTap: () => onSelected(color),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // License Plate and Max Passengers
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _vehiclePlateController,
                                decoration: InputDecoration(
                                  labelText: 'License Plate',
                                  hintText: '123TU4567',
                                  prefixIcon: const Icon(Icons.confirmation_number),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'License plate is required';
                                  }
                                  
                                  // Tunisian license plate format: 3 numbers + TU + 4 numbers
                                  final plateRegex = RegExp(r'^\d{3}TU\d{4}$');
                                  final cleanValue = value.trim().toUpperCase();
                                  
                                  if (!plateRegex.hasMatch(cleanValue)) {
                                    return 'Format: 3 numbers + TU + 4 numbers (e.g., 123TU4567)';
                                  }
                                  
                                  return null;
                                },
                                onChanged: (value) {
                                  // Auto-format the input
                                  final cleanValue = value.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
                                  
                                  if (cleanValue.length <= 3) {
                                    // Only numbers for first 3 digits
                                    _vehiclePlateController.value = TextEditingValue(
                                      text: cleanValue,
                                      selection: TextSelection.collapsed(offset: cleanValue.length),
                                    );
                                  } else if (cleanValue.length <= 5) {
                                    // Add TU after 3 digits
                                    final numbers = cleanValue.substring(0, 3);
                                    final remaining = cleanValue.substring(3);
                                    if (remaining.isEmpty || remaining == 'T') {
                                      _vehiclePlateController.value = TextEditingValue(
                                        text: numbers + 'T',
                                        selection: TextSelection.collapsed(offset: (numbers + 'T').length),
                                      );
                                    } else if (remaining == 'TU') {
                                      _vehiclePlateController.value = TextEditingValue(
                                        text: numbers + 'TU',
                                        selection: TextSelection.collapsed(offset: (numbers + 'TU').length),
                                      );
                                    } else {
                                      _vehiclePlateController.value = TextEditingValue(
                                        text: numbers + 'TU' + remaining.substring(2),
                                        selection: TextSelection.collapsed(offset: (numbers + 'TU' + remaining.substring(2)).length),
                                      );
                                    }
                                  } else {
                                    // Complete format: 3 numbers + TU + up to 4 numbers
                                    final numbers = cleanValue.substring(0, 3);
                                    final afterTU = cleanValue.substring(5);
                                    if (afterTU.length <= 4) {
                                      _vehiclePlateController.value = TextEditingValue(
                                        text: numbers + 'TU' + afterTU,
                                        selection: TextSelection.collapsed(offset: (numbers + 'TU' + afterTU).length),
                                      );
                                    } else {
                                      // Limit to 4 numbers after TU
                                      _vehiclePlateController.value = TextEditingValue(
                                        text: numbers + 'TU' + afterTU.substring(0, 4),
                                        selection: TextSelection.collapsed(offset: (numbers + 'TU' + afterTU.substring(0, 4)).length),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _maxPassengersController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Max Passengers',
                                  prefixIcon: const Icon(Icons.people),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Max passengers is required';
                                  }
                                  final num = int.tryParse(value);
                                  if (num == null || num < 1 || num > 8) {
                                    return 'Enter 1-8 passengers';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Next button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _next,
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
                                    'Next',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}








