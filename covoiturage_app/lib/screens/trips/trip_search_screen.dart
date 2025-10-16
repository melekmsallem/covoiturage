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
      // Simulate API call with mock cities data
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
      
      if (!mounted) return;
      setState(() {
        _allCities = mockCities;
        _loadingCities = false;
      });
    } catch (_) {
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
    setState(() => _searching = true);
    try {
      // Simulate API call with mock search results
      await Future.delayed(const Duration(seconds: 2));
      
      // Create mock search results
      final mockResults = {
        'content': [
          {
            'id': 1,
            'driverName': 'Ahmed Ben Ali',
            'driverPhone': '+216 98 123 456',
            'departureCity': _departureController.text.trim(),
            'arrivalCity': _arrivalController.text.trim(),
            'departureTime': '2025-10-17T08:00:00',
            'arrivalTime': '2025-10-17T10:30:00',
            'price': 5.0,
            'availableSeats': 3,
            'totalSeats': 4,
            'vehicleModel': 'Peugeot 208',
            'vehicleColor': 'Blanc',
            'vehiclePlate': '123 TU 456',
            'rating': 4.5,
            'description': 'Trajet confortable avec climatisation',
          },
          {
            'id': 2,
            'driverName': 'Fatma Khelil',
            'driverPhone': '+216 95 789 012',
            'departureCity': _departureController.text.trim(),
            'arrivalCity': _arrivalController.text.trim(),
            'departureTime': '2025-10-17T14:00:00',
            'arrivalTime': '2025-10-17T16:30:00',
            'price': 4.5,
            'availableSeats': 2,
            'totalSeats': 3,
            'vehicleModel': 'Renault Clio',
            'vehicleColor': 'Rouge',
            'vehiclePlate': '456 SF 789',
            'rating': 4.8,
            'description': 'Conductrice expérimentée, trajet direct',
          },
        ],
        'totalElements': 2,
        'totalPages': 1,
        'size': 10,
        'number': 0,
      };
      
      if (!mounted) return;
      setState(() => _results = mockResults);
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
    final items = (data['data'] as List?) ?? [];
    
    if (items.isEmpty) {
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
              'No trips found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final t = items[index] as Map<String, dynamic>;
        final dep = t['departureCity'] ?? 'Unknown';
        final arr = t['arrivalCity'] ?? 'Unknown';
        final time = t['departureTime']?.toString() ?? '';
        final price = t['pricePerSeat']?.toString() ?? '';
        final availableSeats = t['availableSeats'] ?? 0;
        
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
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$price TND',
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
}