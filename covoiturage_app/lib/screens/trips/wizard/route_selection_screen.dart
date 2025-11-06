import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_service.dart';

class RouteSelectionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onNext;

  const RouteSelectionScreen({
    super.key,
    this.initialData,
    required this.onNext,
  });

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  List<dynamic> _cities = [];
  Map<String, dynamic>? _selectedDepartureCity;
  Map<String, dynamic>? _selectedArrivalCity;
  String? _departureCityError;
  String? _arrivalCityError;
  bool _isLoading = false;
  
  // Text controllers for city input
  final TextEditingController _departureCityController = TextEditingController();
  final TextEditingController _arrivalCityController = TextEditingController();
  
  // Filtered cities for autocomplete
  List<dynamic> _filteredDepartureCities = [];
  List<dynamic> _filteredArrivalCities = [];
  
  // Estimation data
  Map<String, dynamic>? _estimationData;
  bool _isCalculatingEstimation = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadInitialData();
    
    // Add listeners for text changes to show autocomplete
    _departureCityController.addListener(_onDepartureCityChanged);
    _arrivalCityController.addListener(_onArrivalCityChanged);
  }
  
  @override
  void dispose() {
    _departureCityController.dispose();
    _arrivalCityController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      setState(() {
        _selectedDepartureCity = widget.initialData!['departureCity'];
        _selectedArrivalCity = widget.initialData!['arrivalCity'];
        if (_selectedDepartureCity != null) {
          _departureCityController.text = _selectedDepartureCity!['name'] ?? '';
        }
        if (_selectedArrivalCity != null) {
          _arrivalCityController.text = _selectedArrivalCity!['name'] ?? '';
        }
      });
    }
  }
  
  void _onDepartureCityChanged() {
    final query = _departureCityController.text.toLowerCase();
    setState(() {
      _filteredDepartureCities = _cities.where((city) {
        final cityName = (city['name'] ?? '').toString().toLowerCase();
        return cityName.contains(query) && query.isNotEmpty;
      }).toList();
    });
  }
  
  void _onArrivalCityChanged() {
    final query = _arrivalCityController.text.toLowerCase();
    setState(() {
      _filteredArrivalCities = _cities.where((city) {
        final cityName = (city['name'] ?? '').toString().toLowerCase();
        return cityName.contains(query) && query.isNotEmpty;
      }).toList();
    });
  }
  
  Future<void> _calculateEstimation() async {
    if (_selectedDepartureCity == null || _selectedArrivalCity == null) {
      return;
    }
    
    setState(() {
      _isCalculatingEstimation = true;
    });
    
    try {
      // Use OSRM API for route calculation
      final departureLat = _selectedDepartureCity!['latitude'];
      final departureLng = _selectedDepartureCity!['longitude'];
      final arrivalLat = _selectedArrivalCity!['latitude'];
      final arrivalLng = _selectedArrivalCity!['longitude'];
      
      final url = 'https://router.project-osrm.org/route/v1/driving/$departureLng,$departureLat;$arrivalLng,$arrivalLat?overview=false&alternatives=false&steps=false';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final distance = route['distance'] / 1000; // Convert to km
          final duration = route['duration'] / 60; // Convert to minutes
          
          setState(() {
            _estimationData = {
              'distance': distance,
              'duration': duration,
              'departureCity': _selectedDepartureCity!['name'],
              'arrivalCity': _selectedArrivalCity!['name'],
            };
          });
        }
      }
    } catch (e) {
      print('Error calculating estimation: $e');
    } finally {
      setState(() {
        _isCalculatingEstimation = false;
      });
    }
  }

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);
    try {
      final citiesData = await ApiService.instance.getCities();
      setState(() {
        _cities = citiesData;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load cities: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    print('DEBUG: _nextStep called');
    
    // Prevent multiple calls
    if (_isLoading) {
      print('DEBUG: Already processing, ignoring call');
      return;
    }
    
    setState(() {
      _departureCityError = null;
      _arrivalCityError = null;
    });

    // Find cities by name
    final departureCityName = _departureCityController.text.trim();
    final arrivalCityName = _arrivalCityController.text.trim();
    
    print('DEBUG: departureCityName: $departureCityName');
    print('DEBUG: arrivalCityName: $arrivalCityName');
    print('DEBUG: _cities length: ${_cities.length}');
    
    if (departureCityName.isEmpty) {
      setState(() => _departureCityError = 'Please enter a departure city');
      return;
    }
    if (arrivalCityName.isEmpty) {
      setState(() => _arrivalCityError = 'Please enter an arrival city');
      return;
    }
    
    // Find the city objects
    final departureCity = _cities.firstWhere(
      (city) => (city['name'] ?? '').toString().toLowerCase() == departureCityName.toLowerCase(),
      orElse: () => null,
    );
    final arrivalCity = _cities.firstWhere(
      (city) => (city['name'] ?? '').toString().toLowerCase() == arrivalCityName.toLowerCase(),
      orElse: () => null,
    );
    
    print('DEBUG: departureCity found: ${departureCity != null}');
    print('DEBUG: arrivalCity found: ${arrivalCity != null}');
    
    if (departureCity == null) {
      setState(() => _departureCityError = 'City not found. Please check the spelling.');
      return;
    }
    if (arrivalCity == null) {
      setState(() => _arrivalCityError = 'City not found. Please check the spelling.');
      return;
    }
    if (departureCity == arrivalCity) {
      setState(() => _arrivalCityError = 'Arrival city must be different from departure city');
      return;
    }

    print('DEBUG: Calling widget.onNext');
    // Call onNext - the TripCreationWizard will handle navigation
    widget.onNext({
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'estimationData': _estimationData,
    });
    print('DEBUG: widget.onNext called successfully');
    
    // Set loading state to prevent multiple calls
    setState(() {
      _isLoading = true;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Route'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Your Route',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your departure and arrival cities',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  
                      // Departure City
                      const Text(
                        'Departure City',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          TextFormField(
                            controller: _departureCityController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              errorText: _departureCityError,
                              prefixIcon: const Icon(Icons.location_on),
                              hintText: 'Type departure city name',
                              suffixIcon: _departureCityController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _departureCityController.clear();
                                        setState(() {
                                          _selectedDepartureCity = null;
                                          _departureCityError = null;
                                          _filteredDepartureCities = [];
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _departureCityError = null;
                              });
                            },
                          ),
                          // Autocomplete suggestions
                          if (_filteredDepartureCities.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredDepartureCities.length > 5 ? 5 : _filteredDepartureCities.length,
                                itemBuilder: (context, index) {
                                  final city = _filteredDepartureCities[index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_on, size: 16),
                                    title: Text(
                                      city['name'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _departureCityController.text = city['name'] ?? '';
                                        _selectedDepartureCity = city;
                                        _filteredDepartureCities = [];
                                        _departureCityError = null;
                                      });
                                      _calculateEstimation();
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                  
                  const SizedBox(height: 24),
                  
                      // Arrival City
                      const Text(
                        'Arrival City',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          TextFormField(
                            controller: _arrivalCityController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              errorText: _arrivalCityError,
                              prefixIcon: const Icon(Icons.location_on),
                              hintText: 'Type arrival city name',
                              suffixIcon: _arrivalCityController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _arrivalCityController.clear();
                                        setState(() {
                                          _selectedArrivalCity = null;
                                          _arrivalCityError = null;
                                          _filteredArrivalCities = [];
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _arrivalCityError = null;
                              });
                            },
                          ),
                          // Autocomplete suggestions
                          if (_filteredArrivalCities.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredArrivalCities.length > 5 ? 5 : _filteredArrivalCities.length,
                                itemBuilder: (context, index) {
                                  final city = _filteredArrivalCities[index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_on, size: 16),
                                    title: Text(
                                      city['name'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _arrivalCityController.text = city['name'] ?? '';
                                        _selectedArrivalCity = city;
                                        _filteredArrivalCities = [];
                                        _arrivalCityError = null;
                                      });
                                      _calculateEstimation();
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                  
                  const SizedBox(height: 24),
                  
                  // Route Estimation Section
                  if (_estimationData != null || _isCalculatingEstimation)
                    Container(
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
                              Icon(Icons.route, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Route Estimation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isCalculatingEstimation)
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Calculating route...'),
                              ],
                            )
                          else if (_estimationData != null)
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Distance',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          '${_estimationData!['distance'].toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Duration',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          '${_estimationData!['duration'].toStringAsFixed(0)} min',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_estimationData!['departureCity']} → ${_estimationData!['arrivalCity']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Processing...'),
                            ],
                          )
                        : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
