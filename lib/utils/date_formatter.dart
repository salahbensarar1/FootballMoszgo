import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DateFormatter {
  static String formatTimestamp(Timestamp? timestamp,
      {String format = 'dd MMM yyyy'}) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat(format).format(timestamp.toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  static String formatDateTime(DateTime? dateTime,
      {String format = 'dd MMM yyyy'}) {
    if (dateTime == null) return 'N/A';
    try {
      return DateFormat(format).format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

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
}
