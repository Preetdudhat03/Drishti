import 'package:intl/intl.dart';

class AppFormatters {
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String formatTimestamp(DateTime? dateTime) => formatDateTime(dateTime);

  static String formatDateOnly(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String formatPercentage(double? value, {int decimals = 1}) {
    if (value == null) return 'N/A';
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  static String formatPercent(double? value, {int decimals = 1}) =>
      formatPercentage(value, decimals: decimals);

  static String formatProbability(double? prob) {
    if (prob == null) return 'N/A';
    return '${(prob * 100).toStringAsFixed(1)}%';
  }

  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(dateTime);
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
}

