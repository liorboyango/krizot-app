/// Form field validators for the Krizot application.
class Validators {
  Validators._();

  /// Validates that a field is not empty.
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validates an email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a password (min 6 chars).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates station name (2-100 chars).
  static String? stationName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Station name is required';
    }
    if (value.trim().length < 2) {
      return 'Station name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Station name must be 100 characters or less';
    }
    return null;
  }

  /// Validates location/sector (2-100 chars).
  static String? location(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    if (value.trim().length < 2) {
      return 'Location must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Location must be 100 characters or less';
    }
    return null;
  }

  /// Validates capacity (1-20).
  static String? capacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Capacity is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Capacity must be a number';
    }
    if (parsed < 1) {
      return 'Capacity must be at least 1';
    }
    if (parsed > 20) {
      return 'Capacity cannot exceed 20';
    }
    return null;
  }

  /// Validates notes (optional, max 500 chars).
  static String? notes(String? value) {
    if (value != null && value.length > 500) {
      return 'Notes must be 500 characters or less';
    }
    return null;
  }
}
