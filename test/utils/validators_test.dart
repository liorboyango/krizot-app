import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('returns error for null', () {
      expect(Validators.required(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.required(''), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(Validators.required('   '), isNotNull);
    });

    test('returns null for valid value', () {
      expect(Validators.required('hello'), isNull);
    });
  });

  group('Validators.email', () {
    test('returns error for null', () {
      expect(Validators.email(null), isNotNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.email('notanemail'), isNotNull);
      expect(Validators.email('missing@'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('admin@krizot.io'), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for null', () {
      expect(Validators.password(null), isNotNull);
    });

    test('returns error for short password', () {
      expect(Validators.password('abc'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(Validators.password('password123'), isNull);
    });
  });

  group('Validators.stationName', () {
    test('returns error for null', () {
      expect(Validators.stationName(null), isNotNull);
    });

    test('returns error for single char', () {
      expect(Validators.stationName('A'), isNotNull);
    });

    test('returns error for too long name', () {
      expect(Validators.stationName('A' * 101), isNotNull);
    });

    test('returns null for valid name', () {
      expect(Validators.stationName('Alpha Station'), isNull);
    });
  });

  group('Validators.capacity', () {
    test('returns error for null', () {
      expect(Validators.capacity(null), isNotNull);
    });

    test('returns error for non-numeric', () {
      expect(Validators.capacity('abc'), isNotNull);
    });

    test('returns error for zero', () {
      expect(Validators.capacity('0'), isNotNull);
    });

    test('returns error for over 20', () {
      expect(Validators.capacity('21'), isNotNull);
    });

    test('returns null for valid capacity', () {
      expect(Validators.capacity('1'), isNull);
      expect(Validators.capacity('10'), isNull);
      expect(Validators.capacity('20'), isNull);
    });
  });

  group('Validators.notes', () {
    test('returns null for null (optional field)', () {
      expect(Validators.notes(null), isNull);
    });

    test('returns null for empty string', () {
      expect(Validators.notes(''), isNull);
    });

    test('returns error for over 500 chars', () {
      expect(Validators.notes('A' * 501), isNotNull);
    });

    test('returns null for valid notes', () {
      expect(Validators.notes('Some notes here'), isNull);
    });
  });
}
