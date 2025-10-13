# Architecture Logique - Application Covoiturage

## Vue d'ensemble
L'architecture logique décrit l'organisation des composants logiciels et leurs interactions dans l'application de covoiturage.

## Diagramme d'Architecture Logique

```mermaid
graph TB
    subgraph "Couche Présentation"
        A[Application Flutter Mobile]
        B[Admin Dashboard Web]
        C[API REST Endpoints]
    end
    
    subgraph "Couche Contrôleurs"
        D[AuthController]
        E[TripController]
        F[BookingController]
        G[UserController]
        H[AdminController]
        I[NotificationController]
    end
    
    subgraph "Couche Services"
        J[UserService]
        K[TripService]
        L[BookingService]
        M[NotificationService]
        N[PaymentService]
        O[RatingService]
    end
    
    subgraph "Couche Sécurité"
        P[JWT Authentication]
        Q[Spring Security]
        R[Role-based Access Control]
    end
    
    subgraph "Couche Persistance"
        S[UserRepository]
        T[TripRepository]
        U[BookingRepository]
        V[NotificationRepository]
    end
    
    subgraph "Couche Données"
        W[(Base de données MySQL)]
        X[WebSocket Real-time]
    end
    
    subgraph "Entités Métier"
        Y[User/Admin/Conducteur/Passager]
        Z[Voyage/Trip]
        AA[Reservation/Booking]
        BB[Notification]
        CC[Paiement]
        DD[Avis/Rating]
    end
    
    A --> C
    B --> C
    C --> D
    C --> E
    C --> F
    C --> G
    C --> H
    C --> I
    
    D --> J
    E --> K
    F --> L
    G --> J
    H --> J
    I --> M
    
    J --> S
    K --> T
    L --> U
    M --> V
    
    S --> W
    T --> W
    U --> W
    V --> W
    
    P --> Q
    Q --> R
    
    S --> Y
    T --> Z
    U --> AA
    V --> BB
    
    X --> M
```

## Description des Couches

### 1. Couche Présentation
- **Application Flutter** : Interface mobile pour conducteurs et passagers
- **Admin Dashboard** : Interface web pour l'administration
- **API REST** : Points d'entrée pour toutes les requêtes

### 2. Couche Contrôleurs
- **AuthController** : Gestion de l'authentification
- **TripController** : Gestion des trajets
- **BookingController** : Gestion des réservations
- **UserController** : Gestion des utilisateurs
- **AdminController** : Fonctionnalités d'administration
- **NotificationController** : Gestion des notifications

### 3. Couche Services
- **UserService** : Logique métier des utilisateurs
- **TripService** : Logique métier des trajets
- **BookingService** : Logique métier des réservations
- **NotificationService** : Gestion des notifications
- **PaymentService** : Gestion des paiements
- **RatingService** : Système d'évaluation

### 4. Couche Sécurité
- **JWT Authentication** : Authentification par tokens
- **Spring Security** : Framework de sécurité
- **Role-based Access Control** : Contrôle d'accès par rôles

### 5. Couche Persistance
- **Repositories** : Accès aux données via JPA
- **Base de données MySQL** : Stockage persistant
- **WebSocket** : Communication temps réel

### 6. Entités Métier
- **User/Admin/Conducteur/Passager** : Types d'utilisateurs
- **Voyage/Trip** : Trajets proposés
- **Reservation/Booking** : Réservations
- **Notification** : Notifications système
- **Paiement** : Transactions financières
- **Avis/Rating** : Système d'évaluation










