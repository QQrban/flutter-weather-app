import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import './weather_model.dart';

class CitySuggestion {
  final String name;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;
  final String? featureCode;
  final int? population;

  CitySuggestion({
    required this.name,
    required this.country,
    required this.admin1,
    required this.latitude,
    required this.longitude,
    required this.featureCode,
    required this.population,
  });

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      admin1: json['admin1']?.toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      featureCode: json['feature_code']?.toString(),
      population: (json['population'] as num?)?.toInt(),
    );
  }

  String get label {
    final region = admin1?.trim();
    if (region != null && region.isNotEmpty) {
      return '$name, $region, $country';
    }
    return '$name, $country';
  }
}

class WeatherService {
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const _geocodingHost = 'geocoding-api.open-meteo.com';
  static const _geocodingPath = '/v1/search';

  final String apiKey;

  WeatherService(this.apiKey);

  String _normalizeCityName(String name, String country) {
    final normalizedName = name.trim();
    final lowerName = normalizedName.toLowerCase();
    final lowerCountry = country.trim().toLowerCase();

    if (lowerCountry == 'estonia' &&
        (lowerName == 'revel' || lowerName == 'reval')) {
      return 'Tallinn';
    }
    return normalizedName;
  }

  Future<Weather> getWeather(String city) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('OpenWeather API key is missing');
    }

    final uri = Uri.parse(
      '$_baseUrl?q=${Uri.encodeQueryComponent(city)}&appid=$apiKey&units=metric',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    }

    String details = 'status ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message']?.toString();
      if (message != null && message.isNotEmpty) {
        details = '$details: $message';
      }
    } catch (_) {}

    throw Exception('Failed to load weather data ($details)');
  }

  Future<Weather> getWeatherByCoordinates(
    double latitude,
    double longitude, {
    String? cityName,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('OpenWeather API key is missing');
    }

    final uri = Uri.parse(
      '$_baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final weather = Weather.fromJson(jsonDecode(response.body));
      if (cityName != null && cityName.trim().isNotEmpty) {
        return Weather(
          city: cityName,
          temperature: weather.temperature,
          mainCondition: weather.mainCondition,
        );
      }
      return weather;
    }

    String details = 'status ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message']?.toString();
      if (message != null && message.isNotEmpty) {
        details = '$details: $message';
      }
    } catch (_) {}

    throw Exception('Failed to load weather data ($details)');
  }

  Future<List<CitySuggestion>> searchCities(String query) async {
    final input = query.trim();
    if (input.isEmpty) return const [];

    final uri = Uri.https(_geocodingHost, _geocodingPath, {
      'name': input,
      'count': '7',
      'language': 'en',
      'format': 'json',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return const [];
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'];
    if (results is! List) {
      return const [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(CitySuggestion.fromJson)
        .where((item) => item.name.isNotEmpty && item.country.isNotEmpty)
        .map(
          (item) => CitySuggestion(
            name: _normalizeCityName(item.name, item.country),
            country: item.country,
            admin1: item.admin1,
            latitude: item.latitude,
            longitude: item.longitude,
            featureCode: item.featureCode,
            population: item.population,
          ),
        )
        .where((item) {
          final code = item.featureCode?.toUpperCase() ?? '';
          if (code.isNotEmpty && !code.startsWith('PPL')) {
            return false;
          }

          return true;
        })
        .toList()
      ..sort((a, b) {
        final aPop = a.population ?? 0;
        final bPop = b.population ?? 0;
        return bPop.compareTo(aPop);
      });
  }

  Future<String> getCurrentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String? city = placemarks[0].locality;

    return city ?? '';
  }
}
