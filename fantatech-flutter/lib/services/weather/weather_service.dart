import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

/// Snapshot of the current weather at the user's real location.
class WeatherInfo {
  final double temperatureC;
  final String city;
  final int weatherCode; // WMO weather interpretation code
  final bool isDay;
  final int humidityPct;

  const WeatherInfo({
    required this.temperatureC,
    required this.city,
    required this.weatherCode,
    required this.isDay,
    required this.humidityPct,
  });
}

/// Fetches the device's real GPS position, reverse-geocodes it to a city name,
/// and pulls live current weather from the free Open-Meteo API (no API key).
class WeatherService {
  static const _base = 'https://api.open-meteo.com/v1/forecast';

  /// Returns live weather for the current location, or `null` if location
  /// permission is denied / unavailable / the network call fails.
  static Future<WeatherInfo?> fetch() async {
    try {
      final pos = await _resolvePosition();
      if (pos == null) return null;

      final city = await _resolveCity(pos.latitude, pos.longitude);

      final uri = Uri.parse(
        '$_base?latitude=${pos.latitude}&longitude=${pos.longitude}'
        '&current=temperature_2m,relative_humidity_2m,weather_code,is_day',
      );
      final resp = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      return WeatherInfo(
        temperatureC: (current['temperature_2m'] as num).toDouble(),
        city: city,
        weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
        isDay: (current['is_day'] as num?)?.toInt() == 1,
        humidityPct: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolve GPS position, requesting permission if needed.
  static Future<Position?> _resolvePosition() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Reverse-geocode coordinates into a human-readable city name.
  static Future<String> _resolveCity(double lat, double lon) async {
    try {
      final places = await placemarkFromCoordinates(lat, lon);
      if (places.isNotEmpty) {
        final p = places.first;
        final name = p.locality?.isNotEmpty == true
            ? p.locality
            : (p.subAdministrativeArea?.isNotEmpty == true
                ? p.subAdministrativeArea
                : p.administrativeArea);
        if (name != null && name.isNotEmpty) return name;
      }
    } catch (_) {/* fall through */}
    return '—';
  }
}
