import 'package:intl/intl.dart';

abstract final class DateFormatters {
  static final _fullFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final _dateOnly = DateFormat('yyyy-MM-dd');
  static final _timeOnly = DateFormat('HH:mm');

  static String full(DateTime dt) => _fullFormat.format(dt);
  static String dateOnly(DateTime dt) => _dateOnly.format(dt);
  static String timeOnly(DateTime dt) => _timeOnly.format(dt);

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return dateOnly(dt);
  }
}
