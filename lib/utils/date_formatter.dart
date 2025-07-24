// lib/utils/date_formatter.dart

class DateFormatter {
  // Month abbreviations for the circles
  static List<String> getMonthNames() {
    return [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
  }

  // Full month names
  static List<String> getFullMonthNames() {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
  }

  // Get month name by index (1-12)
  static String getMonthName(int monthIndex) {
    if (monthIndex < 1 || monthIndex > 12) {
      return 'Invalid';
    }
    return getFullMonthNames()[monthIndex - 1];
  }

  // Get month abbreviation by index (1-12)
  static String getMonthAbbreviation(int monthIndex) {
    if (monthIndex < 1 || monthIndex > 12) {
      return 'Invalid';
    }
    return getMonthNames()[monthIndex - 1];
  }

  // Format date for display
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format date with month name
  static String formatDateWithMonthName(DateTime date) {
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  }

  // Get current month key (e.g., "01", "02", etc.)
  static String getCurrentMonthKey() {
    return DateTime.now().month.toString().padLeft(2, '0');
  }

  // Get month key from index (1-12)
  static String getMonthKey(int monthIndex) {
    if (monthIndex < 1 || monthIndex > 12) {
      return '00';
    }
    return monthIndex.toString().padLeft(2, '0');
  }

  // Parse month key to index
  static int parseMonthKey(String monthKey) {
    try {
      return int.parse(monthKey);
    } catch (e) {
      return 0;
    }
  }

  // Check if a month is in the past
  static bool isMonthInPast(String monthKey, int year) {
    final now = DateTime.now();
    final monthIndex = parseMonthKey(monthKey);

    if (year < now.year) return true;
    if (year > now.year) return false;

    return monthIndex < now.month;
  }

  // Check if a month is current
  static bool isCurrentMonth(String monthKey, int year) {
    final now = DateTime.now();
    final monthIndex = parseMonthKey(monthKey);

    return year == now.year && monthIndex == now.month;
  }

  // Check if a month is in the future
  static bool isMonthInFuture(String monthKey, int year) {
    final now = DateTime.now();
    final monthIndex = parseMonthKey(monthKey);

    if (year > now.year) return true;
    if (year < now.year) return false;

    return monthIndex > now.month;
  }

  // Format time ago
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Format currency amount
  static String formatCurrency(double amount, {String currency = 'HUF'}) {
    if (currency == 'HUF') {
      return '${amount.toStringAsFixed(0)} Ft';
    } else if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    } else if (currency == 'EUR') {
      return '€${amount.toStringAsFixed(2)}';
    }
    return '${amount.toStringAsFixed(2)} $currency';
  }
}
