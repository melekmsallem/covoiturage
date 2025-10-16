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
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      // Simulate API call with mock data
      await Future.delayed(const Duration(seconds: 1));
      
      // Create mock cities data for Tunisia
      final mockCities = [
        {'id': 1, 'name': 'Tunis', 'region': 'Tunis'},
        {'id': 2, 'name': 'Sfax', 'region': 'Sfax'},
        {'id': 3, 'name': 'Sousse', 'region': 'Sousse'},
        {'id': 4, 'name': 'Kairouan', 'region': 'Kairouan'},
        {'id': 5, 'name': 'Bizerte', 'region': 'Bizerte'},
        {'id': 6, 'name': 'Gabès', 'region': 'Gabès'},
        {'id': 7, 'name': 'Ariana', 'region': 'Ariana'},
        {'id': 8, 'name': 'Ben Arous', 'region': 'Ben Arous'},
        {'id': 9, 'name': 'Monastir', 'region': 'Monastir'},
        {'id': 10, 'name': 'Nabeul', 'region': 'Nabeul'},
        {'id': 11, 'name': 'Kasserine', 'region': 'Kasserine'},
        {'id': 12, 'name': 'Gafsa', 'region': 'Gafsa'},
        {'id': 13, 'name': 'Tozeur', 'region': 'Tozeur'},
        {'id': 14, 'name': 'Béja', 'region': 'Béja'},
        {'id': 15, 'name': 'Jendouba', 'region': 'Jendouba'},
        {'id': 16, 'name': 'Kef', 'region': 'Kef'},
        {'id': 17, 'name': 'Siliana', 'region': 'Siliana'},
        {'id': 18, 'name': 'Mahdia', 'region': 'Mahdia'},
        {'id': 19, 'name': 'Tataouine', 'region': 'Tataouine'},
        {'id': 20, 'name': 'Medenine', 'region': 'Medenine'},
      ];
      
      // Create mock trip options
      final mockOptions = [
        {'id': 1, 'name': 'Air Conditioning', 'icon': 'ac'},
        {'id': 2, 'name': 'WiFi', 'icon': 'wifi'},
        {'id': 3, 'name': 'Music', 'icon': 'music'},
        {'id': 4, 'name': 'Smoking Allowed', 'icon': 'smoking'},
        {'id': 5, 'name': 'Pet Friendly', 'icon': 'pets'},
        {'id': 6, 'name': 'Luggage Space', 'icon': 'luggage'},
      ];
      
      setState(() {
        _cities = mockCities;
        _options = mockOptions;
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
      // Simulate API call with mock estimation data
      await Future.delayed(const Duration(seconds: 2));
      
      // Create mock estimation result
      final mockEstimation = {
        'distance': '120.5',
        'durationFormatted': '2h 15min',
        'estimatedFuelCost': '15.2',
        'route': {
          'departure': _selectedDepartureCity!['name'],
          'arrival': _selectedArrivalCity!['name'],
        }
      };
      
      setState(() => _estimationResult = mockEstimation);
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
      // Simulate API call with mock trip creation
      await Future.delayed(const Duration(seconds: 2));
      
      // Create mock trip result
      final mockResult = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'departureCity': _selectedDepartureCity!['name'],
        'arrivalCity': _selectedArrivalCity!['name'],
        'departureTime': _departureTime!.toIso8601String(),
        'arrivalTime': _arrivalTime!.toIso8601String(),
        'pricePerSeat': double.tryParse(_priceController.text) ?? 0.0,
        'maxSeats': int.tryParse(_maxSeatsController.text) ?? 1,
        'status': 'ACTIVE',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      if (mounted) {
        _showSuccessSnackBar('Trip created successfully!');
        Navigator.of(context).pop(mockResult);
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
                prefixIcon: const Icon(Icons.payments),
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

