import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:weather_mapp/weather_model.dart';
import 'package:weather_mapp/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController();

  late final String apiKey;
  late final WeatherService _weatherService;

  Weather? _weather;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    apiKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
    _weatherService = WeatherService(apiKey);

    _fetchWeatherByCurrentCity();
  }

  Future<void> _fetchWeatherByCurrentCity() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final city = await _weatherService.getCurrentCity();
      final weather = await _weatherService.getWeather(city);

      setState(() {
        _weather = weather;
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchWeather() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final weather = await _weatherService.getWeather(city);

      setState(() {
        _weather = weather;
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'clear';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return 'clouds';
      case 'thunderstorm':
        return 'thunder';
      case 'rain':
      case 'drizzle':
        return 'rain';
      case 'clear':
        return 'clear';
      default:
        return 'clear';
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = getWeatherAnimation(_weather?.mainCondition);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1020), Color(0xFF1E3A8A), Color(0xFF60A5FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter city',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.location_city,
                      color: Colors.white,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  onSubmitted: (_) => _searchWeather(),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _weather == null
                                ? const Text(
                                    'No weather data',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Lottie.asset('assets/$animation.json'),
                                      Text(
                                        _weather!.city,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${_weather!.temperature.round()}°',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 72,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _weather!.mainCondition,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
