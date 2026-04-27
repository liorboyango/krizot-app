/// Form field validators for Krizot.
class Validators {
  Validators._();

  /// Validates email format.
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

  /// Validates password (min 6 chars).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates required text field.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates numeric capacity (1-20).
  static String? capacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Capacity is required';
    }
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 1 || n > 20) return 'Capacity must be between 1 and 20';
    return null;
  }
}
