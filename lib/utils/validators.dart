/// Client-side form validators for Krizot.
///
/// Each validator follows the Flutter [FormField.validator] signature:
/// returns `null` when valid, or an error message string when invalid.
library;

/// Collection of reusable form-field validators.
class Validators {
  Validators._();

  // ---------------------------------------------------------------------------
  // Generic
  // ---------------------------------------------------------------------------

  /// Ensures the field is not empty.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Ensures the value has at least [min] characters.
  static String? minLength(String? value, int min, {String fieldName = 'Field'}) {
    if (value == null || value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  /// Ensures the value does not exceed [max] characters.
  static String? maxLength(String? value, int max, {String fieldName = 'Field'}) {
    if (value != null && value.trim().length > max) {
      return '$fieldName must not exceed $max characters';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Email
  // ---------------------------------------------------------------------------

  /// Validates an email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  /// Validates a password (min 8 chars).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Numbers
  // ---------------------------------------------------------------------------

  /// Validates that the value is an integer within [min]..[max].
  static String? intRange(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a whole number';
    }
    if (parsed < min || parsed > max) {
      return '$fieldName must be between $min and $max';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Composite helpers
  // ---------------------------------------------------------------------------

  /// Runs multiple validators in sequence and returns the first error.
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
