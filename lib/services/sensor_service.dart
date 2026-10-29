import 'dart:convert';
import 'package:http/http.dart' as http;

// CHANGE THIS to the IP address of the computer running Flask.
// Example: http://192.168.1.5:5000
const String apiBaseUrl = "http://10.69.1.205:5000";

class SensorData {
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final bool rain;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final bool pumpOn;

  SensorData({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.rain,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.pumpOn,
  });

  factory SensorData.fromJson(Map<String, dynamic> j) {
    double numValue(String key) => (j[key] as num?)?.toDouble() ?? 0.0;
    return SensorData(
      soilMoisture: numValue("soil_moisture"),
      temperature: numValue("temperature"),
      humidity: numValue("humidity"),
      rain: j["rain"] == true,
      nitrogen: numValue("nitrogen"),
      phosphorus: numValue("phosphorus"),
      potassium: numValue("potassium"),
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
