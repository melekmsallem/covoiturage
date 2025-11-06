import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/trip_service.dart';
import 'trip_booking_screen.dart';

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _dateController = TextEditingController();

  final _tripService = TripService();
  final _api = ApiService.instance;

  List<Map<String, dynamic>> _allCities = [];
  List<Map<String, dynamic>> _depSuggestions = [];
  List<Map<String, dynamic>> _arrSuggestions = [];

  Timer? _depDebounce;
  Timer? _arrDebounce;

  bool _loadingCities = true;
  bool _searching = false;
  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _departureController.addListener(_onDepartureChanged);
    _arrivalController.addListener(_onArrivalChanged);
  }

  Future<void> _loadCities() async {
    try {
      print('DEBUG: Loading cities from API...');
      
      // Load cities from real API
      final citiesResponse = await ApiService.instance.getDynamic('/cities');
      print('DEBUG: Cities response: $citiesResponse');
      
      List<dynamic> citiesList = [];
      if (citiesResponse is List) {
        citiesList = citiesResponse;
      } else if (citiesResponse is Map && citiesResponse.containsKey('data')) {
        citiesList = citiesResponse['data'] as List<dynamic>? ?? [];
      }
      
      print('DEBUG: Loaded ${citiesList.length} cities');
      
      if (!mounted) return;
      setState(() {
        _allCities = citiesList.cast<Map<String, dynamic>>();
        _loadingCities = false;
      });
    } catch (e) {
      print('DEBUG: Error loading cities: $e');
      if (!mounted) return;
      setState(() => _loadingCities = false);
    }
  }

  void _onDepartureChanged() {
    _depDebounce?.cancel();
    _depDebounce = Timer(const Duration(milliseconds: 300), () {
      final q = _departureController.text.trim().toLowerCase();
      setState(() {
        _depSuggestions = q.isEmpty
            ? []
            : _allCities
                .where((c) => (c['name'] ?? '').toString().toLowerCase().contains(q))
                .take(8)
                .cast<Map<String, dynamic>>()
                .toList();
      });
    });
  }

  void _onArrivalChanged() {
    _arrDebounce?.cancel();
    _arrDebounce = Timer(const Duration(milliseconds: 300), () {
      final q = _arrivalController.text.trim().toLowerCase();
    setState(() {
        _arrSuggestions = q.isEmpty
            ? []
            : _allCities
                .where((c) => (c['name'] ?? '').toString().toLowerCase().contains(q))
                .take(8)
                .cast<Map<String, dynamic>>()
                .toList();
      });
    });
  }

  Future<void> _runSearch() async {
    if (_departureController.text.trim().isEmpty || _arrivalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both departure and arrival cities')),
      );
      return;
    }

    setState(() => _searching = true);
    try {
      // Use real API call to search for trips
      final searchParams = {
        'departureCity': _departureController.text.trim(),
        'arrivalCity': _arrivalController.text.trim(),
        'departureDate': _dateController.text.trim().isNotEmpty ? _dateController.text.trim() : null,
        'size': 20,
        'page': 0,
      };
      
      print('DEBUG: Searching with params: $searchParams');
      final results = await _tripService.searchTrips(searchParams);
      print('DEBUG: Search results type: ${results.runtimeType}');
      print('DEBUG: Search results: $results');
      
      // Check if results is null or empty
      if (results == null) {
        print('DEBUG: Results is null');
      } else if (results is Map) {
        print('DEBUG: Results is Map with keys: ${results.keys}');
      } else if (results is List) {
        print('DEBUG: Results is List with ${results.length} items');
      }
      
      if (!mounted) return;
      
      // If results are empty or null, show a message but don't crash
      if (results == null || 
          (results is Map && results.isEmpty) ||
          (results is Map && !results.containsKey('data') && !results.containsKey('content')) ||
          (results is List && results.isEmpty)) {
        print('DEBUG: No results found, showing empty state');
        setState(() => _results = {'data': []});
      } else {
        setState(() => _results = results);
      }
    } catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
        );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _depDebounce?.cancel();
    _arrDebounce?.cancel();
    _departureController.dispose();
    _arrivalController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Trips'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search form with better styling
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _departureController,
                      decoration: InputDecoration(
                        labelText: 'Departure city',
                        hintText: 'Where are you starting from?',
                        prefixIcon: Icon(Icons.trip_origin, color: colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                      ),
                    ),
                    if (_depSuggestions.isNotEmpty)
                      _SuggestionList(
                        suggestions: _depSuggestions,
                        onTap: (name) {
                          _departureController.text = name;
                          setState(() => _depSuggestions = []);
                        },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _arrivalController,
                      decoration: InputDecoration(
                        labelText: 'Arrival city',
                        hintText: 'Where are you going?',
                        prefixIcon: Icon(Icons.flag, color: colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                      ),
                    ),
                    if (_arrSuggestions.isNotEmpty)
                      _SuggestionList(
                        suggestions: _arrSuggestions,
                        onTap: (name) {
                          _arrivalController.text = name;
                          setState(() => _arrSuggestions = []);
                        },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date (optional)',
                        hintText: 'Select departure date',
                        prefixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _dateController.text = picked.toIso8601String().split('T').first;
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _loadingCities || _searching ? null : _runSearch,
                        icon: _searching 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.search, color: colorScheme.onPrimary),
                        label: Text(
                          _searching ? 'Searching...' : 'Search Trips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _results == null
                  ? const SizedBox.shrink()
                  : _SearchResults(data: _results!),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final void Function(String) onTap;
  const _SuggestionList({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final name = (suggestions[index]['name'] ?? '').toString();
          final codePostal = (suggestions[index]['codePostal'] ?? '').toString();
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on, size: 20, color: Colors.blue),
            title: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: codePostal.isNotEmpty ? Text(codePostal, style: const TextStyle(fontSize: 12)) : null,
            onTap: () => onTap(name),
          );
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SearchResults({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    print('DEBUG: SearchResults data structure: $data');
    
    // Try different possible data structures
    List<dynamic> items = [];
    if (data.containsKey('data')) {
      items = (data['data'] as List?) ?? [];
    } else if (data.containsKey('content')) {
      items = (data['content'] as List?) ?? [];
    } else {
      items = [];
    }
    
    print('DEBUG: Extracted items: $items');
    
    // Filter to show only future trips
    final now = DateTime.now();
    final futureItems = items.where((trip) {
      try {
        final departureTimeString = trip['departureTime'] as String? ?? '';
        if (departureTimeString.isEmpty) {
          return false; // Skip trips without departure time
        }
        
        final departureTime = DateTime.parse(departureTimeString);
        final isFuture = departureTime.isAfter(now);
        
        if (!isFuture) {
          print('DEBUG: Filtering out past trip: ${trip['departureTime']}');
        }
        
        return isFuture;
      } catch (e) {
        print('DEBUG: Error parsing trip date: $e for trip: $trip');
        return false; // Skip trips with invalid dates
      }
    }).toList();
    
    print('DEBUG: Future trips count: ${futureItems.length} out of ${items.length} total');
    
    if (futureItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming trips found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No trips are available for the selected route\nTry different dates or destinations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      itemCount: futureItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final t = futureItems[index] as Map<String, dynamic>;
        final dep = t['departureCity'] ?? 'Unknown';
        final arr = t['arrivalCity'] ?? 'Unknown';
        final time = t['departureTime']?.toString() ?? '';
        final price = t['pricePerSeat']?.toString() ?? '';
        final availableSeats = t['availableSeats'] ?? 0;
        
        // Extract driver information
        final driver = t['driver'] as Map<String, dynamic>?;
        final driverName = driver != null 
            ? '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}'.trim()
            : 'Unknown Driver';
        final driverRating = (driver?['rating'] as num?)?.toDouble() ?? 0.0;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripBookingScreen(trip: t),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dep → $arr',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$availableSeats seats available',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Driver name and rating
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driverName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Add verification badge if driver is verified
                            if (driver != null && (driver['isVerified'] == true || driver['isVerified'] == 'true')) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                            ],
                            if (driverRating > 0) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                driverRating.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.amber[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildPickupModeInfo(t),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$price coins',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'per seat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickupModeInfo(Map<String, dynamic> trip) {
    final pickupMode = trip['pickupMode'] as String?;
    final hasPickupPoints = trip['pickupPoints'] != null && 
                           (trip['pickupPoints'] as List).isNotEmpty;
    
    if (pickupMode == 'DESIGNATED_POINT' && hasPickupPoints) {
      return Row(
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            'Designated pickup points',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (pickupMode == 'INDIVIDUAL_PICKUP') {
      return Row(
        children: [
          Icon(
            Icons.my_location,
            size: 14,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            'Individual pickup (share location)',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // Default or unknown pickup mode
      return Row(
        children: [
          Icon(
            Icons.help_outline,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            'Pickup details available in trip',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }
  }
}