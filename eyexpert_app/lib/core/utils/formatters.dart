import 'package:intl/intl.dart';

class AppFormatters {
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String formatDateOnly(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String formatPercentage(double? value, {int decimals = 1}) {
    if (value == null) return 'N/A';
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  static String formatProbability(double? prob) {
    if (prob == null) return 'N/A';
    return '${(prob * 100).toStringAsFixed(1)}%';
  }

  static String formatEye(String? eye) {
    if (eye == null) return 'N/A';
    switch (eye.toUpperCase()) {
      case 'OD':
        return 'Right Eye (OD)';
      case 'OS':
        return 'Left Eye (OS)';
      case 'OU':
        return 'Both Eyes (OU)';
      default:
        return eye;
    }
  }

  /// Returns a time-appropriate greeting (Good Morning, Good Afternoon, Good Evening)
  static String getGreeting([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }
}
