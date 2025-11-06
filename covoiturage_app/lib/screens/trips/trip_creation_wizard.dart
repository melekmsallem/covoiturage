import 'package:flutter/material.dart';
import 'wizard/route_selection_screen.dart';
import 'wizard/trip_details_screen.dart';
import 'wizard/pickup_mode_screen.dart';
import 'wizard/trip_options_screen.dart';

class TripCreationWizard extends StatefulWidget {
  const TripCreationWizard({super.key});

  @override
  State<TripCreationWizard> createState() => _TripCreationWizardState();
}

class _TripCreationWizardState extends State<TripCreationWizard> {
  bool _isAdvancing = false;
  @override
  void initState() {
    super.initState();
    // Navigate to the first step after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToRouteSelection();
    });
  }

  void _navigateToRouteSelection() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteSelectionScreen(
            onNext: (data) {
              Navigator.pop(context); // Close the route selection screen
              // Defer navigation to the next frame to avoid transient blank screen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _navigateToTripDetails(data);
                }
              });
            },
          ),
        ),
      ).then((result) {
        // If the route selection was dismissed (via X), close the wizard
        if (!mounted) return;
        if (result == null || result == false) {
          Navigator.of(context).pop(false);
        }
      });
    }
  }

  void _navigateToTripDetails(Map<String, dynamic> routeData) {
    print('DEBUG: _navigateToTripDetails called with data: $routeData');
    if (mounted) {
      print('DEBUG: Navigating to TripDetailsScreen');
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailsScreen(
              initialData: routeData,
              onNext: (tripData) {
                print('DEBUG: TripDetailsScreen onNext called with: $tripData');
                if (_isAdvancing) {
                  print('DEBUG: Ignoring duplicate onNext (already advancing)');
                  return;
                }
                _isAdvancing = true;
                final merged = {...routeData, ...tripData};
                // Try immediate push first
                try {
                  print('DEBUG: Pushing PickupModeScreen (immediate)...');
                  Navigator.of(this.context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => PickupModeScreen(
                            initialData: merged,
                            onNext: (pickupData) {
                              // Defer next navigation as well
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                print('DEBUG: Proceeding to TripOptionsScreen...');
                                _navigateToTripOptions({...merged, ...pickupData});
                              });
                            },
                          ),
                        ),
                      )
                      .then((_) {
                        // Allow future advances if user backs out
                        _isAdvancing = false;
                      });
                  print('DEBUG: PickupModeScreen push initiated (immediate)');
                } catch (e) {
                  print('ERROR: Immediate push failed, will retry post-frame: $e');
                  // Fallback: Defer and navigate using the wizard's context
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    print('DEBUG: Pushing PickupModeScreen (post-frame)...');
                    try {
                      Navigator.of(this.context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => PickupModeScreen(
                                initialData: merged,
                                onNext: (pickupData) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    print('DEBUG: Proceeding to TripOptionsScreen...');
                                    _navigateToTripOptions({...merged, ...pickupData});
                                  });
                                },
                              ),
                            ),
                          )
                          .then((_) {
                            _isAdvancing = false;
                          });
                      print('DEBUG: PickupModeScreen push initiated (post-frame)');
                    } catch (e2) {
                      _isAdvancing = false;
                      print('ERROR: Failed to push PickupModeScreen (post-frame): $e2');
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigation error. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
                }
              },
            ),
          ),
        );
        print('DEBUG: Navigation completed successfully');
      } catch (e) {
        print('DEBUG: Navigation error: $e');
      }
    } else {
      print('DEBUG: Widget not mounted, cannot navigate');
    }
  }

  void _navigateToPickupMode(Map<String, dynamic> data) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PickupModeScreen(
            initialData: data,
            onNext: (pickupData) {
              Navigator.pop(context); // Close the pickup mode screen
              _navigateToTripOptions({...data, ...pickupData});
            },
          ),
        ),
      );
    }
  }

  void _navigateToTripOptions(Map<String, dynamic> data) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripOptionsScreen(
            initialData: data,
            onCreateTrip: (optionsData) {
              // Trip creation is handled in TripOptionsScreen
              // The screen will close itself when trip is created
            },
          ),
        ),
      ).then((result) {
        // Handle the result when TripOptionsScreen closes
        if (mounted && result != null) {
          // Bubble up created trip payload to the dashboard
          Navigator.of(context).pop(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _SimpleTripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onNext;

  const _SimpleTripDetailsScreen({
    this.initialData,
    required this.onNext,
  });

  @override
  State<_SimpleTripDetailsScreen> createState() => _SimpleTripDetailsScreenState();
}

class _SimpleTripDetailsScreenState extends State<_SimpleTripDetailsScreen> {
  final _priceController = TextEditingController();
  final _maxSeatsController = TextEditingController(text: '4');
  final _descriptionController = TextEditingController();
  
  DateTime? _departureTime;
  DateTime? _arrivalTime;

  @override
  void initState() {
    super.initState();
    print('DEBUG: _SimpleTripDetailsScreen initState called');
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
        _priceController.text = widget.initialData!['price']?.toString() ?? '10';
        _maxSeatsController.text = widget.initialData!['maxSeats']?.toString() ?? '4';
        _descriptionController.text = widget.initialData!['description'] ?? '';
        _departureTime = widget.initialData!['departureTime'];
        _arrivalTime = widget.initialData!['arrivalTime'];
      });
    }
  }

  Future<void> _selectDepartureTime() async {
    final now = DateTime.now();
    final initialDate = _departureTime ?? now.add(const Duration(hours: 1));
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
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
          });
        } else {
          // Show error message
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
    final initialDate = _arrivalTime ?? now.add(const Duration(hours: 3));
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
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
        
        // Ensure the selected time is in the future and after departure time
        if (selectedDateTime.isAfter(now) && 
            (_departureTime == null || selectedDateTime.isAfter(_departureTime!))) {
          setState(() {
            _arrivalTime = selectedDateTime;
          });
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a future time for arrival that is after departure time'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: _SimpleTripDetailsScreen build method called');
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
            const Text(
              'Trip Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('From: ${widget.initialData?['departureCity']?['name'] ?? 'Unknown'}'),
            Text('To: ${widget.initialData?['arrivalCity']?['name'] ?? 'Unknown'}'),
            const SizedBox(height: 24),
            
            // Price input
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price per seat (coins)',
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.amber.shade600),
                    const SizedBox(width: 8),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Max seats input
            TextFormField(
              controller: _maxSeatsController,
              decoration: InputDecoration(
                labelText: 'Maximum seats',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Description input
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Departure time
            InkWell(
              onTap: _selectDepartureTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 12),
                    Text(
                      _departureTime != null
                          ? 'Departure: ${_departureTime!.day}/${_departureTime!.month}/${_departureTime!.year} at ${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select departure time',
                      style: TextStyle(
                        color: _departureTime != null ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Arrival time
            InkWell(
              onTap: _selectArrivalTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 12),
                    Text(
                      _arrivalTime != null
                          ? 'Arrival: ${_arrivalTime!.day}/${_arrivalTime!.month}/${_arrivalTime!.year} at ${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select arrival time',
                      style: TextStyle(
                        color: _arrivalTime != null ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print('DEBUG: Simple screen continue button pressed');
                  final price = double.tryParse(_priceController.text) ?? 10.0;
                  final maxSeats = int.tryParse(_maxSeatsController.text) ?? 4;
                  final description = _descriptionController.text;
                  
                  // Ensure departure time is in the future (at least 1 hour from now)
                  final now = DateTime.now();
                  final departureTime = _departureTime ?? now.add(const Duration(hours: 1));
                  final arrivalTime = _arrivalTime ?? now.add(const Duration(hours: 3));
                  
                  // Double-check that departure time is in the future
                  if (departureTime.isBefore(now)) {
                    print('DEBUG: Departure time is in the past, adjusting to future');
                    final adjustedDepartureTime = now.add(const Duration(hours: 1));
                    final adjustedArrivalTime = now.add(const Duration(hours: 3));
                    
                    widget.onNext({
                      'price': price,
                      'maxSeats': maxSeats,
                      'description': description,
                      'departureTime': adjustedDepartureTime,
                      'arrivalTime': adjustedArrivalTime,
                    });
                    return;
                  }
                  
                  widget.onNext({
                    'price': price,
                    'maxSeats': maxSeats,
                    'description': description,
                    'departureTime': departureTime,
                    'arrivalTime': arrivalTime,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
