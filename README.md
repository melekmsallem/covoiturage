# Covoiturage Final - Carpooling Application

A comprehensive Spring Boot carpooling application with JWT-based authentication system.

## 🚀 Current Version: v1.0.0 (Sprint 1 Complete)

### ✅ Sprint 1: Authentication System (COMPLETED)

**Features Implemented:**
- JWT-based authentication with Spring Security
- User registration and login endpoints
- Role-based access control (Admin, Conducteur, Passager)
- Password encryption with BCrypt
- JWT token validation and filtering
- CORS configuration
- User entity with inheritance
- Complete authentication flow

**API Endpoints:**
- `POST /api/auth/signup` - User registration
- `POST /api/auth/signin` - User login
- `GET /api/users/**` - User management (protected)

## 🛠️ Technical Stack

- **Backend:** Spring Boot 3.5.5
- **Security:** Spring Security 6 + JWT
- **Database:** MySQL
- **Build Tool:** Gradle
- **Java Version:** 17
- **Frontend:** Flutter (Mobile App)

## 📋 Sprint Planning

### Sprint 2: Core Carpooling Features (PLANNED)
- Trip creation and management
- Search and filter trips
- Booking system
- Driver and passenger matching
- Trip status management
- Basic notifications

### Sprint 3: Advanced Features (PLANNED)
- Real-time notifications
- Payment integration
- Rating and review system
- Trip history and analytics
- Advanced search filters
- Mobile app integration

### Sprint 4: Admin Dashboard & Analytics (PLANNED)
- Admin dashboard
- User management
- Trip analytics
- System monitoring
- Report generation

## 🚀 Getting Started

### Prerequisites
- Java 17+
- MySQL 8.0+
- Gradle 7.0+

### Installation

1. Clone the repository:
```bash
git clone <your-github-repo-url>
cd covoiturage_final
```

2. Configure database in `src/main/resources/application.properties`

3. Run the application:
```bash
./gradlew bootRun
```

4. The API will be available at `http://localhost:8080`

## 📱 Mobile App

The project includes a Flutter mobile application in the `covoiturage_app/` directory.

## 🔐 Authentication

The application uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## 📊 Project Structure

```
src/main/java/esprit/pfe/covoiturage_final/
├── config/          # Security configuration
├── controllers/     # REST controllers
├── dto/            # Data transfer objects
├── entities/       # JPA entities
├── repositories/   # Data repositories
├── security/       # JWT and security components
└── services/       # Business logic
```

## 🏷️ Version Control

- **Current Version:** v1.0.0
- **Git Flow:** Feature branches with main/develop
- **Semantic Versioning:** MAJOR.MINOR.PATCH

## 📝 License

This project is part of a PFE (Projet de Fin d'Études) at ESPRIT.

## 👥 Contributors

- [Your Name] - Initial work

---

**Next Sprint:** Core Carpooling Features (v1.1.0)
