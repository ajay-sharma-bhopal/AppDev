import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeoService {
  static const _cacheKey = 'geo_locale';
  static const _cacheTimeKey = 'geo_locale_time';
  static const _cacheTtlMs = 72 * 3600 * 1000; // 72 hours

  static const _countryToLocale = {
    'US': 'en-US', 'GB': 'en-GB', 'AU': 'en-AU', 'CA': 'en-CA',
    'NZ': 'en-NZ', 'ZA': 'en-ZA', 'IE': 'en-IE',
    'IN': 'hi-IN', 'PK': 'ur-PK',
    'ES': 'es-ES', 'MX': 'es-MX', 'AR': 'es-AR', 'CO': 'es-CO',
    'CL': 'es-CL', 'PE': 'es-PE', 'VE': 'es-VE',
    'FR': 'fr-FR', 'BE': 'fr-BE', 'CH': 'fr-CH',
    'DE': 'de-DE', 'AT': 'de-AT',
    'BR': 'pt-BR', 'PT': 'pt-PT',
    'JP': 'ja-JP',
    'CN': 'zh-CN', 'TW': 'zh-TW', 'HK': 'zh-HK',
    'KR': 'ko-KR',
    'RU': 'ru-RU',
    'IT': 'it-IT',
    'SA': 'ar-SA', 'AE': 'ar-AE', 'EG': 'ar-EG', 'MA': 'ar-MA',
    'NL': 'nl-NL', 'PL': 'pl-PL', 'TR': 'tr-TR',
    'ID': 'id-ID', 'TH': 'th-TH', 'VN': 'vi-VN',
    'SE': 'sv-SE', 'NO': 'nb-NO', 'DK': 'da-DK', 'FI': 'fi-FI',
    'CZ': 'cs-CZ', 'SK': 'sk-SK', 'HU': 'hu-HU', 'RO': 'ro-RO',
    'GR': 'el-GR', 'HE': 'he-IL', 'IL': 'he-IL',
    'UA': 'uk-UA', 'HR': 'hr-HR', 'BG': 'bg-BG',
  };

  /// Returns the best matching BCP-47 locale string for the device's public IP,
  /// or null if detection fails. Result is cached for 72 hours.
  Future<String?> detectLocale() async {
    if (kIsWeb) return null; // ip-api.com doesn't allow CORS from web
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLocale = prefs.getString(_cacheKey);
      final cachedTime = prefs.getInt(_cacheTimeKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - cachedTime;

      if (cachedLocale != null && age < _cacheTtlMs) {
        return cachedLocale;
      }

      final response = await http
          .get(Uri.parse('http://ip-api.com/json?fields=countryCode'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final countryCode = data['countryCode'] as String?;
        if (countryCode != null) {
          final locale = _countryToLocale[countryCode] ?? 'en-US';
          await prefs.setString(_cacheKey, locale);
          await prefs.setInt(
              _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
          return locale;
        }
      }
    } catch (_) {}
    return null;
  }
}
