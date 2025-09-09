# Covoiturage Final - Sprint Planning

## Project Overview
A Spring Boot carpooling application with JWT-based authentication system.

## Sprint 1: Authentication System ✅ (COMPLETED)

### Features Implemented:
- ✅ JWT-based authentication with Spring Security
- ✅ User registration and login endpoints
- ✅ Role-based access control (Admin, Conducteur, Passager)
- ✅ Password encryption with BCrypt
- ✅ JWT token validation and filtering
- ✅ CORS configuration
- ✅ User entity with inheritance (Admin, Conducteur, Passager)
- ✅ Complete authentication flow

### API Endpoints:
- `POST /api/auth/signup` - User registration
- `POST /api/auth/signin` - User login
- `GET /api/users/**` - User management (protected)

### Technical Stack:
- Spring Boot 3.5.5
- Spring Security 6
- JWT (jjwt 0.11.5)
- MySQL Database
- Lombok for boilerplate reduction

## Sprint 2: Core Carpooling Features (PLANNED)

### Planned Features:
- [ ] Trip creation and management
- [ ] Search and filter trips
- [ ] Booking system
- [ ] Driver and passenger matching
- [ ] Trip status management
- [ ] Basic notifications

### API Endpoints (Planned):
- `POST /api/trips` - Create trip
- `GET /api/trips` - Search trips
- `POST /api/bookings` - Book a trip
- `GET /api/bookings` - Get user bookings
- `PUT /api/trips/{id}/status` - Update trip status

## Sprint 3: Advanced Features (PLANNED)

### Planned Features:
- [ ] Real-time notifications
- [ ] Payment integration
- [ ] Rating and review system
- [ ] Trip history and analytics
- [ ] Advanced search filters
- [ ] Mobile app integration

## Sprint 4: Admin Dashboard & Analytics (PLANNED)

### Planned Features:
- [ ] Admin dashboard
- [ ] User management
- [ ] Trip analytics
- [ ] System monitoring
- [ ] Report generation

## Version Control Strategy

### Git Flow:
- `main` branch: Production-ready code
- `develop` branch: Integration branch for features
- `feature/*` branches: Individual feature development
- `release/*` branches: Release preparation
- `hotfix/*` branches: Critical bug fixes

### Versioning:
- Semantic versioning (MAJOR.MINOR.PATCH)
- Current version: 0.0.1-SNAPSHOT
- Sprint 1 completion: v1.0.0
- Sprint 2 completion: v1.1.0
- Sprint 3 completion: v1.2.0
- Sprint 4 completion: v2.0.0

## Development Guidelines

### Code Standards:
- Follow Spring Boot best practices
- Use Lombok for reducing boilerplate
- Implement proper error handling
- Write comprehensive tests
- Document API endpoints with Swagger/OpenAPI

### Database:
- Use MySQL for production
- Implement proper migrations
- Follow naming conventions
- Add proper indexes for performance

### Security:
- JWT tokens with proper expiration
- Password encryption
- Input validation
- CORS configuration
- Role-based access control
