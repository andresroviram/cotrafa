import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String localizedCop(BuildContext context, num amount) => NumberFormat.currency(
  locale: _localeName(context),
  symbol: r'$',
  decimalDigits: 0,
).format(amount);

String localizedDate(BuildContext context, DateTime date) =>
    DateFormat.yMd(_localeName(context)).format(date);

String localizedDateTime(BuildContext context, DateTime date) =>
    DateFormat.yMd(_localeName(context)).add_Hm().format(date);

String _localeName(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'es_CO';
