import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// CHANGE THIS to the Wi-Fi IP address of the computer running Flask
// (run `ipconfig` and use the IPv4 address of the Wi-Fi adapter).
// It is only used by phones / emulators. It changes when you join a
// different network.
const String _flaskComputerIp = "172.19.123.205";

// ONE server address used by every screen.
//   * Chrome / web: the page is opened from the same computer that runs
//     Flask, so use the address the page itself was loaded from
//     (localhost) - this never goes stale when the Wi-Fi changes.
//   * Phone / emulator: the computer's Wi-Fi address above.
String get apiBaseUrl =>
    kIsWeb ? "http://${Uri.base.host}:5000" : "http://$_flaskComputerIp:5000";

class SensorData {
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final bool rain;
  final bool pumpOn;

  SensorData({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.rain,
    required this.pumpOn,
  });

  factory SensorData.fromJson(Map<String, dynamic> j) {
    double numValue(String key) => (j[key] as num?)?.toDouble() ?? 0.0;
    return SensorData(
      soilMoisture: numValue("soil_moisture"),
      temperature: numValue("temperature"),
      humidity: numValue("humidity"),
      rain: j["rain"] == true,
      pumpOn: j["pump_status"] == "ON",
    );
  }
}

class SensorService {
  static Future<SensorData> fetch() async {
    final response = await http
        .get(Uri.parse("$apiBaseUrl/sensor_data"))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception("Sensor server error: ${response.statusCode}");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data["success"] != true) {
      throw Exception(data["error"] ?? "Sensor data unavailable");
    }

    return SensorData.fromJson(data);
  }
}
