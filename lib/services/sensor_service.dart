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

  // True only when the ESP32 delivered a genuine N/P/K reading.
  // When false, nitrogen/phosphorus/potassium are 0.0 placeholders
  // and must not be shown as measurements.
  final bool npkValid;
  final String npkError;

  // Seconds since the last valid NPK reading, if known.
  final double? npkAgeSeconds;

  SensorData({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.rain,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.pumpOn,
    this.npkValid = false,
    this.npkError = "",
    this.npkAgeSeconds,
  });

  // A valid reading older than this (ESP32 posts every minute) is stale.
  static const double npkStaleAfterSeconds = 180;

  bool get npkStale =>
      npkValid &&
      npkAgeSeconds != null &&
      npkAgeSeconds! > npkStaleAfterSeconds;

  String get npkProblem {
    if (npkValid) {
      return npkStale ? "NPK reading is outdated" : "";
    }
    switch (npkError) {
      case "no_response_timeout":
        return "NPK sensor not responding - check power, RS485 A/B wiring and baud rate";
      case "crc_mismatch":
      case "bad_response_header":
      case "short_response":
      case "unexpected_byte_count":
        return "NPK sensor sent an invalid response - check RS485 wiring and baud rate";
      case "modbus_exception":
        return "NPK sensor rejected the request - check slave address and registers";
      case "value_out_of_range":
        return "NPK sensor value out of range";
      case "no_data_received":
        return "Waiting for NPK data from ESP32";
      case "no_npk_data_from_esp32":
        return "ESP32 firmware is not sending NPK readings";
      default:
        return npkError.isEmpty
            ? "NPK sensor data unavailable"
            : "NPK sensor data unavailable ($npkError)";
    }
  }

  factory SensorData.fromJson(Map<String, dynamic> j) {
    double numValue(String key) => (j[key] as num?)?.toDouble() ?? 0.0;
    final hasNpkNumbers = j["nitrogen"] is num &&
        j["phosphorus"] is num &&
        j["potassium"] is num;
    return SensorData(
      soilMoisture: numValue("soil_moisture"),
      temperature: numValue("temperature"),
      humidity: numValue("humidity"),
      rain: j["rain"] == true,
      nitrogen: numValue("nitrogen"),
      phosphorus: numValue("phosphorus"),
      potassium: numValue("potassium"),
      pumpOn: j["pump_status"] == "ON",
      // Only trust NPK when the backend says it is valid AND the
      // numbers are really present.
      npkValid: j["npk_valid"] == true && hasNpkNumbers,
      npkError: (j["npk_error"] ?? "").toString(),
      npkAgeSeconds: (j["npk_age_seconds"] as num?)?.toDouble(),
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
