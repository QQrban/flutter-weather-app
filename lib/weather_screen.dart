import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController();

  String city = 'Tashkent';
  String description = 'Sunny';
  int temperature = 22;
  String icon = 'clear';

  void searchWeather() {
    final text = _cityController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      city = text;

      if (text.toLowerCase() == 'tallinn') {
        temperature = 10;
        description = 'Cloudy';
        icon = 'clouds';
      } else if (text.toLowerCase() == 'tartu') {
        temperature = 14;
        description = 'Hot';
        icon = 'thunder';
      } else {
        temperature = 22;
        description = 'Sunny';
        icon = 'clear';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
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
                        onSubmitted: (_) => searchWeather(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Lottie.asset('assets/$icon.json'),
                      Text(
                        city,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$temperature°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
