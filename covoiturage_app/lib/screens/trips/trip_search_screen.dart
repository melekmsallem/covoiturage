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
      final cities = await _api.getCities();
      if (!mounted) return;
      setState(() {
        _allCities = cities.cast<Map<String, dynamic>>();
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
      final req = <String, dynamic>{
        'departureCity': _departureController.text.trim(),
        'arrivalCity': _arrivalController.text.trim(),
        if (_dateController.text.isNotEmpty) 'date': _dateController.text.trim(),
      };
      final res = await _tripService.searchTrips(req, page: 0, size: 10);
      if (!mounted) return;
      setState(() => _results = res);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Search Trips')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                  controller: _departureController,
                  decoration: const InputDecoration(
                labelText: 'Departure city',
                prefixIcon: Icon(Icons.trip_origin),
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
            const SizedBox(height: 12),
            TextField(
              controller: _arrivalController,
                decoration: const InputDecoration(
                labelText: 'Arrival city',
                prefixIcon: Icon(Icons.flag),
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
            const SizedBox(height: 12),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date (optional)',
                prefixIcon: Icon(Icons.calendar_today),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingCities || _searching ? null : _runSearch,
                icon: const Icon(Icons.search),
                label: Text(_searching ? 'Searching...' : 'Search'),
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
    final items = (data['data'] as List?) ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('No trips found'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = items[index] as Map<String, dynamic>;
        final dep = t['departureCity'] ?? 'Unknown';
        final arr = t['arrivalCity'] ?? 'Unknown';
        final time = t['departureTime']?.toString() ?? '';
        final price = t['pricePerSeat']?.toString() ?? '';
        return ListTile(
          leading: const Icon(Icons.directions_car),
          title: Text('$dep → $arr'),
          subtitle: Text(time),
          trailing: Text('$price TND'),
          onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
                builder: (context) => TripBookingScreen(trip: t),
              ),
            );
          },
        );
      },
    );
  }
}