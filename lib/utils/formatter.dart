import 'package:intl/intl.dart';

final currencyFormatter = NumberFormat.simpleCurrency(locale: 'en_IN');
String fmt(double v) => currencyFormatter.format(v);