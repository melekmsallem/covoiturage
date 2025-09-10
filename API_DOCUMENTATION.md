# Covoiturage API Documentation - Sprint 2

## Overview
This document describes the REST API endpoints for the carpooling application's core features implemented in Sprint 2.

## Base URL
```
http://localhost:8080/api
```

## Authentication
Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### 1. Trip Management

#### Create Trip
```http
POST /trips
Authorization: Bearer <token>
Content-Type: application/json

{
  "departureTime": "2024-01-15T10:00:00",
  "arrivalTime": "2024-01-15T12:00:00",
  "pricePerSeat": 25.50,
  "maxSeats": 4,
  "description": "Trip from Tunis to Sfax",
  "startPoint": {
    "latitude": 36.8065,
    "longitude": 10.1815,
    "address": "Tunis, Tunisia"
  },
  "endPoint": {
    "latitude": 34.7406,
    "longitude": 10.7603,
    "address": "Sfax, Tunisia"
  },
  "intermediatePoints": [
    {
      "latitude": 35.8256,
      "longitude": 10.6411,
      "address": "Sousse, Tunisia"
    }
  ],
  "optionIds": [1, 2],
  "villeIds": [1, 2, 3]
}
```

#### Get Trip by ID
```http
GET /trips/{tripId}
Authorization: Bearer <token>
```

#### Get My Trips (Driver)
```http
GET /trips/my-trips
Authorization: Bearer <token>
```

#### Search Trips
```http
POST /trips/search
Content-Type: application/json

{
  "departureTime": "2024-01-15T08:00:00",
  "maxDepartureTime": "2024-01-15T18:00:00",
  "startLatitude": 36.8065,
  "startLongitude": 10.1815,
  "endLatitude": 34.7406,
  "endLongitude": 10.7603,
  "minPrice": 20.0,
  "maxPrice": 50.0,
  "numberOfSeats": 2,
  "searchRadiusKm": 15.0,
  "startCity": "Tunis",
  "endCity": "Sfax"
}
```

#### Get Available Trips
```http
GET /trips/available
```

#### Update Trip
```http
PUT /trips/{tripId}
Authorization: Bearer <token>
Content-Type: application/json

{
  // Same structure as CreateTripRequest
}
```

#### Cancel Trip
```http
POST /trips/{tripId}/cancel
Authorization: Bearer <token>
```

#### Delete Trip
```http
DELETE /trips/{tripId}
Authorization: Bearer <token>
```

#### Start Trip
```http
POST /trips/{tripId}/start
Authorization: Bearer <token>
```

#### Complete Trip
```http
POST /trips/{tripId}/complete
Authorization: Bearer <token>
```

#### Get Upcoming Trips
```http
GET /trips/upcoming
Authorization: Bearer <token>
```

#### Get Completed Trips
```http
GET /trips/completed
Authorization: Bearer <token>
```

### 2. Booking Management

#### Create Booking
```http
POST /bookings
Authorization: Bearer <token>
Content-Type: application/json

{
  "tripId": 1,
  "numberOfSeats": 2,
  "notes": "Please pick me up at the main entrance"
}
```

#### Get Booking by ID
```http
GET /bookings/{bookingId}
Authorization: Bearer <token>
```

#### Get My Bookings (Passenger)
```http
GET /bookings/my-bookings
Authorization: Bearer <token>
```

#### Get Bookings by Trip
```http
GET /bookings/trip/{tripId}
Authorization: Bearer <token>
```

#### Confirm Booking (Driver)
```http
POST /bookings/{bookingId}/confirm
Authorization: Bearer <token>
```

#### Cancel Booking
```http
POST /bookings/{bookingId}/cancel
Authorization: Bearer <token>
```

### 3. Options Management

#### Get All Options
```http
GET /options
```

#### Get Option by ID
```http
GET /options/{id}
```

#### Search Options
```http
GET /options/search?name=wifi
```

#### Get Options by Price Range
```http
GET /options/price-range?minPrice=5.0&maxPrice=20.0
```

### 4. Cities Management

#### Get All Cities
```http
GET /cities
```

#### Get City by ID
```http
GET /cities/{id}
```

#### Search Cities
```http
GET /cities/search?name=tunis
```

#### Get City by Name
```http
GET /cities/by-name/{name}
```

#### Get Cities by Country
```http
GET /cities/by-country?country=Tunisia
```

#### Get Cities by Postal Code
```http
GET /cities/by-postal-code?postalCode=1000
```

### 5. Test Endpoints

#### Health Check
```http
GET /test/health
```

#### Sprint 2 Status
```http
GET /test/sprint2
```

## Response Formats

### Success Response
```json
{
  "id": 1,
  "departureTime": "2024-01-15T10:00:00",
  "arrivalTime": "2024-01-15T12:00:00",
  "pricePerSeat": 25.50,
  "availableSeats": 2,
  "maxSeats": 4,
  "description": "Trip from Tunis to Sfax",
  "status": "PLANNED",
  "createdAt": "2024-01-10T15:30:00",
  "updatedAt": "2024-01-10T15:30:00",
  "driver": {
    "id": 1,
    "username": "driver1",
    "firstName": "Ahmed",
    "lastName": "Ben Ali",
    "phoneNumber": "+21612345678",
    "vehicleModel": "Toyota Corolla",
    "vehicleColor": "White",
    "vehiclePlate": "123TU456",
    "rating": 4.5,
    "totalTrips": 25,
    "isVerified": true
  },
  "points": [
    {
      "id": 1,
      "latitude": 36.8065,
      "longitude": 10.1815,
      "address": "Tunis, Tunisia",
      "pointType": "START"
    },
    {
      "id": 2,
      "latitude": 34.7406,
      "longitude": 10.7603,
      "address": "Sfax, Tunisia",
      "pointType": "END"
    }
  ],
  "options": [
    {
      "id": 1,
      "name": "WiFi",
      "description": "Free WiFi available",
      "price": 5.0
    }
  ],
  "cities": [
    {
      "id": 1,
      "name": "Tunis",
      "codePostal": "1000",
      "pays": "Tunisia"
    }
  ]
}
```

### Error Response
```json
{
  "error": "Trip not found"
}
```

## Trip Status Flow
1. **PLANNED** - Trip is created and available for booking
2. **ACTIVE** - Trip has started
3. **COMPLETED** - Trip has finished
4. **CANCELLED** - Trip was cancelled

## Booking Status Flow
1. **PENDING** - Booking request submitted
2. **CONFIRMED** - Driver confirmed the booking
3. **CANCELLED** - Booking was cancelled
4. **COMPLETED** - Trip completed successfully

## Validation Rules

### Trip Creation
- Departure time must be in the future
- Price per seat must be greater than 0
- Maximum seats must be between 1 and 8
- Start and end points are required
- GPS coordinates must be valid

### Booking Creation
- Trip must be in PLANNED status
- Number of seats must be available
- Number of seats must be between 1 and 8

## Error Codes
- 400 Bad Request - Invalid input data
- 401 Unauthorized - Missing or invalid token
- 403 Forbidden - Insufficient permissions
- 404 Not Found - Resource not found
- 500 Internal Server Error - Server error

## Testing
Use the test endpoints to verify the API is working:
```bash
curl http://localhost:8080/api/test/health
curl http://localhost:8080/api/test/sprint2
```
