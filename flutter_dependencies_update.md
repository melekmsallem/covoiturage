# Flutter Dependencies for Covoiturage Mobile App

## Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP requests to Spring Boot API
  http: ^1.1.0
  
  # State management
  provider: ^6.0.5
  
  # Local storage for JWT tokens
  shared_preferences: ^2.2.2
  
  # Real-time WebSocket communication
  web_socket_channel: ^2.4.0
  
  # Location services
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Maps integration
  google_maps_flutter: ^2.5.0
  
  # Push notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  
  # UI components
  cupertino_icons: ^1.0.2
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  
  # Date/time handling
  intl: ^0.18.1
  
  # Form validation
  form_field_validator: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

## Run this command in your Flutter project directory:
```bash
flutter pub get
```


