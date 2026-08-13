const List<Map<String, String>> kDefaultCurrencies = [
  {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
  {'code': 'SAR', 'symbol': 'ر.س', 'name': 'Saudi Riyal'},
  {'code': 'SGD', 'symbol': '\$', 'name': 'Singapore Dollar'},
  {'code': 'THB', 'symbol': '฿', 'name': 'Thai Baht'},
  {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  {'code': 'AUD', 'symbol': '\$', 'name': 'Australian Dollar'},
  {'code': 'CAD', 'symbol': '\$', 'name': 'Canadian Dollar'},
  {'code': 'CHF', 'symbol': 'Fr', 'name': 'Swiss Franc'},
  {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
  {'code': 'KWD', 'symbol': 'د.ك', 'name': 'Kuwaiti Dinar'},
  {'code': 'QAR', 'symbol': 'ر.ق', 'name': 'Qatari Riyal'},
  {'code': 'BHD', 'symbol': 'د.ب', 'name': 'Bahraini Dinar'},
  {'code': 'NZD', 'symbol': '\$', 'name': 'New Zealand Dollar'},
  {'code': 'HKD', 'symbol': '\$', 'name': 'Hong Kong Dollar'},
  {'code': 'MYR', 'symbol': 'RM', 'name': 'Malaysian Ringgit'},
  {'code': 'LKR', 'symbol': 'Rs', 'name': 'Sri Lankan Rupee'},
  {'code': 'IDR', 'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
  {'code': 'VND', 'symbol': '₫', 'name': 'Vietnamese Dong'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
];

const List<String> kDefaultCategories = [
  'Hotel',
  'Flights',
  'Taxi/Cab',
  'Food',
  'Snacks/Coffee',
  'Activities',
  'Fuel',
  'Shopping',
  'Visa',
  'SIM/Internet',
  'Tickets',
  'Miscellaneous',
  'Drinks',
];

String currencySymbol(String code) {
  for (final c in kDefaultCurrencies) {
    if (c['code'] == code) return c['symbol']!;
  }
  return '$code ';
}

String formatMoney(double amount, String currencyCode) {
  final symbol = currencySymbol(currencyCode);
  final value = amount.abs();
  final isInr = currencyCode == 'INR';
  final whole = value.floor();
  final frac = ((value - whole) * 100).round();
  final sign = amount < 0 ? '-' : '';

  String groupDigits(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    if (isInr) {
      final last3 = s.substring(s.length - 3);
      final rest = s.substring(0, s.length - 3);
      final buf = StringBuffer();
      for (var i = 0; i < rest.length; i++) {
        if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
        buf.write(rest[i]);
      }
      return '$buf,$last3';
    }
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(re, (_) => ',');
  }

  if (frac == 0) return '$sign$symbol${groupDigits(whole)}';
  return '$sign$symbol${groupDigits(whole)}.$frac';
}
