# Krizot App

> **Shift Operations Platform** – A cross-platform Flutter application for shift managers and operations officers.

## Features

- 🗓️ **Dynamic Station Management** – Create, edit, and monitor operational stations
- 📅 **Shift Scheduling** – Weekly grid view with drag-and-drop assignment
- 📊 **Dashboard** – Real-time overview of staffing levels and critical alerts
- 🔐 **Secure Auth** – JWT-based authentication with secure token storage
- 📱 **Responsive** – Desktop-optimised with full mobile support

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3+ |
| State | Riverpod 2 |
| Navigation | GoRouter |
| HTTP | Dio |
| Storage | flutter_secure_storage |
| Dates | intl |

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.10.0
- Dart SDK ≥ 3.0.0

### Installation

```bash
# Clone the repository
git clone https://github.com/liorboyango/krizot-app.git
cd krizot-app

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on desktop (macOS)
flutter run -d macos
```

### Configuration

The API base URL defaults to `http://localhost:3000/api`. Override at build time:

```bash
flutter run --dart-define=KRIZOT_API_URL=https://your-api.example.com/api
```

### Running Tests

```bash
flutter test
```

## Project Structure

```
lib/
├── main.dart             # Entry point – ProviderScope + KrizotApp
├── app.dart              # Root widget – theme + GoRouter
├── router/
│   └── app_router.dart   # Route definitions + auth guard
├── screens/
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── stations_screen.dart
│   └── schedule_screen.dart
├── widgets/
│   └── app_shell.dart    # Sidebar / bottom-nav shell
├── services/
│   ├── api_client.dart   # Dio HTTP client
│   └── auth_service.dart # Login / logout / session restore
├── providers/
│   └── auth_provider.dart
├── models/
│   ├── user_model.dart
│   ├── station_model.dart
│   └── schedule_model.dart
└── utils/
    ├── app_colors.dart
    ├── app_theme.dart
    ├── breakpoints.dart
    ├── constants.dart
    ├── validators.dart
    └── error_handler.dart
```

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Login | `/login` | Email + password authentication |
| Dashboard | `/` | Stats overview + today's schedule |
| Stations | `/stations` | Station CRUD management |
| Schedule | `/schedule` | Weekly shift grid |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes
4. Open a pull request

## License

MIT © Krizot
