import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../../services/license_ocr_service.dart';
import 'vehicle_info_screen.dart';

class LicenseScanningScreen extends StatefulWidget {
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String role;

  const LicenseScanningScreen({
    super.key,
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
  });

  @override
  State<LicenseScanningScreen> createState() => _LicenseScanningScreenState();
}

class _LicenseScanningScreenState extends State<LicenseScanningScreen> {
  final LicenseOCRService _ocrService = LicenseOCRService();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _capturedImagePath;
  DriverLicenseInfo? _extractedInfo;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });

      // Process the image with OCR
      await _processImage(image.path);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Failed to capture photo: $e');
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      final extractedText = await _ocrService.extractTextFromImage(imagePath);
      final licenseInfo = await _ocrService.parseLicenseInfo(extractedText);
      
      setState(() {
        _extractedInfo = licenseInfo;
        _isProcessing = false;
      });

      if (licenseInfo != null) {
        _showSuccessSnackBar('License information extracted successfully!');
      } else {
        _showErrorSnackBar('Could not extract license information. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Failed to process image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final imagePath = await _ocrService.pickImageFromGallery();
      if (imagePath != null) {
        setState(() {
          _capturedImagePath = imagePath;
        });
        await _processImage(imagePath);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _retakePhoto() {
    setState(() {
      _capturedImagePath = null;
      _extractedInfo = null;
    });
  }

  Future<void> _proceedWithManualEntry() async {
    // Don't upload the image here - we'll upload it after the user account is created
    // Just pass the image path to the next screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleInfoScreen(
            role: widget.role,
            phoneNumber: widget.phoneNumber,
            username: widget.username,
            email: widget.email,
            password: widget.password,
            firstName: widget.firstName,
            lastName: widget.lastName,
            licenseNumber: _extractedInfo?.licenseNumber ?? '',
            licenseImagePath: _capturedImagePath, // Pass the image path
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Driver License'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Icon(
                  Icons.credit_card,
                  size: 48,
                  color: Colors.blue[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan Your Driver License',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Position your license within the frame and ensure good lighting',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Camera preview or captured image
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCameraView(),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_extractedInfo != null) ...[
                  // Show extracted information
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text(
                              'License Information Extracted',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_extractedInfo!.licenseNumber != null)
                          Text('License Number: ${_extractedInfo!.licenseNumber}'),
                        if (_extractedInfo!.fullName != null)
                          Text('Name: ${_extractedInfo!.fullName}'),
                        if (_extractedInfo!.dateOfBirth != null)
                          Text('Date of Birth: ${_extractedInfo!.dateOfBirth}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    if (_capturedImagePath == null) ...[
                      // Camera controls
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isInitialized ? _capturePhoto : null,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ] else ...[
                      // After capture controls
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _retakePhoto,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retake'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _extractedInfo != null ? _proceedWithManualEntry : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),
                TextButton(
                  onPressed: _proceedWithManualEntry,
                  child: const Text('Enter License Number Manually'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isProcessing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Processing...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_capturedImagePath != null) {
      return Image.file(
        File(_capturedImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Camera not available'),
            ],
          ),
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }
}
