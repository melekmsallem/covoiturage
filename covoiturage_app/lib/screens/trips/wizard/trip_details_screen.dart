import 'package:flutter/material.dart';
import '../../../services/trip_creation_service.dart';
import 'pickup_mode_screen.dart';
import 'trip_options_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onNext;

  const TripDetailsScreen({
    super.key,
    this.initialData,
    required this.onNext,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _priceController = TextEditingController();
  final _maxSeatsController = TextEditingController();
  final _descriptionController = TextEditingController();

  final TripCreationService _tripCreationService = TripCreationService();

  DateTime? _departureTime;
  DateTime? _arrivalTime;

  String? _priceError;
  String? _seatsError;
  String? _departureTimeError;
  String? _arrivalTimeError;
  double? _estimatedFuelCost;
  double? _maxRecommendedPrice;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: TripDetailsScreen initState called');
    _loadInitialData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _maxSeatsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      setState(() {
        _priceController.text = widget.initialData!['price']?.toString() ?? '';
        _maxSeatsController.text = widget.initialData!['maxSeats']?.toString() ?? '';
        _descriptionController.text = widget.initialData!['description'] ?? '';
        _departureTime = widget.initialData!['departureTime'];
        _arrivalTime = widget.initialData!['arrivalTime'];
      });
    }
  }

  Future<void> _nextStep() async {
    _validateForm();
    if (_priceError == null && _seatsError == null &&
        _departureTimeError == null && _arrivalTimeError == null &&
        _departureTime != null && _arrivalTime != null) {
      final nextData = {
        'price': double.tryParse(_priceController.text),
        'maxSeats': int.tryParse(_maxSeatsController.text),
        'description': _descriptionController.text,
        'departureTime': _departureTime,
        'arrivalTime': _arrivalTime,
      };

      if (_isValidating) return;
      setState(() {
        _isValidating = true;
      });

      final validationPayload = {
        'departureCity': widget.initialData?['departureCity']?['name'] ?? widget.initialData?['departureCity'] ?? '',
        'arrivalCity': widget.initialData?['arrivalCity']?['name'] ?? widget.initialData?['arrivalCity'] ?? '',
        'departureTime': _departureTime!.toIso8601String(),
        'arrivalTime': _arrivalTime!.toIso8601String(),
        'pricePerSeat': nextData['price'],
        'maxSeats': nextData['maxSeats'],
        'description': _descriptionController.text,
      };

      Map<String, dynamic> validationResponse = {};
      try {
        validationResponse = await _tripCreationService.validateTripCreation(validationPayload);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not validate trip price: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isValidating = false;
        });
        return;
      }

      final bool isValid = validationResponse['valid'] == true;
      final List<dynamic> errorsDynamic = validationResponse['errors'] as List<dynamic>? ?? [];
      final errors = errorsDynamic.map((e) => e.toString()).toList();
      final maxRecommended = (validationResponse['maxRecommendedPricePerSeat'] as num?)?.toDouble();
      final estimatedFuel = (validationResponse['estimatedFuelCost'] as num?)?.toDouble();

      setState(() {
        _maxRecommendedPrice = maxRecommended;
        _estimatedFuelCost = estimatedFuel;
      });

      if (!isValid || errors.isNotEmpty) {
        String? priceError;
        String? seatsError;
        String? timeError;
        for (final error in errors) {
          final lower = error.toLowerCase();
          if (lower.contains('price per seat')) {
            priceError ??= error;
          } else if (lower.contains('seat')) {
            seatsError ??= error;
          } else if (lower.contains('departure') || lower.contains('arrival')) {
            timeError ??= error;
          }
        }

        setState(() {
          if (priceError != null) {
            final suggestion = _maxRecommendedPrice != null
                ? '\nFuel estimate: ${_estimatedFuelCost?.toStringAsFixed(2) ?? '-'} TND • Suggested max ${_maxRecommendedPrice!.toStringAsFixed(0)} coins'
                : '';
            _priceError = '$priceError$suggestion';
          }
          if (seatsError != null) _seatsError = seatsError;
          if (timeError != null) {
            _departureTimeError ??= timeError;
            _arrivalTimeError ??= timeError;
          }
        });

        setState(() {
          _isValidating = false;
        });
        return;
      }

      if (_maxRecommendedPrice != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estimated fuel: ${_estimatedFuelCost?.toStringAsFixed(2) ?? '-'} TND • Recommended max price: ${_maxRecommendedPrice?.toStringAsFixed(0)} coins',
            ),
            backgroundColor: Colors.blueGrey.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      nextData['estimatedFuelCost'] = _estimatedFuelCost;
      nextData['maxRecommendedPricePerSeat'] = _maxRecommendedPrice;

      setState(() {
        _isValidating = false;
      });

      widget.onNext(nextData);
      // Also navigate forward directly to avoid context issues upstream
      try {
        final merged = {
          ...?widget.initialData,
          ...nextData,
        };
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PickupModeScreen(
              initialData: merged,
              onNext: (pickupData) {
                try {
                  final merged2 = {...merged, ...pickupData};
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripOptionsScreen(
                        initialData: merged2,
                        onCreateTrip: (_) {},
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint('Navigation to TripOptions failed: $e');
                }
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('Navigation to PickupMode failed: $e');
      }
    }
  }

  void _validateForm() {
    setState(() {
      _priceError = null;
      _seatsError = null;
      _departureTimeError = null;
      _arrivalTimeError = null;
    });

    // Validate price
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      setState(() => _priceError = 'Please enter a valid price');
    }

    // Validate seats
    final seats = int.tryParse(_maxSeatsController.text);
    if (seats == null || seats < 1 || seats > 8) {
      setState(() => _seatsError = 'Please enter a valid number of seats (1-8)');
    }

    // Validate departure time
    if (_departureTime == null) {
      setState(() => _departureTimeError = 'Please select departure time');
    } else if (_departureTime!.isBefore(DateTime.now())) {
      setState(() => _departureTimeError = 'Departure time must be in the future');
    }

    // Validate arrival time
    if (_arrivalTime == null) {
      setState(() => _arrivalTimeError = 'Please select arrival time');
    } else if (_departureTime != null && _arrivalTime!.isBefore(_departureTime!)) {
      setState(() => _arrivalTimeError = 'Arrival time must be after departure time');
    }
  }

  Widget _buildPriceInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price per Seat (coins)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            errorText: _priceError,
            errorMaxLines: 3,
            prefixIcon: Icon(Icons.monetization_on, color: Colors.amber.shade600),
            hintText: '10.0',
          ),
          onChanged: (value) {
            setState(() {
              _priceError = null;
              _maxRecommendedPrice = null;
              _estimatedFuelCost = null;
            });
          },
        ),
        if (_maxRecommendedPrice != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Suggested max: ${_maxRecommendedPrice!.toStringAsFixed(0)} coins • Fuel est. ${_estimatedFuelCost?.toStringAsFixed(2) ?? '-'} TND',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.shade600,
              ),
              softWrap: true,
              maxLines: 2,
            ),
          ),
      ],
    );
  }

  Widget _buildSeatInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Max Seats',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _maxSeatsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            errorText: _seatsError,
            prefixIcon: const Icon(Icons.people_alt_outlined),
            hintText: '4',
          ),
          onChanged: (value) {
            if (_seatsError != null) {
              setState(() => _seatsError = null);
            }
          },
        ),
      ],
    );
  }

  Future<void> _selectDepartureTime() async {
    final now = DateTime.now();
    final initialDate = _departureTime ?? now.add(const Duration(hours: 1));
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now.add(const Duration(hours: 1)) : initialDate,
      firstDate: now,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (time != null) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        // Ensure the selected time is in the future
        if (selectedDateTime.isAfter(now)) {
          setState(() {
            _departureTime = selectedDateTime;
            _departureTimeError = null;
            // Reset arrival time if it's before the new departure time
            if (_arrivalTime != null && _arrivalTime!.isBefore(selectedDateTime)) {
              _arrivalTime = null;
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a future time for departure'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectArrivalTime() async {
    final now = DateTime.now();
    final minDate = _departureTime ?? now.add(const Duration(hours: 1));
    final initialDate = _arrivalTime ?? minDate.add(const Duration(hours: 2));
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (time != null) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        // Ensure arrival time is after departure time
        if (_departureTime != null && selectedDateTime.isAfter(_departureTime!)) {
          setState(() {
            _arrivalTime = selectedDateTime;
            _arrivalTimeError = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arrival time must be after departure time'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: TripDetailsScreen build method called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Details',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the time, price, and other details for your trip',
                    style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Route Summary Card
            if (widget.initialData != null && 
                widget.initialData!['departureCity'] != null && 
                widget.initialData!['arrivalCity'] != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.route, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Route',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.initialData!['departureCity']['name']} → ${widget.initialData!['arrivalCity']['name']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Time Selection Section
            Container(
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
                      Icon(Icons.access_time, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Trip Schedule',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Departure Time
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _departureTimeError != null ? Colors.red : Colors.grey.shade300),
                    ),
                    child: InkWell(
                      onTap: _selectDepartureTime,
                      child: Row(
                        children: [
                          Icon(Icons.flight_takeoff, color: Colors.blue.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Departure Time',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _departureTime != null
                                      ? '${_departureTime!.day}/${_departureTime!.month}/${_departureTime!.year} at ${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Tap to select departure time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _departureTime != null ? Colors.black : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                  if (_departureTimeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8),
                      child: Text(
                        _departureTimeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Arrival Time
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _arrivalTimeError != null ? Colors.red : Colors.grey.shade300),
                    ),
                    child: InkWell(
                      onTap: _selectArrivalTime,
                      child: Row(
                        children: [
                          Icon(Icons.flight_land, color: Colors.green.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Arrival Time',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _arrivalTime != null
                                      ? '${_arrivalTime!.day}/${_arrivalTime!.month}/${_arrivalTime!.year} at ${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Tap to select arrival time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _arrivalTime != null ? Colors.black : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                  if (_arrivalTimeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8),
                      child: Text(
                        _arrivalTimeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Price and Seats Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.purple.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Trip Pricing',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 360;
                      final priceField = _buildPriceInputField();
                      final seatsField = _buildSeatInputField();

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            priceField,
                            const SizedBox(height: 16),
                            seatsField,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: priceField),
                          const SizedBox(width: 16),
                          Expanded(child: seatsField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Additional Description Section (Compact)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_add, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Additional Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2, // Reduced from 3 to 2 lines
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Add any additional details about your trip...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Continue Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isValidating ? null : () => _nextStep(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isValidating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
