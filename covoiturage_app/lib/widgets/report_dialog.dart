import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportDialog extends StatefulWidget {
  final Map<String, dynamic> reportedUser;
  final int? bookingId;
  final int? tripId;
  final String userRole; // 'driver' or 'passenger'

  const ReportDialog({
    Key? key,
    required this.reportedUser,
    this.bookingId,
    this.tripId,
    required this.userRole,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedReportType;
  bool _isSubmitting = false;

  final List<Map<String, String>> _reportTypes = [
    {'value': 'HARASSMENT', 'label': 'Harassment'},
    {'value': 'INAPPROPRIATE_BEHAVIOR', 'label': 'Inappropriate Behavior'},
    {'value': 'NO_SHOW', 'label': 'No Show'},
    {'value': 'LATE_ARRIVAL', 'label': 'Late Arrival'},
    {'value': 'UNSAFE_DRIVING', 'label': 'Unsafe Driving'},
    {'value': 'INAPPROPRIATE_MESSAGES', 'label': 'Inappropriate Messages'},
    {'value': 'FRAUD', 'label': 'Fraud'},
    {'value': 'OTHER', 'label': 'Other'},
  ];

  String _getUserDisplayName() {
    final firstName = widget.reportedUser['firstName'] ?? '';
    final lastName = widget.reportedUser['lastName'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return widget.reportedUser['username'] ?? 'User';
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReportType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a report type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reportedUserId = widget.reportedUser['id'] as int?;
      if (reportedUserId == null) {
        throw Exception('Unable to identify the user to report');
      }

      final requestData = {
        'reportedUserId': reportedUserId,
        'bookingId': widget.bookingId,
        'tripId': widget.tripId,
        'reportType': _selectedReportType,
        'reason': _reportTypes.firstWhere(
          (type) => type['value'] == _selectedReportType,
          orElse: () => {'label': 'Other'},
        )['label'],
        'description': _descriptionController.text.trim(),
      };

      final apiService = ApiService.instance;
      await apiService.post('/reports', requestData);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. We will review it shortly.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserDisplayName();
    final userType = widget.userRole == 'driver' ? 'Driver' : 'Passenger';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.red[600], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report $userType',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reporting: $userName',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Report type selection
              Text(
                'Report Type *',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                hint: const Text('Select a reason'),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a report type';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Description *',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Please provide details about the incident...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

