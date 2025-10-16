import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/trip_creation_service.dart';
import '../../services/trip_service.dart';

class EditTripScreen extends StatefulWidget {
  final int tripId;
  final String tripTitle;

  const EditTripScreen({
    super.key,
    required this.tripId,
    required this.tripTitle,
  });

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripCreationService = TripCreationService();
  final _tripService = TripService();

  // Form controllers
  final _priceController = TextEditingController();
  final _maxSeatsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form data
  DateTime? _departureTime;
  DateTime? _arrivalTime;
  List<dynamic> _cities = [];
  List<dynamic> _options = [];
  List<int> _selectedOptions = [];
  Map<String, dynamic>? _selectedDepartureCity;
  Map<String, dynamic>? _selectedArrivalCity;
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _tripData;
  
  // Validation errors
  String? _priceError;
  String? _seatsError;
  String? _departureTimeError;
  String? _arrivalTimeError;
  String? _departureCityError;
  String? _arrivalCityError;

  @override
  void initState() {
    super.initState();
    _loadTripData();
    _loadFormData();
    
    // Add listeners for real-time validation
    _priceController.addListener(_validatePrice);
    _maxSeatsController.addListener(_validateSeats);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _maxSeatsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTripData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tripData = await _tripService.getTripById(widget.tripId);
      setState(() {
        _tripData = tripData;
        _populateFormWithTripData();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trip: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormWithTripData() {
    if (_tripData == null) return;

    _priceController.text = _tripData!['pricePerSeat']?.toString() ?? '';
    _maxSeatsController.text = _tripData!['maxSeats']?.toString() ?? '4';
    _descriptionController.text = _tripData!['description'] ?? '';

    // Parse departure and arrival times
    if (_tripData!['departureTime'] != null) {
      _departureTime = DateTime.parse(_tripData!['departureTime']);
    }
    if (_tripData!['arrivalTime'] != null) {
      _arrivalTime = DateTime.parse(_tripData!['arrivalTime']);
    }

    // Set selected options
    if (_tripData!['options'] != null) {
      _selectedOptions = List<int>.from(_tripData!['options'].map((opt) => opt['id']));
    }

    // Set departure and arrival cities
    if (_tripData!['departureCity'] != null) {
      _selectedDepartureCity = {'name': _tripData!['departureCity']};
    }
    if (_tripData!['arrivalCity'] != null) {
      _selectedArrivalCity = {'name': _tripData!['arrivalCity']};
    }
  }

  Future<void> _loadFormData() async {
    try {
      final formData = await _tripCreationService.getFormData();
      
      setState(() {
        _cities = formData['cities'] ?? [];
        _options = formData['options'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading form data: $e')),
        );
      }
    }
  }

  void _validatePrice() {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      setState(() {
        _priceError = 'Please enter a valid price';
      });
    } else {
      setState(() {
        _priceError = null;
      });
    }
  }

  void _validateSeats() {
    final seats = int.tryParse(_maxSeatsController.text);
    if (seats == null || seats < 1 || seats > 8) {
      setState(() {
        _seatsError = 'Please enter a valid number of seats (1-8)';
      });
    } else {
      setState(() {
        _seatsError = null;
      });
    }
  }

  void _validateDepartureTime() {
    if (_departureTime == null) {
      setState(() {
        _departureTimeError = 'Please select departure time';
      });
    } else if (_departureTime!.isBefore(DateTime.now())) {
      setState(() {
        _departureTimeError = 'Departure time must be in the future';
      });
    } else {
      setState(() {
        _departureTimeError = null;
      });
    }
  }

  void _validateArrivalTime() {
    if (_arrivalTime == null) {
      setState(() {
        _arrivalTimeError = 'Please select arrival time';
      });
    } else if (_departureTime != null && _arrivalTime!.isBefore(_departureTime!)) {
      setState(() {
        _arrivalTimeError = 'Arrival time must be after departure time';
      });
    } else {
      setState(() {
        _arrivalTimeError = null;
      });
    }
  }

  void _validateDepartureCity() {
    if (_selectedDepartureCity == null) {
      setState(() {
        _departureCityError = 'Please select departure city';
      });
    } else {
      setState(() {
        _departureCityError = null;
      });
    }
  }

  void _validateArrivalCity() {
    if (_selectedArrivalCity == null) {
      setState(() {
        _arrivalCityError = 'Please select arrival city';
      });
    } else if (_selectedDepartureCity != null && 
               _selectedArrivalCity!['name'] == _selectedDepartureCity!['name']) {
      setState(() {
        _arrivalCityError = 'Arrival city must be different from departure city';
      });
    } else {
      setState(() {
        _arrivalCityError = null;
      });
    }
  }

  bool _isFormValid() {
    _validateDepartureTime();
    _validateArrivalTime();
    _validateDepartureCity();
    _validateArrivalCity();
    
    return _departureTime != null &&
           _arrivalTime != null &&
           _selectedDepartureCity != null &&
           _selectedArrivalCity != null &&
           _priceError == null &&
           _seatsError == null &&
           _departureTimeError == null &&
           _arrivalTimeError == null &&
           _departureCityError == null &&
           _arrivalCityError == null;
  }

  Future<void> _saveTrip() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix all errors before saving')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final request = {
        'departureTime': _departureTime!.toIso8601String(),
        'arrivalTime': _arrivalTime!.toIso8601String(),
        'pricePerSeat': double.tryParse(_priceController.text) ?? 0.0,
        'maxSeats': int.tryParse(_maxSeatsController.text) ?? 1,
        'description': _descriptionController.text,
        'departureCity': _selectedDepartureCity!['name'],
        'arrivalCity': _selectedArrivalCity!['name'],
        'options': _selectedOptions,
      };

      await _tripService.updateTrip(widget.tripId, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip updated successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating trip: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDateTime(bool isDeparture) async {
    final now = DateTime.now();
    final initialDate = isDeparture ? _departureTime : _arrivalTime;
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: initialDate != null 
            ? TimeOfDay.fromDateTime(initialDate)
            : const TimeOfDay(hour: 9, minute: 0),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isDeparture) {
            _departureTime = dateTime;
            _validateDepartureTime();
            if (_arrivalTime != null) {
              _validateArrivalTime();
            }
          } else {
            _arrivalTime = dateTime;
            _validateArrivalTime();
          }
        });
      }
    }
  }

  void _showCityPicker(bool isDeparture) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDeparture ? 'Select Departure City' : 'Select Arrival City',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _cities.length,
                itemBuilder: (context, index) {
                  final city = _cities[index];
                  return ListTile(
                    title: Text(city['name']),
                    onTap: () {
                      setState(() {
                        if (isDeparture) {
                          _selectedDepartureCity = city;
                          _validateDepartureCity();
                          if (_selectedArrivalCity != null) {
                            _validateArrivalCity();
                          }
                        } else {
                          _selectedArrivalCity = city;
                          _validateArrivalCity();
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Trip Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final isSelected = _selectedOptions.contains(option['id']);
                  
                  return CheckboxListTile(
                    title: Text(option['name']),
                    subtitle: Text('${option['price']} TND'),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedOptions.add(option['id']);
                        } else {
                          _selectedOptions.remove(option['id']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit ${widget.tripTitle}'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.tripTitle}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveTrip,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Departure City
              const Text(
                'Departure City',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showCityPicker(true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _departureCityError != null ? Colors.red : Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDepartureCity?['name'] ?? 'Select departure city',
                          style: TextStyle(
                            color: _selectedDepartureCity == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              if (_departureCityError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _departureCityError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Arrival City
              const Text(
                'Arrival City',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showCityPicker(false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _arrivalCityError != null ? Colors.red : Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedArrivalCity?['name'] ?? 'Select arrival city',
                          style: TextStyle(
                            color: _selectedArrivalCity == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              if (_arrivalCityError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _arrivalCityError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Departure Time
              const Text(
                'Departure Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _departureTimeError != null ? Colors.red : Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _departureTime != null
                              ? '${_departureTime!.day}/${_departureTime!.month}/${_departureTime!.year} at ${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select departure time',
                          style: TextStyle(
                            color: _departureTime == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              if (_departureTimeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _departureTimeError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Arrival Time
              const Text(
                'Arrival Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _arrivalTimeError != null ? Colors.red : Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _arrivalTime != null
                              ? '${_arrivalTime!.day}/${_arrivalTime!.month}/${_arrivalTime!.year} at ${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select arrival time',
                          style: TextStyle(
                            color: _arrivalTime == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              if (_arrivalTimeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _arrivalTimeError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Price per Seat
              const Text(
                'Price per Seat (TND)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: InputDecoration(
                  hintText: 'Enter price per seat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: _priceError,
                ),
              ),
              const SizedBox(height: 16),

              // Max Seats
              const Text(
                'Maximum Seats',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxSeatsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter maximum number of seats',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: _seatsError,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter trip description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Trip Options
              const Text(
                'Trip Options',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showOptionsPicker,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_box, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedOptions.isEmpty
                              ? 'Select trip options (optional)'
                              : '${_selectedOptions.length} option(s) selected',
                          style: TextStyle(
                            color: _selectedOptions.isEmpty ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Update Trip',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
