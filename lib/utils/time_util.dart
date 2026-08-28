import 'package:intl/intl.dart';

/// Date/time helpers shared by the scheduling grid and shift services.
class TimeUtil {
  TimeUtil._();

  static final DateFormat _dayKeyFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dayLabelFormat = DateFormat('EEE d MMM');

  /// 'YYYY-MM-DD' key of [date] in local time — matches `shifts.dayKey`.
  static String dayKey(DateTime date) => _dayKeyFormat.format(date);

  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String formatDayLabel(DateTime date) => _dayLabelFormat.format(date);

  static String formatRange(DateTime start, DateTime end) =>
      '${formatTime(start)}–${formatTime(end)}';

  /// Midnight (local) of [date].
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Monday midnight of the week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final day = startOfDay(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// The seven days of the week containing [date], starting Monday.
  static List<DateTime> weekDays(DateTime date) {
    final monday = startOfWeek(date);
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
