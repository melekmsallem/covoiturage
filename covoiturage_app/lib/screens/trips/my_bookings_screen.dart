import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/trip_service.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/report_dialog.dart';
import 'passenger_pickup_screen.dart';
import '../chat/chat_screen.dart';
import '../chat/group_chat_screen.dart';
import 'realtime_tracking_screen.dart';
import 'dart:async';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final TripService _tripService = TripService();
  final ApiService _apiService = ApiService.instance;
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> bookings = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 1;
  Set<int> _ratedTrips = {}; // Track trips that have been rated
  StreamSubscription? _websocketSubscription;

  @override
  void initState() {
    super.initState();
    _loadMyBookings();
    _scrollController.addListener(_onScroll);
    _setupTripCompletionListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _websocketSubscription?.cancel();
    super.dispose();
  }

  void _setupTripCompletionListener() async {
    // Connect to websocket if not already connected
    if (!WebSocketService.instance.isConnected) {
      await WebSocketService.instance.connect();
    }

    // Listen for trip completion messages via websocket - but don't show popup
    _websocketSubscription = WebSocketService.instance.messageStream.listen((message) {
      if (message['type'] == 'trip-completed' || message['type'] == 'TRIP_COMPLETED') {
        final tripId = message['tripId'] as int?;
        if (tripId != null) {
          // Only refresh bookings when trip completes - no popup
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _loadMyBookings(); // Refresh bookings to get updated status
            }
          });
        }
      }
    });
  }

  Future<bool> _checkIfAlreadyRated(int tripId) async {
    // Use the backend's canRateTrip endpoint for accurate check
    try {
      final canRate = await _apiService.canRateTrip(tripId);
      return !canRate; // If can't rate, then already rated
    } catch (e) {
      print('Error checking if already rated: $e');
      // If check fails, allow rating attempt (backend will handle duplicate)
      return false;
    }
  }

  Future<void> _loadRatingStatus() async {
    try {
      // Check all completed trips to see if they've been rated
      // Note: We're lenient here - if check fails, we allow rating attempts
      // Backend will handle duplicate checks when submitting
      for (var booking in bookings) {
        final trip = booking['trip'] as Map<String, dynamic>? ?? {};
        final tripId = (trip['id'] as num?)?.toInt();
        final status = trip['status'] as String? ?? '';
        
        if (tripId != null && status == 'COMPLETED') {
          try {
            // Only mark as rated if we're certain (both checks agree)
            bool canRate = await _apiService.canRateTrip(tripId);
            final hasRated = await _checkIfAlreadyRated(tripId);
            // Only mark as rated if both checks indicate already rated
            // This prevents false positives from incorrect backend logic
            if (!canRate && hasRated) {
              _ratedTrips.add(tripId);
            }
          } catch (e) {
            // If check fails, don't mark as rated - allow rating attempt
            print('Error checking rating status for trip $tripId: $e');
          }
        }
      }
      
      if (mounted) {
        setState(() {
          // Trigger rebuild to update button visibility
        });
      }
    } catch (e) {
      print('Error loading rating status: $e');
    }
  }


  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
        !isLoadingMore &&
        currentPage < totalPages - 1) {
      _loadMoreBookings();
    }
  }

  Future<void> _loadMyBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentPage = 0;
    });

    try {
      print('DEBUG: Loading my bookings...');
      // Use real API call to get passenger bookings
      final bookingsData = await _tripService.getMyBookings();
      print('DEBUG: Received bookings: $bookingsData');
      
      List<dynamic> bookingsList = [];
      if (bookingsData.containsKey('data')) {
        bookingsList = bookingsData['data'] as List<dynamic>? ?? [];
      } else if (bookingsData.containsKey('content')) {
        bookingsList = bookingsData['content'] as List<dynamic>? ?? [];
      }
      
      print('DEBUG: Processed bookings count: ${bookingsList.length}');
      
      setState(() {
        bookings = bookingsList;
        currentPage = 0;
        totalPages = 1;
        isLoading = false;
      });
      
      // Load rating status for completed trips
      await _loadRatingStatus();
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreBookings() async {
    if (isLoadingMore) return;
    
    setState(() {
      isLoadingMore = true;
    });

    try {
      // Simulate loading more data (no more data available)
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyBookings,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : _buildBookingsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMyBookings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookings for your trips will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyBookings,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == bookings.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final id = booking['id'] as int? ?? 0;
    final trip = booking['trip'] as Map<String, dynamic>? ?? {};
    final passenger = booking['passenger'] as Map<String, dynamic>? ?? {};
    
    // Extract passenger information
    final passengerUsername = passenger['username'] as String? ?? 'Unknown';
    final passengerFirstName = passenger['firstName'] as String? ?? '';
    final passengerLastName = passenger['lastName'] as String? ?? '';
    final passengerName = passengerFirstName.isNotEmpty && passengerLastName.isNotEmpty 
        ? '$passengerFirstName $passengerLastName' 
        : passengerUsername;
    
    // Extract trip information
    final description = trip['description'] as String? ?? '';
    final departureTime = trip['departureTime'] as String? ?? '';
    final arrivalTime = trip['arrivalTime'] as String? ?? '';
    final departureCity = trip['departureCity'] as String? ?? '';
    final arrivalCity = trip['arrivalCity'] as String? ?? '';
    
    // Extract booking information
    final numberOfSeats = booking['numberOfSeats'] as int? ?? 1;
    final totalPrice = booking['totalPrice'] as double? ?? 0.0;
    final status = booking['status'] as String? ?? '';
    final reservationDate = booking['reservationDate'] as String? ?? '';
    final notes = booking['notes'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Booking Confirmation',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Passenger info
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        passengerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Trip route information
                Row(
                  children: [
                    Icon(Icons.route, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description.isNotEmpty ? description : 'Trip Details',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            departureTime.isNotEmpty 
                                ? 'Departure: ${departureCity.isNotEmpty ? departureCity : 'Unknown City'} - ${_formatDateTime(departureTime)}'
                                : 'Departure: Not specified',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            arrivalTime.isNotEmpty 
                                ? 'Arrival: ${arrivalCity.isNotEmpty ? arrivalCity : 'Unknown City'} - ${_formatDateTime(arrivalTime)}'
                                : 'Arrival: Not specified',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Trip and booking details
                Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Information',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Reserved: ${_formatDateTime(reservationDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Seats and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$numberOfSeats seat${numberOfSeats > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.payments, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${totalPrice.toStringAsFixed(2)} coins',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Rating button for completed trips
                if (status == 'COMPLETED') ...[
                  Builder(
                    builder: (context) {
                      final tripId = (trip['id'] as num?)?.toInt();
                      final hasRated = tripId != null && _ratedTrips.contains(tripId);
                      
                      if (hasRated) {
                        // Show message if already rated
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Déjà noté',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Show rating button if not rated
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final tripId = (trip['id'] as num?)?.toInt();
                              if (tripId == null) return;
                              
                              // Safely cast driver data
                              Map<String, dynamic>? driverToRate;
                              final driver = trip['driver'];
                              if (driver is Map) {
                                driverToRate = Map<String, dynamic>.from(driver);
                              }
                              
                              // Navigate to rating screen - backend will handle duplicate check
                              final result = await Navigator.pushNamed(
                                context,
                                '/rating',
                                arguments: {
                                  'trip': Map<String, dynamic>.from(trip),
                                  'userToRate': driverToRate ?? <String, dynamic>{},
                                  'ratingType': 'driver',
                                },
                              );
                              
                              // If rating was submitted successfully, mark as rated
                              if (result == true) {
                                _ratedTrips.add(tripId);
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            },
                            icon: const Icon(Icons.star, size: 18),
                            label: const Text('Noter le conducteur'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
                
                // Notes
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notes,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Coin payment info for confirmed bookings
                if (status.toUpperCase() == 'CONFIRMED') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment Status:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Paid with Coins',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount:'),
                            Text(
                              '${totalPrice.toStringAsFixed(2)} coins',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (status.toUpperCase() == 'PAID') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Completed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Pickup point button for confirmed bookings with individual pickup
                if (status.toUpperCase() == 'CONFIRMED' && trip['pickupMode'] == 'INDIVIDUAL_PICKUP') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPickupPointScreen(booking, trip),
                      icon: const Icon(Icons.location_on, size: 18),
                      label: Text(booking['passengerPickupAddress'] != null ? 'Update Pickup Point' : 'Set Pickup Point'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Track Driver button for active trips
                if (trip['status'] == 'IN_PROGRESS' || trip['status'] == 'ACTIVE') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startTrackingDriver(booking, trip),
                      icon: const Icon(Icons.my_location, size: 20),
                      label: const Text('Track Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Chat and contact buttons for confirmed bookings
                if (status.toUpperCase() == 'CONFIRMED') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openChatScreen(booking, trip),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openGroupChatScreen(trip),
                          icon: const Icon(Icons.group, size: 18),
                          label: const Text('Group'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callDriver(booking, trip),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Report button (for all statuses except cancelled)
                if (status.toUpperCase() != 'CANCELLED') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showReportDialog(booking, trip),
                        icon: Icon(Icons.flag, size: 16, color: Colors.red[600]),
                        label: Text(
                          'Report Driver',
                          style: TextStyle(color: Colors.red[600], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Action buttons
                if (status.toUpperCase() == 'PENDING') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelBooking(id),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Annuler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (status.toUpperCase() != 'CONFIRMED') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Status: ${status.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(Map<String, dynamic> booking, Map<String, dynamic> trip) {
    // Driver info can be in booking['driver'] OR trip['driver']
    final bookingDriver = booking['driver'] as Map<String, dynamic>?;
    final tripDriver = trip['driver'] as Map<String, dynamic>?;
    final driver = bookingDriver ?? tripDriver;
    
    if (driver == null || driver.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final bookingId = (booking['id'] as num?)?.toInt();
    final tripId = (trip['id'] as num?)?.toInt();
    
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportedUser: driver,
        bookingId: bookingId,
        tripId: tripId,
        userRole: 'driver',
      ),
    ).then((success) {
      if (success == true) {
        // Refresh bookings if report was successful
        _loadMyBookings();
      }
    });
  }

  void _cancelBooking(int bookingId) async {
    try {
      await _tripService.cancelBooking(bookingId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking #$bookingId cancelled'),
          backgroundColor: Colors.red[600],
        ),
      );
      _loadMyBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _openPickupPointScreen(Map<String, dynamic> booking, Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerPickupScreen(
          booking: booking,
          trip: trip,
        ),
      ),
    ).then((_) {
      // Refresh bookings when returning from pickup screen
      _loadMyBookings();
    });
  }

  void _openChatScreen(Map<String, dynamic> booking, Map<String, dynamic> trip) {
    // Get driver information from booking (now available in BookingResponse)
    final driver = booking['driver'] as Map<String, dynamic>? ?? {};
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          booking: booking,
          trip: trip,
          otherUser: driver,
        ),
      ),
    );
  }

  void _openGroupChatScreen(Map<String, dynamic> trip) {
    // Get current user info from AuthProvider or pass a simple user object
    final currentUser = {
      'id': 20, // This should be dynamically retrieved from AuthProvider
      'firstName': 'Current',
      'lastName': 'User',
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          trip: trip,
          currentUser: currentUser,
        ),
      ),
    );
  }

  Future<void> _callDriver(Map<String, dynamic> booking, Map<String, dynamic> trip) async {
    final driver = booking['driver'] as Map<String, dynamic>? ?? {};
    final phoneNumber = driver['phoneNumber'] as String?;
    
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create tel: URL
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhoneNumber);
      
      // Check if device can make phone calls
      if (await canLaunchUrl(phoneUri)) {
        // Launch phone app directly
        await launchUrl(phoneUri);
      } else {
        // Fallback: show dialog with copy option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Call Driver'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Driver: ${driver['firstName']} ${driver['lastName']}'),
                const SizedBox(height: 8),
                Text('Phone: $phoneNumber'),
                const SizedBox(height: 16),
                const Text(
                  'Unable to launch phone app. You can copy this number and call manually.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: phoneNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number copied to clipboard'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Copy Number'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PAID':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  // Start tracking driver for active trips
  Future<void> _startTrackingDriver(Map<String, dynamic> booking, Map<String, dynamic> trip) async {
    final tripId = trip['id'] as int? ?? 0;
    
    // Driver info can be in booking['driver'] OR trip['driver']
    final bookingDriver = booking['driver'] as Map<String, dynamic>?;
    final tripDriver = trip['driver'] as Map<String, dynamic>?;
    final driver = bookingDriver ?? tripDriver ?? <String, dynamic>{};
    final driverId = driver['id'] as int?;
    
    print('DEBUG: Booking driver data: $bookingDriver');
    print('DEBUG: Trip driver data: $tripDriver');
    print('DEBUG: Driver ID: $driverId');
    
    // Get driver info for the participants list
    List<Map<String, dynamic>> participants = [];
    if (driverId != null) {
      participants = [
        {
          'id': driverId,
          'firstName': driver['firstName'] ?? 'Driver',
          'lastName': driver['lastName'] ?? '',
        }
      ];
      print('DEBUG: Created participants: $participants');
    } else {
      print('DEBUG: No driver ID found in booking or trip data!');
    }
    
    // Get pickup point from booking
    Map<String, dynamic>? pickupPoint;
    if (booking['passengerPickupLatitude'] != null && booking['passengerPickupLongitude'] != null) {
      pickupPoint = {
        'latitude': booking['passengerPickupLatitude'] as double,
        'longitude': booking['passengerPickupLongitude'] as double,
        'address': booking['passengerPickupAddress'] as String? ?? 'Pickup Point',
      };
    }
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealtimeTrackingScreen(
          tripId: tripId,
          userRole: 'PASSENGER',
          participants: participants,
          pickupPoint: pickupPoint,
        ),
      ),
    );
  }
}