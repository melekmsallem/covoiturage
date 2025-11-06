import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/trip_service.dart';
import '../../services/api_service.dart';
import '../../widgets/simple_location_picker_widget.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService.instance;

  // Form controllers
  final _priceController = TextEditingController();
  final _maxSeatsController = TextEditingController(text: '4');

  // Form data
  DateTime? _departureTime;
  DateTime? _arrivalTime;
  List<dynamic> _cities = [];
  List<dynamic> _options = [];
  List<int> _selectedOptions = [];
  Map<String, dynamic>? _selectedDepartureCity;
  Map<String, dynamic>? _selectedArrivalCity;
  bool _isLoading = false;
  Map<String, dynamic>? _estimationResult;
  
  // Step-by-step form state
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Pickup mode variables
  String? _selectedPickupMode;
  List<Map<String, dynamic>> _pickupPoints = [];
  bool _allowLocationSharing = true;
  bool _flexiblePickupTimes = true;
  
  // GPS coordinates for departure and arrival
  Map<String, dynamic>? _departurePoint;
  Map<String, dynamic>? _arrivalPoint;
  
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
    _loadFormData();
    
    // Add listeners for real-time validation
    _priceController.addListener(_validatePrice);
    _maxSeatsController.addListener(_validateSeats);
  }

  @override
  void dispose() {
    _priceController.removeListener(_validatePrice);
    _maxSeatsController.removeListener(_validateSeats);
    _priceController.dispose();
    _maxSeatsController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      print('DEBUG: Loading form data from API...');
      
      // Load cities from real API
      final citiesResponse = await _apiService.getDynamic('/cities');
      print('DEBUG: Cities response: $citiesResponse');
      
      List<dynamic> citiesList = [];
      if (citiesResponse is List) {
        citiesList = citiesResponse;
      } else if (citiesResponse is Map && citiesResponse.containsKey('data')) {
        citiesList = citiesResponse['data'] as List<dynamic>? ?? [];
      }
      
      // Load options from real API
      final optionsResponse = await _apiService.getDynamic('/options');
      print('DEBUG: Options response: $optionsResponse');
      
      List<dynamic> optionsList = [];
      if (optionsResponse is List) {
        optionsList = optionsResponse;
      } else if (optionsResponse is Map && optionsResponse.containsKey('data')) {
        optionsList = optionsResponse['data'] as List<dynamic>? ?? [];
      }
      
      print('DEBUG: Loaded ${citiesList.length} cities and ${optionsList.length} options');
      
      setState(() {
        _cities = citiesList.cast<Map<String, dynamic>>();
        _options = optionsList.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load form data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Real-time validation methods
  void _validatePrice() {
    final value = _priceController.text;
    if (value.isEmpty) {
      setState(() => _priceError = 'Please enter a price');
    } else {
      final price = double.tryParse(value);
      if (price == null || price <= 0) {
        setState(() => _priceError = 'Please enter a valid price');
      } else if (price > 320) {
        setState(() => _priceError = 'Price is quite high (over 320 coins)');
      } else {
        setState(() => _priceError = null);
      }
    }
  }

  void _validateSeats() {
    final value = _maxSeatsController.text;
    if (value.isEmpty) {
      setState(() => _seatsError = 'Please enter number of seats');
    } else {
      final seats = int.tryParse(value);
      if (seats == null || seats < 1 || seats > 8) {
        setState(() => _seatsError = 'Seats must be between 1 and 8');
      } else {
        setState(() => _seatsError = null);
      }
    }
  }

  void _validateDepartureTime() {
    if (_departureTime == null) {
      setState(() => _departureTimeError = 'Please select departure time');
    } else if (_departureTime!.isBefore(DateTime.now())) {
      setState(() => _departureTimeError = 'Departure time must be in the future');
    } else {
      setState(() => _departureTimeError = null);
    }
  }

  void _validateArrivalTime() {
    if (_arrivalTime == null) {
      setState(() => _arrivalTimeError = 'Please select arrival time');
    } else if (_departureTime != null && _arrivalTime!.isBefore(_departureTime!)) {
      setState(() => _arrivalTimeError = 'Arrival time must be after departure time');
    } else {
      setState(() => _arrivalTimeError = null);
    }
  }

  void _validateDepartureCity() {
    if (_selectedDepartureCity == null) {
      setState(() => _departureCityError = 'Please select departure city');
    } else if (_selectedDepartureCity!['name']?.toString().isEmpty ?? true) {
      setState(() => _departureCityError = 'Please select departure city');
    } else {
      setState(() => _departureCityError = null);
    }
  }

  void _validateArrivalCity() {
    if (_selectedArrivalCity == null) {
      setState(() => _arrivalCityError = 'Please select arrival city');
    } else if (_selectedArrivalCity!['name']?.toString().isEmpty ?? true) {
      setState(() => _arrivalCityError = 'Please select arrival city');
    } else if (_selectedDepartureCity != null && 
               _selectedDepartureCity!['name'] == _selectedArrivalCity!['name']) {
      setState(() => _arrivalCityError = 'Arrival city should be different from departure city');
    } else {
      setState(() => _arrivalCityError = null);
    }
  }

  bool _isFormValid() {
    return _priceError == null &&
           _seatsError == null &&
           _departureTimeError == null &&
           _arrivalTimeError == null &&
           _departureCityError == null &&
           _arrivalCityError == null &&
           _departureTime != null &&
           _arrivalTime != null &&
           _selectedDepartureCity != null &&
           _selectedArrivalCity != null &&
           _selectedPickupMode != null &&
           _departurePoint != null; // Departure point is required
  }

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0: // Route selection step
        return _selectedDepartureCity != null && 
               _selectedArrivalCity != null &&
               _departureCityError == null && 
               _arrivalCityError == null;
      case 1: // Date & Time step
        return _departureTime != null && 
               _arrivalTime != null &&
               _departureTimeError == null && 
               _arrivalTimeError == null;
      case 2: // Price & Seats step
        return _priceError == null && 
               _seatsError == null &&
               _priceController.text.isNotEmpty &&
               _maxSeatsController.text.isNotEmpty;
      case 3: // Pickup options step
        return _selectedPickupMode != null && 
               (_selectedPickupMode == 'FLEXIBLE' || _departurePoint != null);
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_isCurrentStepValid() && _currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _estimateTrip() async {
    if (_selectedDepartureCity == null || _selectedArrivalCity == null) {
      _showErrorSnackBar('Please select departure and arrival cities');
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('DEBUG: Estimating trip from ${_selectedDepartureCity!['name']} to ${_selectedArrivalCity!['name']}');
      
      // Use real API call for trip estimation
      final estimationRequest = {
        'departureAddress': _selectedDepartureCity!['name'],
        'arrivalAddress': _selectedArrivalCity!['name'],
      };
      
      // Use real trip estimation endpoint
      final estimationResponse = await _apiService.postPublic('/trip-creation/estimate', estimationRequest);
      print('DEBUG: Estimation response: $estimationResponse');
      
      // Validate response structure before setting
      if (estimationResponse.containsKey('distance') && 
          estimationResponse.containsKey('durationFormatted') && 
          estimationResponse.containsKey('estimatedFuelCost')) {
        setState(() => _estimationResult = estimationResponse);
      // Trip estimated successfully
      } else {
        print('DEBUG: Invalid estimation response structure: $estimationResponse');
        _showErrorSnackBar('Invalid estimation response. Please try again.');
      }
    } catch (e) {
      print('DEBUG: Estimation error: $e');
      String errorMessage = 'Estimation failed';
      
      if (e.toString().contains('403')) {
        errorMessage = 'Authentication error. Please log in again.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Estimation service not available. Please try again.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      } else {
        errorMessage = 'Estimation error: $e';
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTrip() async {
    if (!_isFormValid()) {
      _showErrorSnackBar('Please fix all validation errors before creating the trip');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Create pickup points list - include departure point as first pickup point
      List<Map<String, dynamic>> finalPickupPoints = [];
      if (_selectedPickupMode == 'DESIGNATED_POINT') {
        // Add departure point as the first pickup point
        if (_departurePoint != null) {
          finalPickupPoints.add({
            'address': _departurePoint!['address'],
            'latitude': _departurePoint!['latitude'],
            'longitude': _departurePoint!['longitude'],
            'pickupTime': _departureTime!.toIso8601String(),
            'maxWaitingTime': 10, // 10 minutes default
            'pickupOrder': 1,
          });
        }
        // Add other designated pickup points
        for (int i = 0; i < _pickupPoints.length; i++) {
          finalPickupPoints.add({
            'address': _pickupPoints[i]['address'],
            'latitude': _pickupPoints[i]['latitude'],
            'longitude': _pickupPoints[i]['longitude'],
            'pickupTime': _pickupPoints[i]['pickupTime'] ?? _departureTime!.toIso8601String(),
            'maxWaitingTime': _pickupPoints[i]['maxWaitingTime'] ?? 10,
            'pickupOrder': i + 2, // Start from 2 since departure is 1
          });
        }
      }

      // Create real trip using API
      final tripData = {
        'departureCity': _selectedDepartureCity!['name'],
        'arrivalCity': _selectedArrivalCity!['name'],
        'departureTime': _departureTime!.toIso8601String(),
        'arrivalTime': _arrivalTime!.toIso8601String(),
        'pricePerSeat': double.tryParse(_priceController.text) ?? 0.0,
        'maxSeats': int.tryParse(_maxSeatsController.text) ?? 1,
        'description': 'Carpool trip',
        'optionIds': _selectedOptions,
        'pickupMode': _selectedPickupMode,
        'pickupPoints': _selectedPickupMode == 'DESIGNATED_POINT' ? finalPickupPoints : null,
        'allowLocationSharing': _allowLocationSharing,
        'flexiblePickupTimes': _flexiblePickupTimes,
        // Add GPS coordinates - departure is always required, arrival is optional
        if (_departurePoint != null) 'departurePoint': _departurePoint,
        if (_arrivalPoint != null) 'arrivalPoint': _arrivalPoint,
      };

      final tripService = TripService();
      final result = await tripService.createTrip(tripData);
      
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create trip: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Trip (Step ${_currentStep + 1}/$_totalSteps)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(),
                    const SizedBox(height: 24),
                    _buildCurrentStep(),
                    const SizedBox(height: 24),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Creation Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(_totalSteps, (index) {
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent 
                          ? Colors.blue 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getStepTitle(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Step a: Select Route (Departure & Arrival Cities)';
      case 1:
        return 'Step b: Set Date & Time';
      case 2:
        return 'Step c: Set Price & Number of Seats';
      case 3:
        return 'Step d: Configure Pickup Options';
      default:
        return 'Unknown Step';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildRouteSelectionStep();
      case 1:
        return _buildDateTimeStep();
      case 2:
        return _buildPriceAndSeatsStep();
      case 3:
        return _buildPickupOptionsStep();
      default:
        return Container();
    }
  }

  Widget _buildRouteSelectionStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.teal.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: Colors.green.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Route Selection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Departure city selection
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedDepartureCity,
              decoration: InputDecoration(
                labelText: 'Departure City',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _departureCityError,
              ),
              items: _cities.map((city) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: city,
                  child: Text(city['name'] ?? 'Unknown City'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartureCity = value;
                });
                _validateDepartureCity();
                _validateArrivalCity(); // Re-validate arrival city
              },
            ),
            const SizedBox(height: 16),
            // Arrival city selection
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedArrivalCity,
              decoration: InputDecoration(
                labelText: 'Arrival City',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _arrivalCityError,
              ),
              items: _cities.map((city) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: city,
                  child: Text(city['name'] ?? 'Unknown City'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedArrivalCity = value;
                });
                _validateArrivalCity();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeStep() {
    return _buildDateTimeSection();
  }

  Widget _buildPriceAndSeatsStep() {
    return _buildBasicInfoSection();
  }

  Widget _buildPickupOptionsStep() {
    return Column(
      children: [
        _buildPickupModeSection(),
        const SizedBox(height: 16),
        _buildLocationSection(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: ElevatedButton(
                  onPressed: _previousStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Previous'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _currentStep == _totalSteps - 1 
                    ? (_isLoading || !_isFormValid()) ? null : _createTrip
                    : _isCurrentStepValid() ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == _totalSteps - 1 
                      ? (_isFormValid() ? Colors.blue : Colors.grey)
                      : (_isCurrentStepValid() ? Colors.blue : Colors.grey),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_currentStep == _totalSteps - 1 
                        ? (_isFormValid() ? 'Create Trip' : 'Complete all steps')
                        : (_isCurrentStepValid() ? 'Continue' : 'Complete this step')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.car_rental, color: Colors.blue.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price per Seat (coins)',
                  prefixIcon: Icon(Icons.monetization_on, color: Colors.amber.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                errorText: _priceError,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
              controller: _maxSeatsController,
              decoration: InputDecoration(
                labelText: 'Maximum Seats',
                  prefixIcon: Icon(Icons.people, color: Colors.orange.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                errorText: _seatsError,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.red.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
              'Date & Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.departure_board),
                  title: Text(_departureTime == null
                      ? 'Select Departure Time'
                      : 'Departure: ${_formatDateTime(_departureTime!)}'),
                  trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _departureTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                    _validateDepartureTime();
                    _validateArrivalTime(); // Re-validate arrival time
                  }
                }
              },
                ),
                if (_departureTimeError != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    child: Text(
                      _departureTimeError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(_arrivalTime == null
                      ? 'Select Arrival Time'
                      : 'Arrival: ${_formatDateTime(_arrivalTime!)}'),
                  trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _departureTime?.add(const Duration(hours: 2)) ?? 
                             DateTime.now().add(const Duration(days: 1)),
                  firstDate: _departureTime ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 11, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _arrivalTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                    _validateArrivalTime();
                  }
                }
              },
                ),
                if (_arrivalTimeError != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    child: Text(
                      _arrivalTimeError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.teal.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: Colors.green.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Route Selection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (Map<String, dynamic> option) => option['name'] ?? '',
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _cities.cast<Map<String, dynamic>>().take(10); // Show first 10 cities alphabetically
                }
                
                // Filter cities that start with the typed text
                final matchingCities = _cities.cast<Map<String, dynamic>>().where((city) =>
                    city['name'].toString().toLowerCase().startsWith(textEditingValue.text.toLowerCase())
                ).toList();
                
                // If we have matches, show them first, then add other cities alphabetically
                if (matchingCities.isNotEmpty) {
                  final otherCities = _cities.cast<Map<String, dynamic>>().where((city) =>
                      !city['name'].toString().toLowerCase().startsWith(textEditingValue.text.toLowerCase())
                  ).toList();
                  return [...matchingCities, ...otherCities].take(15);
                }
                
                // If no matches, show all cities alphabetically
                return _cities.cast<Map<String, dynamic>>().take(15);
              },
              onSelected: (Map<String, dynamic> selection) {
                setState(() {
                  _selectedDepartureCity = selection;
                });
                _validateDepartureCity();
                _validateArrivalCity(); // Re-validate arrival city
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Departure City',
                    prefixIcon: const Icon(Icons.location_on),
                    border: const OutlineInputBorder(),
                    hintText: 'Type to search cities...',
                    errorText: _departureCityError,
                  ),
                  onChanged: (value) {
                    _validateDepartureCity();
                    _validateArrivalCity(); // Re-validate arrival city
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
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
                          final option = options.elementAt(index);
                          final cityName = option['name'].toString();
                          final isHighlighted = cityName.toLowerCase().startsWith(
                            _selectedDepartureCity?['name']?.toString().toLowerCase() ?? ''
                          );
                          
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isHighlighted ? Colors.blue.shade50 : null,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_city,
                                    size: 20,
                                    color: isHighlighted ? Colors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cityName,
                                      style: TextStyle(
                                        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                                        color: isHighlighted ? Colors.blue : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
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
            const SizedBox(height: 16),
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (Map<String, dynamic> option) => option['name'] ?? '',
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _cities.cast<Map<String, dynamic>>().take(10); // Show first 10 cities alphabetically
                }
                
                // Filter cities that start with the typed text
                final matchingCities = _cities.cast<Map<String, dynamic>>().where((city) =>
                    city['name'].toString().toLowerCase().startsWith(textEditingValue.text.toLowerCase())
                ).toList();
                
                // If we have matches, show them first, then add other cities alphabetically
                if (matchingCities.isNotEmpty) {
                  final otherCities = _cities.cast<Map<String, dynamic>>().where((city) =>
                      !city['name'].toString().toLowerCase().startsWith(textEditingValue.text.toLowerCase())
                  ).toList();
                  return [...matchingCities, ...otherCities].take(15);
                }
                
                // If no matches, show all cities alphabetically
                return _cities.cast<Map<String, dynamic>>().take(15);
              },
              onSelected: (Map<String, dynamic> selection) {
                setState(() {
                  _selectedArrivalCity = selection;
                });
                _validateArrivalCity();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Arrival City',
                    prefixIcon: const Icon(Icons.location_on),
                    border: const OutlineInputBorder(),
                    hintText: 'Type to search cities...',
                    errorText: _arrivalCityError,
                  ),
                  onChanged: (value) {
                    _validateArrivalCity();
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
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
                          final option = options.elementAt(index);
                          final cityName = option['name'].toString();
                          final isHighlighted = cityName.toLowerCase().startsWith(
                            _selectedArrivalCity?['name']?.toString().toLowerCase() ?? ''
                          );
                          
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isHighlighted ? Colors.blue.shade50 : null,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_city,
                                    size: 20,
                                    color: isHighlighted ? Colors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cityName,
                                      style: TextStyle(
                                        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                                        color: isHighlighted ? Colors.blue : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
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
            const SizedBox(height: 16),
            
            // GPS Coordinate Selection for Departure
            if (_selectedDepartureCity != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SimpleLocationPickerWidget(
                              title: 'Select Departure Point',
                              onLocationSelected: _setDeparturePoint,
                              initialLocation: _departurePoint,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.my_location),
                      label: Text(_departurePoint != null 
                          ? 'Update Departure Point' 
                          : 'Set Departure Point'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_departurePoint != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _departurePoint = null;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Clear departure point',
                    ),
                ],
              ),
              if (_departurePoint != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_departurePoint!['address'] ?? 'Selected location'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
            
            // GPS Coordinate Selection for Arrival (Optional)
            if (_selectedArrivalCity != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arrival point is optional. If not set, passengers will be dropped off anywhere in ${_selectedArrivalCity!['name']}.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SimpleLocationPickerWidget(
                              title: 'Select Arrival Point (Optional)',
                              onLocationSelected: _setArrivalPoint,
                              initialLocation: _arrivalPoint,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.my_location),
                      label: Text(_arrivalPoint != null 
                          ? 'Update Arrival Point' 
                          : 'Set Arrival Point (Optional)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_arrivalPoint != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _arrivalPoint = null;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Clear arrival point',
                    ),
                ],
              ),
              if (_arrivalPoint != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_arrivalPoint!['address'] ?? 'Selected location'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _estimateTrip,
                icon: const Icon(Icons.route),
                label: const Text('Estimate Trip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    if (_options.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('No options available'),
            ],
          ),
        ),
      );
    }

    // Group options by category
    final Map<String, List<dynamic>> categorizedOptions = {};
    for (var option in _options) {
      final category = option['category'] ?? 'OTHER';
      if (!categorizedOptions.containsKey(category)) {
        categorizedOptions[category] = [];
      }
      categorizedOptions[category]!.add(option);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Trip Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_selectedOptions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedOptions.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...categorizedOptions.entries.map((entry) {
              return _buildCategorySection(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<dynamic> options) {
    final categoryInfo = _getCategoryInfo(category);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              categoryInfo['icon'],
              size: 20,
              color: categoryInfo['color'],
            ),
            const SizedBox(width: 8),
            Text(
              categoryInfo['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: categoryInfo['color'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((option) {
            final optionId = (option['id'] as num?)?.toInt() ?? 0;
            final isSelected = _selectedOptions.contains(optionId);
            final price = (option['price'] as num?)?.toDouble() ?? 0.0;
            
            return _buildOptionChip(option, optionId, isSelected, price);
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOptionChip(dynamic option, int optionId, bool isSelected, double price) {
    final iconName = option['iconName'] as String?;
    final name = option['name'] as String;
    final description = option['description'] as String?;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedOptions.remove(optionId);
          } else {
            _selectedOptions.add(optionId);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconName != null)
                  Icon(
                    _getIconData(iconName),
                    size: 16,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                  ),
                if (iconName != null) const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    price == 0 ? 'Free' : '+${price.toInt()} coins',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryInfo(String category) {
    switch (category) {
      case 'COMFORT':
        return {
          'name': 'Comfort',
          'icon': Icons.airline_seat_recline_normal,
          'color': Colors.orange,
        };
      case 'SAFETY':
        return {
          'name': 'Safety',
          'icon': Icons.security,
          'color': Colors.red,
        };
      case 'PETS':
        return {
          'name': 'Pets',
          'icon': Icons.pets,
          'color': Colors.green,
        };
      case 'LUGGAGE':
        return {
          'name': 'Luggage',
          'icon': Icons.luggage,
          'color': Colors.brown,
        };
      case 'ENTERTAINMENT':
        return {
          'name': 'Entertainment',
          'icon': Icons.movie,
          'color': Colors.purple,
        };
      case 'FOOD':
        return {
          'name': 'Food & Drinks',
          'icon': Icons.restaurant,
          'color': Colors.amber,
        };
      default:
        return {
          'name': 'Other',
          'icon': Icons.more_horiz,
          'color': Colors.grey,
        };
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'ac_unit': return Icons.ac_unit;
      case 'thermostat': return Icons.thermostat;
      case 'chair': return Icons.chair;
      case 'spa': return Icons.spa;
      case 'chair_alt': return Icons.chair_alt;
      case 'space_dashboard': return Icons.space_dashboard;
      case 'child_care': return Icons.child_care;
      case 'medical_services': return Icons.medical_services;
      case 'emergency': return Icons.emergency;
      case 'navigation': return Icons.navigation;
      case 'videocam': return Icons.videocam;
      case 'pets': return Icons.pets;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'luggage': return Icons.luggage;
      case 'pedal_bike': return Icons.pedal_bike;
      case 'downhill_skiing': return Icons.downhill_skiing;
      case 'roofing': return Icons.roofing;
      case 'wifi': return Icons.wifi;
      case 'wifi_hotspot': return Icons.wifi_tethering;
      case 'power': return Icons.power;
      case 'bluetooth': return Icons.bluetooth;
      case 'bluetooth_audio': return Icons.bluetooth_audio;
      case 'tablet': return Icons.tablet;
      case 'menu_book': return Icons.menu_book;
      case 'water_drop': return Icons.water_drop;
      case 'restaurant': return Icons.restaurant;
      case 'coffee': return Icons.coffee;
      case 'kitchen': return Icons.kitchen;
      case 'smoking_rooms': return Icons.smoking_rooms;
      case 'smoke_free': return Icons.smoke_free;
      case 'volume_off': return Icons.volume_off;
      case 'business': return Icons.business;
      case 'star': return Icons.star;
      case 'heating': return Icons.thermostat;
      case 'air_conditioning': return Icons.ac_unit;
      case 'extra_luggage': return Icons.luggage;
      case 'food_drinks': return Icons.restaurant;
      case 'entertainment': return Icons.movie;
      case 'comfort': return Icons.airline_seat_recline_normal;
      case 'safety': return Icons.security;
      case 'local_drink': return Icons.local_drink;
      case 'movie': return Icons.movie;
      case 'security': return Icons.security;
      default: return Icons.help_outline;
    }
  }


  Widget _buildEstimationSection() {
    if (_estimationResult == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Estimation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEstimationCard(
                    'Distance',
                    '${_estimationResult!['distance'] ?? 'N/A'} km',
                    Icons.straighten,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstimationCard(
                    'Duration',
                    _estimationResult!['durationFormatted'] ?? 'N/A',
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEstimationCard(
              'Estimated Fuel Cost',
              '${_estimationResult!['estimatedFuelCost'] ?? 'N/A'} coins',
              Icons.local_gas_station,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimationCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade600),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.teal.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pickup Mode',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How do you want to handle passenger pickups?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Designated Points'),
                    subtitle: const Text('Set specific pickup locations'),
                    value: 'DESIGNATED_POINT',
                    groupValue: _selectedPickupMode,
                    onChanged: (value) {
                      setState(() {
                        _selectedPickupMode = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Individual Pickup'),
                    subtitle: const Text('Pick up each passenger individually'),
                    value: 'INDIVIDUAL_PICKUP',
                    groupValue: _selectedPickupMode,
                    onChanged: (value) {
                      setState(() {
                        _selectedPickupMode = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
            if (_selectedPickupMode == 'DESIGNATED_POINT') ...[
              const SizedBox(height: 16),
              _buildDesignatedPointsSection(),
            ] else if (_selectedPickupMode == 'INDIVIDUAL_PICKUP') ...[
              const SizedBox(height: 16),
              _buildIndividualPickupSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesignatedPointsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Designated Pickup Points',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show warning if departure point is not set
          if (_departurePoint == null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You must set a departure point first. Use the GPS coordinate selector above.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Always show departure point as first pickup point
          if (_departurePoint != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: const Text('1', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Departure Point (Automatic)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _departurePoint!['address'] ?? 'Selected location',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Show additional pickup points
          if (_pickupPoints.isEmpty && _departurePoint == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off, color: Colors.grey.shade400, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'No pickup points added yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_pickupPoints.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pickupPoints.length,
              itemBuilder: (context, index) {
                return _buildPickupPointCard(index);
              },
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The departure point is automatically included as the first pickup point. Add additional pickup points below.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _departurePoint != null ? _addPickupPoint : null,
              icon: const Icon(Icons.add_location),
              label: Text(_departurePoint != null 
                  ? 'Add Additional Pickup Point' 
                  : 'Set Departure Point First'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _departurePoint != null ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualPickupSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin_circle, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              Text(
                'Individual Pickup Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Allow passenger location sharing'),
            subtitle: const Text('Passengers can share their exact location'),
            value: _allowLocationSharing,
            onChanged: (value) {
              setState(() {
                _allowLocationSharing = value;
              });
            },
            activeColor: Colors.orange,
          ),
          SwitchListTile(
            title: const Text('Flexible pickup times'),
            subtitle: const Text('Allow small time adjustments'),
            value: _flexiblePickupTimes,
            onChanged: (value) {
              setState(() {
                _flexiblePickupTimes = value;
              });
            },
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPickupPointCard(int index) {
    final point = _pickupPoints[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text('${index + 2}'), // Start from 2 since departure is 1
        ),
        title: Text(point['address'] ?? 'Select location'),
        subtitle: Text('Pickup time: ${point['pickupTime']?.toString() ?? 'Not set'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editPickupPoint(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removePickupPoint(index),
            ),
          ],
        ),
      ),
    );
  }

  void _addPickupPoint() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimpleLocationPickerWidget(
          title: 'Select Pickup Point',
          onLocationSelected: (locationData) {
            setState(() {
              _pickupPoints.add({
                ...locationData,
                'pickupTime': null,
                'maxWaitingTime': 5, // Default 5 minutes
                'pickupOrder': _pickupPoints.length + 1,
              });
            });
          },
        ),
      ),
    );
  }

  void _editPickupPoint(int index) {
    final existingPoint = _pickupPoints[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimpleLocationPickerWidget(
          title: 'Edit Pickup Point',
          initialLocation: existingPoint,
          onLocationSelected: (locationData) {
            setState(() {
              _pickupPoints[index] = {
                ..._pickupPoints[index],
                ...locationData,
              };
            });
          },
        ),
      ),
    );
  }

  void _removePickupPoint(int index) {
    setState(() {
      _pickupPoints.removeAt(index);
    });
  }


  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !_isFormValid()) ? null : _createTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFormValid() ? Colors.blue : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(_isFormValid() ? 'Create Trip' : 'Fix errors to create trip'),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Method to set departure GPS coordinates
  void _setDeparturePoint(Map<String, dynamic> point) {
    setState(() {
      _departurePoint = point;
    });
  }

  // Method to set arrival GPS coordinates  
  void _setArrivalPoint(Map<String, dynamic> point) {
    setState(() {
      _arrivalPoint = point;
    });
  }
}

