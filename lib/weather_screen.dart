import 'dart:async';

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
  final FocusNode _cityFocusNode = FocusNode();

  late final String apiKey;
  late final WeatherService _weatherService;

  Weather? _weather;
  List<CitySuggestion> _suggestions = [];
  String? _errorMessage;
  Timer? _debounce;
  bool _isLoading = false;
  bool _showSuggestions = false;

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
        _errorMessage = null;
      });

      final city = await _weatherService.getCurrentCity();
      final weather = await _weatherService.getWeather(city);

      setState(() {
        _weather = weather;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _weather = null;
        _errorMessage = _buildErrorMessage(e);
      });
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
        _errorMessage = null;
        _showSuggestions = false;
      });

      final weather = await _weatherService.getWeather(city);

      setState(() {
        _weather = weather;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _weather = null;
        _errorMessage = _buildErrorMessage(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCityChanged(String value) {
    _debounce?.cancel();

    final input = value.trim();
    if (input.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final currentText = _cityController.text.trim();
      if (currentText != input) return;

      try {
        final suggestions = await _weatherService.searchCities(input);
        if (!mounted || _cityController.text.trim() != input) return;
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty && _cityFocusNode.hasFocus;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    });
  }

  Future<void> _selectSuggestion(CitySuggestion suggestion) async {
    _cityController.text = suggestion.name;
    _cityController.selection = TextSelection.collapsed(
      offset: _cityController.text.length,
    );
    FocusScope.of(context).unfocus();

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _showSuggestions = false;
      });

      final weather = await _weatherService.getWeatherByCoordinates(
        suggestion.latitude,
        suggestion.longitude,
        cityName: suggestion.name,
      );

      if (!mounted) return;
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint(e.toString());
      setState(() {
        _weather = null;
        _errorMessage = _buildErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _buildErrorMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('city not found') || text.contains('status 404')) {
      return 'City not found';
    }
    return 'Failed to load weather data';
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
    _debounce?.cancel();
    _cityController.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = getWeatherAnimation(_weather?.mainCondition);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Scaffold(
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
                    focusNode: _cityFocusNode,
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
                    onTap: () {
                      if (_suggestions.isNotEmpty) {
                        setState(() {
                          _showSuggestions = true;
                        });
                      }
                    },
                    onChanged: _onCityChanged,
                    onSubmitted: (_) => _searchWeather(),
                  ),
                  if (_showSuggestions) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              title: Text(
                                suggestion.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () => _selectSuggestion(suggestion),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Expanded(
                    child: Center(
                      child: _isLoading
                          ? Lottie.asset(
                              'assets/loading.json',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            )
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
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Lottie.asset(
                                          'assets/nodata.json',
                                          width: 180,
                                          height: 180,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _errorMessage ?? 'No weather data',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
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
      ),
    );
  }
}
