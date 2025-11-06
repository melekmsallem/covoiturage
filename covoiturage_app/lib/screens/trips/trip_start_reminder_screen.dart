import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/trip_service.dart';

class TripStartReminderScreen extends StatefulWidget {
  final int tripId;

  const TripStartReminderScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<TripStartReminderScreen> createState() => _TripStartReminderScreenState();
}

class _TripStartReminderScreenState extends State<TripStartReminderScreen> {
  final ApiService _apiService = ApiService.instance;
  final TripService _tripService = TripService();
  
  Map<String, dynamic>? _reminderData;
  bool _isLoading = true;
  bool _isStartingTrip = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTripReminderData();
  }

  Future<void> _loadTripReminderData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _apiService.get('/trip-reminder/${widget.tripId}');
      setState(() {
        _reminderData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startTrip() async {
    setState(() {
      _isStartingTrip = true;
    });

    try {
      await _tripService.startTrip(widget.tripId);
      
      if (mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isStartingTrip = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Starting Soon'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _reminderData == null
                  ? const Center(child: Text('No data available'))
                  : _buildReminderContent(colorScheme),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTripReminderData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderContent(ColorScheme colorScheme) {
    final String pickupMode = _reminderData!['pickupMode'] ?? 'DESIGNATED_POINT';
    final List<dynamic> pickupPoints = _reminderData!['pickupPoints'] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            color: Colors.orange.shade50,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 64,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Trip Starts in 1 Hour!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_reminderData!['departureCity']} → ${_reminderData!['arrivalCity']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Pickup Mode Info
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    pickupMode == 'DESIGNATED_POINT' ? Icons.location_on : Icons.my_location,
                    color: pickupMode == 'DESIGNATED_POINT' ? Colors.blue : Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupMode == 'DESIGNATED_POINT' ? 'Designated Pickup Points' : 'Individual Pickup Locations',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickupPoints.isEmpty
                              ? 'No pickup points set'
                              : '${pickupPoints.length} pickup location${pickupPoints.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
          
          // Pickup Points List
          if (pickupPoints.isNotEmpty) ...[
            Text(
              'Pickup Route',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...pickupPoints.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              return _buildPickupPointCard(point, index + 1, pickupPoints.length);
            }),
          ],
          
          const SizedBox(height: 32),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isStartingTrip ? null : _startTrip,
              icon: _isStartingTrip
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isStartingTrip ? 'Starting Trip...' : 'Start Trip',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Secondary Action
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Ready Yet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupPointCard(Map<String, dynamic> point, int number, int total) {
    final address = point['address'] ?? 'No address';
    final passengerName = point['passengerName'] as String?;
    final seats = point['seats'] as int?;
    final order = point['order'] as int?;
    final latitude = point['latitude'] as double?;
    final longitude = point['longitude'] as double?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Step Number Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  order?.toString() ?? number.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Point Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (passengerName != null) ...[
                    Text(
                      passengerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.blue.shade700),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (seats != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$seats seat${seats > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (latitude != null && longitude != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Arrow if not last
            if (number < total)
              Icon(Icons.arrow_downward, color: Colors.blue.shade300),
          ],
        ),
      ),
    );
  }
}

