class CurrencyAbbreviator {
  CurrencyAbbreviator._();

  static String abbreviate(int amount, {String locale = 'en'}) {
    if (locale == 'id') return _abbreviateId(amount);
    return _abbreviateEn(amount);
  }

  static String _abbreviateEn(int amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000;
      final formatted = val.toStringAsFixed(1);
      return '${formatted.endsWith('.0') ? formatted.substring(0, formatted.length - 2) : formatted}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }

  static String _abbreviateId(int amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000;
      final formatted = val.toStringAsFixed(1);
      return '${formatted.endsWith('.0') ? formatted.substring(0, formatted.length - 2) : formatted}jt';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toString();
  }
}
