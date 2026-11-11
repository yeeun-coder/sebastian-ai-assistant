import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class WeatherController extends GetxController {

  RxString weather = ''.obs;
  RxInt temperature = 0.obs;
  RxString briefingText = ''.obs;

  final apiKey = 'ac13dcaf14c9e96c05cae27ee0a9f170';

  @override
  void onInit() {
    super.onInit();

    fetchWeather();
  }

  Future<void> fetchWeather() async {

    try {
      // 서울
      // const lat = 37.5665;
      // const lon = 126.9780;

      // 인천
      const lat = 37.4563;
      const lon = 126.7052;

      final url =
          'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat'
          '&lon=$lon'
          '&appid=$apiKey'
          '&units=metric'
          '&lang=kr';

      final response = await http.get(Uri.parse(url));

      final data = jsonDecode(response.body);

      // print(data);

      if (data['weather'] == null) {
        briefingText.value = "날씨 정보를 불러올 수 없어요";
        return;
      }

      weather.value = data['weather'][0]['main'];
      temperature.value = data['main']['temp'].round();

      setBriefing();
    } catch (e) {
      print(e);
      briefingText.value = "날씨 정보를 불러올 수 없어요";
    }
  }

  void setBriefing() {

    final w = weather.value.toLowerCase();

    if (w.contains('rain')) {
      briefingText.value = '우산 챙기세요';
      return;
    }

    if (w.contains('snow')) {
      briefingText.value = '길이 미끄러울 수 있어요';
      return;
    }

    if (w.contains('clear')) {
      briefingText.value = '햇살이 좋은 하루예요';
      return;
    }

    if (w.contains('cloud')) {
      briefingText.value = '구름이 많은 날이에요';
      return;
    }

    if (w.contains('mist') ||
        w.contains('fog') ||
        w.contains('haze')) {
      briefingText.value = '안개가 짙어요';
      return;
    }

    briefingText.value = '좋은 하루 보내세요';
  }

  IconData weatherIcon() {

    final w = weather.value.toLowerCase();

    if (w.contains('rain')) {
      return Icons.umbrella;
    }

    if (w.contains('cloud')) {
      return Icons.cloud;
    }

    if (w.contains('clear')) {
      return Icons.wb_sunny;
    }

    if (w.contains('snow')) {
      return Icons.ac_unit;
    }

    if (w.contains('mist') ||
        w.contains('fog') ||
        w.contains('haze')) {
      return Icons.blur_on;
    }

    return Icons.wb_cloudy;
  }

  String weatherText() {

    final w = weather.value.toLowerCase();

    if (w.contains('rain')) {
      return '비';
    }

    if (w.contains('cloud')) {
      return '구름';
    }

    if (w.contains('clear')) {
      return '맑음';
    }

    if (w.contains('snow')) {
      return '눈';
    }

    if (w.contains('mist') ||
        w.contains('fog') ||
        w.contains('haze')) {
      return '안개';
    }

    return '날씨';
  }
}