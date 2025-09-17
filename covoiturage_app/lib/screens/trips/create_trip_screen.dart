import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/trip_creation_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripCreationService = TripCreationService();

  // Form controllers
  final _priceController = TextEditingController();
  final _maxSeatsController = TextEditingController(text: '4');
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
  Map<String, dynamic>? _estimationResult;
  
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
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      final formData = await _tripCreationService.getFormData();
      setState(() {
        _cities = formData['cities'] ?? [];
        _options = formData['options'] ?? [];
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
        setState(() => _priceError = 'Price is quite high (over 320 TND)');
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
           _selectedArrivalCity != null;
  }

  Future<void> _estimateTrip() async {
    if (_selectedDepartureCity == null || _selectedArrivalCity == null) {
      _showErrorSnackBar('Please select departure and arrival cities');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final routeData = _tripCreationService.formatRouteData(
        departureAddress: _selectedDepartureCity!['name'],
        arrivalAddress: _selectedArrivalCity!['name'],
      );

      final estimation = await _tripCreationService.estimateTrip(routeData);
      setState(() => _estimationResult = estimation);
      _showSuccessSnackBar('Trip estimated successfully!');
    } catch (e) {
      _showErrorSnackBar('Estimation error: $e');
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
      final tripData = _tripCreationService.formatTripData(
        departureTime: _departureTime!,
        arrivalTime: _arrivalTime!,
        pricePerSeat: double.parse(_priceController.text),
        maxSeats: int.parse(_maxSeatsController.text),
        departureCity: _selectedDepartureCity!['name'],
        arrivalCity: _selectedArrivalCity!['name'],
        description: _descriptionController.text,
        optionIds: _selectedOptions.isNotEmpty ? _selectedOptions : null,
        departurePoint: {
          'latitude': _selectedDepartureCity!['latitude']?.toDouble() ?? 0.0,
          'longitude': _selectedDepartureCity!['longitude']?.toDouble() ?? 0.0,
        },
        arrivalPoint: {
          'latitude': _selectedArrivalCity!['latitude']?.toDouble() ?? 0.0,
          'longitude': _selectedArrivalCity!['longitude']?.toDouble() ?? 0.0,
        },
      );

      final result = await _tripCreationService.createTrip(tripData);
      
      if (mounted) {
        _showSuccessSnackBar('Trip created successfully!');
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

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Trip'),
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
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildOptionsSection(),
                    const SizedBox(height: 24),
                    _buildEstimationSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
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
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price per Seat (TND)',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
                errorText: _priceError,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxSeatsController,
              decoration: InputDecoration(
                labelText: 'Maximum Seats',
                prefixIcon: const Icon(Icons.people),
                border: const OutlineInputBorder(),
                errorText: _seatsError,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
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
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const Text(
              'Route',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedDepartureCity,
              decoration: InputDecoration(
                labelText: 'Departure City',
                prefixIcon: const Icon(Icons.location_on),
                border: const OutlineInputBorder(),
                errorText: _departureCityError,
              ),
              items: _cities.map((city) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: city,
                  child: Text(city['name'].toString()),
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
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedArrivalCity,
              decoration: InputDecoration(
                labelText: 'Arrival City',
                prefixIcon: const Icon(Icons.location_on),
                border: const OutlineInputBorder(),
                errorText: _arrivalCityError,
              ),
              items: _cities.map((city) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: city,
                  child: Text(city['name'].toString()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedArrivalCity = value;
                });
                _validateArrivalCity();
              },
            ),
            const SizedBox(height: 16),
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
            final optionId = option['id'] as int;
            final isSelected = _selectedOptions.contains(optionId);
            final price = option['price'] as double;
            
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
                    price == 0 ? 'Free' : '+${price.toInt()} TND',
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
      case 'power': return Icons.power;
      case 'bluetooth': return Icons.bluetooth;
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
                    '${_estimationResult!['distance']} km',
                    Icons.straighten,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstimationCard(
                    'Duration',
                    _estimationResult!['durationFormatted'],
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEstimationCard(
              'Estimated Fuel Cost',
              '${_estimationResult!['estimatedFuelCost']} TND',
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
}

