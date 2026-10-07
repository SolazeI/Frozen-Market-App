import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _peso = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );
  static final _date = DateFormat('MMM d, y');
  static final _dateTime = DateFormat('MMM d, y • h:mm a');

  /// 1080 -> ₱1,080.00
  static String peso(num amount) => _peso.format(amount);

  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);
}
