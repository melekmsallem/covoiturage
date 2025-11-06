import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/trip_service.dart';

class RatingScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  final Map<String, dynamic> userToRate;
  final String ratingType; // 'driver' or 'passenger'
  final VoidCallback? onRatingComplete; // Callback when rating is submitted

  const RatingScreen({
    Key? key,
    required this.trip,
    required this.userToRate,
    required this.ratingType,
    this.onRatingComplete,
  }) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isLoading = false;
  final ApiService _apiService = ApiService.instance;
  Map<String, dynamic>? _fullTripDetails;
  Map<String, dynamic>? _fullUserDetails;

  @override
  void initState() {
    super.initState();
    _loadTripDetails().then((_) {
      _loadUserDetails(); // Load user details after trip details are loaded
    });
  }

  Future<void> _loadTripDetails() async {
    try {
      // Always reload trip details to ensure we have latest passenger/reservation data
      // This is especially important for completed trips where we need to rate passengers
      if (widget.trip['id'] != null) {
        final tripService = TripService();
        final fullDetails = await tripService.getTripDetails(widget.trip['id'] as int);
        debugPrint('DEBUG: Loaded trip details with passengers: ${fullDetails['passengers']?.length ?? 0}');
        debugPrint('DEBUG: Loaded trip details with reservations: ${fullDetails['reservations']?.length ?? 0}');
        setState(() {
          _fullTripDetails = fullDetails;
        });
      } else {
        setState(() {
          _fullTripDetails = widget.trip;
        });
      }
    } catch (e) {
      debugPrint('Error loading trip details for rating: $e');
      setState(() {
        _fullTripDetails = widget.trip; // Fallback to original
      });
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      // If userToRate has an ID, try to load full details from trip
      final userId = widget.userToRate['id'] ?? widget.userToRate['userId'];
      
      if (userId != null && _fullTripDetails != null) {
        // Try to get user details from trip participants first
        final participants = _fullTripDetails!['participants'] as List<dynamic>?;
        if (participants != null) {
          for (var participant in participants) {
            if (participant is Map && (participant['id'] == userId || participant['userId'] == userId)) {
              setState(() {
                _fullUserDetails = Map<String, dynamic>.from(participant);
              });
              return;
            }
          }
        }
        
        // Check passengers list
        final passengers = _fullTripDetails!['passengers'] as List<dynamic>?;
        if (passengers != null) {
          for (var passenger in passengers) {
            if (passenger is Map && (passenger['id'] == userId || passenger['userId'] == userId)) {
              setState(() {
                _fullUserDetails = Map<String, dynamic>.from(passenger);
              });
              return;
            }
          }
        }
        
        // Check reservations for passenger ID
        final reservations = _fullTripDetails!['reservations'] as List<dynamic>?;
        if (reservations != null) {
          for (var reservation in reservations) {
            if (reservation is Map) {
              final passengerId = reservation['passengerId'] ?? 
                                 reservation['passagerId'] ?? 
                                 reservation['passenger']?['id'] ?? 
                                 reservation['passager']?['id'];
              if (passengerId == userId) {
                final passenger = reservation['passenger'] ?? reservation['passager'];
                if (passenger is Map) {
                  setState(() {
                    _fullUserDetails = Map<String, dynamic>.from(passenger);
                  });
                  return;
                }
              }
            }
          }
        }
        
        // Check driver
        if (_fullTripDetails!['driver'] != null) {
          final driver = _fullTripDetails!['driver'] as Map<String, dynamic>;
          if (driver['id'] == userId || driver['userId'] == userId || driver['driverId'] == userId || driver['conducteurId'] == userId) {
            setState(() {
              _fullUserDetails = Map<String, dynamic>.from(driver);
            });
            return;
          }
        }
      }
      
      // If not found in trip or userToRate already has details, use what we have
      setState(() {
        _fullUserDetails = widget.userToRate;
      });
    } catch (e) {
      debugPrint('Error loading user details for rating: $e');
      setState(() {
        _fullUserDetails = widget.userToRate; // Fallback to original
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tripId = _fullTripDetails?['id'] ?? widget.trip['id'];
      if (tripId == null) {
        throw Exception('Trip ID is missing');
      }
      
      // Try to get user ID from loaded details first, then from widget, then from trip participants
      // Handle both int and String IDs
      dynamic targetUserId = _fullUserDetails?['id'] ?? 
                             _fullUserDetails?['userId'] ??
                             widget.userToRate['id'] ?? 
                             widget.userToRate['userId'];
      
      // If still null, try to find user from trip participants
      if (targetUserId == null && _fullTripDetails != null) {
        if (widget.ratingType == 'passenger') {
          // Find passenger from trip - check multiple possible locations
          final passengers = _fullTripDetails!['passengers'] as List<dynamic>?;
          if (passengers != null && passengers.isNotEmpty) {
            final firstPassenger = passengers.first;
            if (firstPassenger is Map) {
              targetUserId = firstPassenger['id'] ?? firstPassenger['userId'] ?? firstPassenger['passengerId'];
            }
          }
          
          // If still not found, check participants list
          if (targetUserId == null) {
            final participants = _fullTripDetails!['participants'] as List<dynamic>?;
            if (participants != null && participants.isNotEmpty) {
              final firstParticipant = participants.first;
              if (firstParticipant is Map) {
                targetUserId = firstParticipant['id'] ?? firstParticipant['userId'];
              }
            }
          }
          
          // If still not found, check reservations/bookings
          if (targetUserId == null) {
            final reservations = _fullTripDetails!['reservations'] as List<dynamic>?;
            if (reservations != null && reservations.isNotEmpty) {
              final firstReservation = reservations.first;
              if (firstReservation is Map) {
                targetUserId = firstReservation['passengerId'] ?? 
                              firstReservation['passagerId'] ??
                              firstReservation['passenger']?['id'] ??
                              firstReservation['passager']?['id'];
              }
            }
          }
        } else if (widget.ratingType == 'driver') {
          // Find driver from trip
          final driver = _fullTripDetails!['driver'] as Map<String, dynamic>?;
          if (driver != null) {
            targetUserId = driver['id'] ?? driver['userId'] ?? driver['driverId'] ?? driver['conducteurId'];
          }
        }
      }
      
      if (targetUserId == null) {
        throw Exception('User ID is missing. Cannot rate user.');
      }
      
      final ratingData = {
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
        'tripId': tripId,
        'targetUserId': targetUserId, // Pass the user being rated (passenger or driver)
        'ratingType': widget.ratingType,
      };

      await _apiService.createRating(ratingData);

      // Persist a local flag so passenger/driver popups don't reappear for this trip
      try {
        final prefs = await SharedPreferences.getInstance();
        final tripKey = widget.ratingType == 'driver' ? 'driver_rating_done_trip_${tripId}' : 'passenger_rating_done_trip_${tripId}';
        await prefs.setBool(tripKey, true);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis soumis avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Call callback if provided (for sequential rating flow)
        if (widget.onRatingComplete != null) {
          widget.onRatingComplete!();
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la soumission';
        String errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('already rated') || errorStr.contains('déjà noté')) {
          errorMessage = 'Vous avez déjà noté cet utilisateur pour ce voyage.';
        } else if (errorStr.contains('cannot rate') || errorStr.contains('ne peut pas noter')) {
          errorMessage = 'Vous ne pouvez pas noter ce voyage. Vous devez y avoir participé.';
        } else if (errorStr.contains('invalid rating')) {
          errorMessage = 'Note invalide. La note doit être entre 1 et 5.';
        } else if (errorStr.contains('comment') && errorStr.contains('exceed')) {
          errorMessage = 'Le commentaire ne peut pas dépasser 500 caractères.';
        } else {
          errorMessage = 'Erreur: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Noter ${widget.ratingType == 'driver' ? 'le conducteur' : 'le passager'}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voyage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_fullTripDetails?['departureCity'] ?? widget.trip['departureCity'] ?? 'N/A'} → ${_fullTripDetails?['arrivalCity'] ?? widget.trip['arrivalCity'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${_fullTripDetails?['departureTime'] ?? widget.trip['departureTime'] ?? 'N/A'} - ${_fullTripDetails?['arrivalTime'] ?? widget.trip['arrivalTime'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User to Rate
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ratingType == 'driver' ? 'Conducteur' : 'Passager',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              (_fullUserDetails?['firstName'] ?? widget.userToRate['firstName'] ?? 'U')?.toString().substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_fullUserDetails?['firstName'] ?? widget.userToRate['firstName'] ?? ''} ${_fullUserDetails?['lastName'] ?? widget.userToRate['lastName'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (widget.userToRate['rating'] != null)
                                  Row(
                                    children: [
                                      ...List.generate(5, (index) {
                                        return Icon(
                                          index < ((widget.userToRate['rating'] as num?)?.toDouble() ?? 0.0).round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        );
                                      }),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${widget.userToRate['rating']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Rating Selection
              Text(
                'Note *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _selectedRating ? Icons.star : Icons.star_border,
                        size: 40,
                        color: index < _selectedRating ? Colors.amber : Colors.grey[400],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _selectedRating == 0
                      ? 'Sélectionnez une note'
                      : _selectedRating == 1
                          ? 'Très mauvais'
                          : _selectedRating == 2
                              ? 'Mauvais'
                              : _selectedRating == 3
                                  ? 'Moyen'
                                  : _selectedRating == 4
                                      ? 'Bon'
                                      : 'Excellent',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedRating == 0 ? Colors.grey[600] : Colors.blue[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Comment
              Text(
                'Commentaire',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue[600]!),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Le commentaire ne peut pas dépasser 500 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Soumettre l\'avis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16), // Extra spacing at bottom
            ],
          ),
        ),
      ),
    );
  }
}
