/// Form field validators for the Krizot app.
///
/// All validators follow the Flutter FormField validator signature:
/// `String? Function(String? value)`
/// Returning null means valid; returning a string means invalid (the error message).
library;

/// Collection of reusable form validators.
class Validators {
  Validators._();

  // ---------------------------------------------------------------------------
  // Required
  // ---------------------------------------------------------------------------

  /// Validates that a field is not empty.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Email
  // ---------------------------------------------------------------------------

  /// Validates that a field contains a valid email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  /// Validates that a password meets minimum requirements.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates that a confirmation password matches the original.
  static String? Function(String?) confirmPassword(String original) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != original) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  // ---------------------------------------------------------------------------
  // Station fields
  // ---------------------------------------------------------------------------

  /// Validates a station name (2-100 chars).
  static String? stationName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Station name is required';
    }
    if (value.trim().length < 2) {
      return 'Station name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Station name must be 100 characters or fewer';
    }
    return null;
  }

  /// Validates a location/sector field.
  static String? location(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    if (value.trim().length < 2) {
      return 'Location must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Location must be 100 characters or fewer';
    }
    return null;
  }

  /// Validates a capacity value (integer, 1-20).
  static String? capacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Capacity is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Capacity must be a whole number';
    }
    if (parsed < 1) {
      return 'Capacity must be at least 1';
    }
    if (parsed > 20) {
      return 'Capacity cannot exceed 20';
    }
    return null;
  }

  /// Validates an optional notes field (max 500 chars).
  static String? notes(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > 500) {
      return 'Notes must be 500 characters or fewer';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Schedule fields
  // ---------------------------------------------------------------------------

  /// Validates that a start time is provided.
  static String? startTime(DateTime? value) {
    if (value == null) return 'Start time is required';
    return null;
  }

  /// Validates that an end time is after the start time.
  static String? Function(DateTime?) endTime(DateTime? startTime) {
    return (DateTime? value) {
      if (value == null) return 'End time is required';
      if (startTime != null && !value.isAfter(startTime)) {
        return 'End time must be after start time';
      }
      return null;
    };
  }

  // ---------------------------------------------------------------------------
  // Generic
  // ---------------------------------------------------------------------------

  /// Validates minimum string length.
  static String? Function(String?) minLength(int min, {String? fieldName}) {
    return (String? value) {
      if (value == null || value.trim().length < min) {
        final name = fieldName ?? 'This field';
        return '$name must be at least $min characters';
      }
      return null;
    };
  }

  /// Validates maximum string length.
  static String? Function(String?) maxLength(int max, {String? fieldName}) {
    return (String? value) {
      if (value != null && value.trim().length > max) {
        final name = fieldName ?? 'This field';
        return '$name must be $max characters or fewer';
      }
      return null;
    };
  }

  /// Combines multiple validators, returning the first error found.
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
