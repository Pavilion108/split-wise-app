import 'package:flutter/material.dart';

/// Maps currency codes to country info with high-quality background images
/// and realistic weather effects.
class CountryTheme {
  const CountryTheme({
    required this.country,
    required this.imageUrl,
    required this.fallbackColors,
    required this.tintColor,
    required this.effectType,
  });

  final String country;
  final String imageUrl;
  final List<Color> fallbackColors;
  final Color tintColor;
  final WeatherEffect effectType;
}

enum WeatherEffect {
  snow,
  rain,
  petals,
  leaves,
  sand,
  aurora,
  fireflies,
  none,
}

/// High-quality country backgrounds — each image is carefully chosen
/// for iconic representation. Uses Unsplash CDN at 1920px for crisp display.
class CountryThemes {
  CountryThemes._();

  static final Map<String, CountryTheme> _themes = {
    'INR': const CountryTheme(
      country: 'India',
      imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1a0a2e), Color(0xFF16213e), Color(0xFF0f3460)],
      tintColor: Color(0x20FF9933),
      effectType: WeatherEffect.petals,
    ),
    'USD': const CountryTheme(
      country: 'United States',
      imageUrl: 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
      tintColor: Color(0x203B5998),
      effectType: WeatherEffect.leaves,
    ),
    'EUR': const CountryTheme(
      country: 'Europe',
      imageUrl: 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF0c0c1d), Color(0xFF1a1a3e), Color(0xFF2d2d6e)],
      tintColor: Color(0x20003399),
      effectType: WeatherEffect.snow,
    ),
    'GBP': const CountryTheme(
      country: 'United Kingdom',
      imageUrl: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF141E30), Color(0xFF243B55), Color(0xFF2c3e50)],
      tintColor: Color(0x20CF142B),
      effectType: WeatherEffect.rain,
    ),
    'AED': const CountryTheme(
      country: 'UAE',
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF3e2723), Color(0xFF5d4037), Color(0xFF8d6e63)],
      tintColor: Color(0x20D4AF37),
      effectType: WeatherEffect.sand,
    ),
    'SAR': const CountryTheme(
      country: 'Saudi Arabia',
      imageUrl: 'https://images.unsplash.com/photo-1578894381163-e72c17f2d45f?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1b3a1b), Color(0xFF2d5a27), Color(0xFF3e7c3e)],
      tintColor: Color(0x20006C35),
      effectType: WeatherEffect.sand,
    ),
    'SGD': const CountryTheme(
      country: 'Singapore',
      imageUrl: 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF0d1b2a), Color(0xFF1b2838), Color(0xFF2d3a4e)],
      tintColor: Color(0x20EF3340),
      effectType: WeatherEffect.rain,
    ),
    'THB': const CountryTheme(
      country: 'Thailand',
      imageUrl: 'https://images.unsplash.com/photo-1504214208698-ea1916a2195a?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF2d1b00), Color(0xFF5c3d00), Color(0xFF8b6914)],
      tintColor: Color(0x20F44336),
      effectType: WeatherEffect.petals,
    ),
    'JPY': const CountryTheme(
      country: 'Japan',
      imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1a0a0a), Color(0xFF3d1515), Color(0xFF5c2020)],
      tintColor: Color(0x20BC002D),
      effectType: WeatherEffect.petals,
    ),
    'AUD': const CountryTheme(
      country: 'Australia',
      imageUrl: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF0a1628), Color(0xFF1a2d4a), Color(0xFF2d4a6e)],
      tintColor: Color(0x2000008B),
      effectType: WeatherEffect.fireflies,
    ),
    'CAD': const CountryTheme(
      country: 'Canada',
      imageUrl: 'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF0c1445), Color(0xFF1a2860), Color(0xFF2d3e80)],
      tintColor: Color(0x20FF0000),
      effectType: WeatherEffect.snow,
    ),
    'CHF': const CountryTheme(
      country: 'Switzerland',
      imageUrl: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF0a1a0a), Color(0xFF1a3a1a), Color(0xFF2d5a2d)],
      tintColor: Color(0x20FF0000),
      effectType: WeatherEffect.snow,
    ),
    'CNY': const CountryTheme(
      country: 'China',
      imageUrl: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1a0000), Color(0xFF3d0a0a), Color(0xFF5c1a1a)],
      tintColor: Color(0x20DE2910),
      effectType: WeatherEffect.petals,
    ),
    'KWD': const CountryTheme(
      country: 'Kuwait',
      imageUrl: 'https://images.unsplash.com/photo-1562979314-bee7453e911c?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1a1a00), Color(0xFF3d3d0a), Color(0xFF5c5c1a)],
      tintColor: Color(0x20007A3D),
      effectType: WeatherEffect.sand,
    ),
    'QAR': const CountryTheme(
      country: 'Qatar',
      imageUrl: 'https://images.unsplash.com/photo-1549927681-0b673b8243ab?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1a0a1a), Color(0xFF3d1a3d), Color(0xFF5c2d5c)],
      tintColor: Color(0x208D1B3D),
      effectType: WeatherEffect.sand,
    ),
    'BHD': const CountryTheme(
      country: 'Bahrain',
      imageUrl: 'https://images.unsplash.com/photo-1578894381163-e72c17f2d45f?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1a0505), Color(0xFF3d0a0a), Color(0xFF5c1515)],
      tintColor: Color(0x20CE1126),
      effectType: WeatherEffect.sand,
    ),
    'NZD': const CountryTheme(
      country: 'New Zealand',
      imageUrl: 'https://images.unsplash.com/photo-1507699622108-4be3abd695ad?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF0a0a14), Color(0xFF1a1a28), Color(0xFF2d2d4a)],
      tintColor: Color(0x20000000),
      effectType: WeatherEffect.rain,
    ),
    'HKD': const CountryTheme(
      country: 'Hong Kong',
      imageUrl: 'https://images.unsplash.com/photo-1536599018102-9f803c2e25b5?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF0d0d1a), Color(0xFF1a1a33), Color(0xFF2d2d4d)],
      tintColor: Color(0x20DE2910),
      effectType: WeatherEffect.rain,
    ),
    'MYR': const CountryTheme(
      country: 'Malaysia',
      imageUrl: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF000a1a), Color(0xFF001a3d), Color(0xFF002d5c)],
      tintColor: Color(0x20010066),
      effectType: WeatherEffect.rain,
    ),
    'LKR': const CountryTheme(
      country: 'Sri Lanka',
      imageUrl: 'https://images.unsplash.com/photo-1586526399035-84a6e4f3c7f5?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF141a00), Color(0xFF283300), Color(0xFF3d4d00)],
      tintColor: Color(0x20FFBE0B),
      effectType: WeatherEffect.rain,
    ),
    'IDR': const CountryTheme(
      country: 'Indonesia',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1a0000), Color(0xFF3d0505), Color(0xFF5c0a0a)],
      tintColor: Color(0x20CE1126),
      effectType: WeatherEffect.rain,
    ),
    'VND': const CountryTheme(
      country: 'Vietnam',
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF1a0000), Color(0xFF3d0808), Color(0xFF5c1010)],
      tintColor: Color(0x20DA251D),
      effectType: WeatherEffect.rain,
    ),
    'ZAR': const CountryTheme(
      country: 'South Africa',
      imageUrl: 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?w=1920&q=85&fit=crop',
      fallbackColors: [Color(0xFF000a14), Color(0xFF001a28), Color(0xFF002d3d)],
      tintColor: Color(0x20007749),
      effectType: WeatherEffect.fireflies,
    ),
  };

  /// Get the theme for a currency code. Returns null if unknown.
  static CountryTheme? forCurrency(String currencyCode) {
    return _themes[currencyCode.toUpperCase()];
  }

  /// Get all supported currency codes.
  static List<String> get supportedCurrencies => _themes.keys.toList();

  /// Get a default gradient for unknown currencies.
  static const defaultColors = [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)];
}
