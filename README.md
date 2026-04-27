# Krizot App

Krizot is a cross-platform Flutter application for shift managers and operations officers. It provides a desktop-optimized administrative scheduler with dynamic station management.

## Features

- 🔐 **Secure Authentication** — JWT-based login with secure token storage
- 🏗️ **Station Management** — Full CRUD for operational stations with desktop table and mobile card views
- 📅 **Schedule Management** — Weekly grid view with shift assignment
- 📊 **Dashboard** — Real-time stats and quick actions
- 📱 **Responsive Design** — Desktop (1280px+), Tablet (900px+), Mobile (<900px)

## Tech Stack

- **Framework**: Flutter 3+ (web, mobile, desktop)
- **State Management**: Riverpod
- **HTTP Client**: Dio with JWT interceptor
- **Routing**: go_router
- **Storage**: flutter_secure_storage
- **Design**: Material 3 + Inter font

## Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.0+
- Backend API running (see [krizot-backend](../krizot-backend))

### Installation

```bash
# Install dependencies
flutter pub get

# Run on web (development)
flutter run -d chrome

# Run on desktop
flutter run -d macos  # or windows/linux

# Build for web
flutter build web
```

### Configuration

The API base URL defaults to `http://localhost:3000/api`. Override via:

```bash
# Web
flutter run -d chrome --dart-define=KRIZOT_API_URL=https://your-api.com/api

# Build
flutter build web --dart-define=KRIZOT_API_URL=https://your-api.com/api
```

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # Root widget, routing, shell navigation
├── screens/
│   ├── login_screen.dart    # Authentication
│   ├── dashboard_screen.dart # Overview stats
│   └── stations_screen.dart  # Station CRUD
├── widgets/
│   ├── add_edit_station_modal.dart  # Station form modal
│   ├── station_card.dart            # Mobile card view
│   ├── status_chip.dart             # Status badge
│   ├── loading_shimmer.dart         # Loading placeholders
│   ├── empty_state.dart             # Empty list state
│   └── error_banner.dart            # Error display
├── providers/
│   ├── auth_provider.dart           # Auth state (Riverpod)
│   └── stations_provider.dart       # Stations state (Riverpod)
├── services/
│   ├── api_client.dart              # Dio HTTP client
│   ├── auth_service.dart            # Login/logout/session
│   └── stations_service.dart        # Stations CRUD API
├── models/
│   ├── user.dart                    # User model
│   └── station.dart                 # Station model
└── utils/
    ├── app_colors.dart              # Color palette
    ├── app_theme.dart               # Material theme
    ├── breakpoints.dart             # Responsive breakpoints
    ├── validators.dart              # Form validators
    └── constants.dart               # App constants
```

## Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## API Integration

The app connects to the Krizot backend REST API:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/login` | POST | Authenticate user |
| `/api/auth/logout` | POST | Logout |
| `/api/auth/me` | GET | Get current user |
| `/api/stations` | GET | List stations |
| `/api/stations` | POST | Create station |
| `/api/stations/:id` | PUT | Update station |
| `/api/stations/:id` | DELETE | Delete station |
| `/api/stations/stats` | GET | Station statistics |

## Design System

- **Primary**: Deep Navy `#1A2B4A`
- **Accent**: Electric Blue `#0D7CFF`
- **Success**: Teal Green `#00B087`
- **Warning**: Amber `#FFB020`
- **Danger**: Red `#E53E3E`
- **Font**: Inter (400, 500, 600, 700)
