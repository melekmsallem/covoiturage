import 'package:flutter/material.dart';
import '../../services/trip_service.dart';
import '../../widgets/payment_button.dart';
import '../../services/payment_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final TripService _tripService = TripService();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> bookings = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadMyBookings();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      final response = await _tripService.getMyBookings(page: 0, size: 10);
      setState(() {
        bookings = response['data'] as List<dynamic>;
        currentPage = response['page'] ?? 0;
        totalPages = response['totalPages'] ?? 1;
        isLoading = false;
      });
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
      final response = await _tripService.getMyBookings(page: currentPage + 1, size: 10);
      setState(() {
        bookings.addAll(response['data'] as List<dynamic>);
        currentPage = response['page'] ?? currentPage;
        totalPages = response['totalPages'] ?? totalPages;
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
    final tripId = trip['id'] as int? ?? 0;
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
                Text(
                  'Booking Confirmation',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                          '${totalPrice.toStringAsFixed(2)} TND',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Rating button for completed trips
                    if (status == 'COMPLETED')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/rating',
                              arguments: {
                                'trip': trip,
                                'userToRate': trip['driver'] ?? {},
                                'ratingType': 'driver',
                              },
                            );
                          },
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Noter le conducteur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
                
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
                
                // Payment Button for confirmed bookings
                if (status.toUpperCase() == 'CONFIRMED') ...[
                  PaymentButton(
                    reservationId: id,
                    amount: totalPrice,
                    tripInfo: '${departureCity.isNotEmpty ? departureCity : 'Unknown'} → ${arrivalCity.isNotEmpty ? arrivalCity : 'Unknown'}',
                    driverName: 'Driver', // We don't have driver name in this context
                    bookingStatus: status,
                    onPaymentCompleted: () {
                      _loadMyBookings(); // Refresh the list after payment
                    },
                  ),
                  const SizedBox(height: 12),
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
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }
}