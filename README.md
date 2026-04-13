# Bighustle (flutter_bighustle)

Bighustle is a Flutter app focused on driver community content, learning resources, licensing workflows, tickets, and account management. The project uses a feature-module layout with GetX for dependency injection, a centralized networking layer, and explicit route definitions for every screen.

## Overview
- App name: Bighustle
- Package name: flutter_bighustle
- Platforms: Android, iOS, Web, Desktop (Flutter)
- SDK: Dart ^3.10.1
- Version: 1.0.0+1

## Core Features
- Authentication flows with splash, login, signup, OTP verification, and password reset
- Home dashboard with community and teen driver content
- Learning center and video playback
- License management, alerts, and editing flows
- Ticket list, ticket details, and ticket notifications
- In-app notifications
- Profile management with personal info, password changes, and settings

## Modules And Screens
- Auth: Splash, Login, Signup, OTP Verify, Forget Password, Reset Password
- Home: Bottom Navigation, Home, Community, Teen Drivers, Teen Driver Posts, Add Teen Driver Experience, Learning Center, Learning Video
- License: License, License Alerts, Edit License Info
- Ticket: Ticket List, Ticket Details, Ticket Notifications, Plan Pricing Details
- Notifications: Notification List
- Profile: Profile, Personal Info, Edit Personal Info, Add License Info, Change Password, Notification Settings, Privacy Policy, Terms and Conditions

## Architecture
- Routing: `MaterialApp` with centralized `onGenerateRoute` and `AppRoutes`
- Modules: Feature-first layout under `lib/moduls/` with interface, implement, controller, model, and presentation layers
- Networking: `AppPigeon` wraps Dio, auth interceptor, refresh token flow, and Socket.IO
- Error handling: `BaseRepository` with `dartz` Either for failures
- Dependency injection: GetX `Get.put` via `externalServiceDI()` and `initServices()`

## Key Packages
- `get` for dependency injection and state
- `dio` for networking
- `socket_io_client` for realtime updates
- `flutter_secure_storage` for secure token storage
- `dartz` for functional error handling
- `image_picker` and `video_player` for media
- `path_provider` for filesystem paths

## Project Structure
```
lib/
  main.dart                         # App entry point and routing
  app/                              # App-level controllers and bootstrapping
  core/                             # Constants, DI, API helpers, services
  moduls/                           # Feature modules
    auth/                           # Auth interfaces, impls, controllers, UI
    home/                           # Home, community, teen driver, learning
    license/                        # License flows and alerts
    notification/                   # Notification data and UI
    profile/                        # Profile and settings
    ticket/                         # Ticket list/details and pricing
assets/
  images/                           # Image assets
  videos/                           # Video assets
```

## Configuration
- API base and socket URLs: `lib/core/constants/api_endpoints.dart`
- App routes: `lib/core/constants/app_routes.dart`
- Dependency injection: `lib/core/di/external_service_di.dart`, `lib/core/di/internal_service_di.dart`
- Assets: `pubspec.yaml`

## Getting Started
1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```
   test
Keep API keys, tokens, and production credentials out of the repo. Use secure storage and environment-specific configuration for sensitive values.
