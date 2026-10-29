import 'package:flutter_test/flutter_test.dart';
import 'package:crop_advisory_app/services/sensor_service.dart';

void main() {
  Map<String, dynamic> base() => {
        "success": true,
        "soil_moisture": 41.0,
        "temperature": 27.5,
        "humidity": 60.0,
        "rain": false,
        "pump_status": "OFF",
      };

  test('valid NPK is parsed and shown as valid', () {
    final s = SensorData.fromJson({
      ...base(),
      "nitrogen": 42.0,
      "phosphorus": 17.0,
      "potassium": 88.0,
      "npk_valid": true,
      "npk_error": null,
      "npk_age_seconds": 5.0,
    });
    expect(s.npkValid, true);
    expect(s.nitrogen, 42.0);
    expect(s.phosphorus, 17.0);
    expect(s.potassium, 88.0);
    expect(s.npkProblem, "");
  });

  test('null NPK from backend is NOT valid and does not crash', () {
    final s = SensorData.fromJson({
      ...base(),
      "nitrogen": null,
      "phosphorus": null,
      "potassium": null,
      "npk_valid": false,
      "npk_error": "no_response_timeout",
    });
    expect(s.npkValid, false);
    expect(s.npkProblem, contains("not responding"));
    // Other readings are unaffected.
    expect(s.soilMoisture, 41.0);
    expect(s.temperature, 27.5);
  });

  test('valid flag without numbers is not trusted', () {
    final s = SensorData.fromJson({
      ...base(),
      "nitrogen": null,
      "phosphorus": 1,
      "potassium": 1,
      "npk_valid": true,
    });
    expect(s.npkValid, false);
  });

  test('missing NPK keys (old backend) is not valid', () {
    final s = SensorData.fromJson(base());
    expect(s.npkValid, false);
  });

  test('old valid reading is reported as outdated', () {
    final s = SensorData.fromJson({
      ...base(),
      "nitrogen": 1,
      "phosphorus": 2,
      "potassium": 3,
      "npk_valid": true,
      "npk_age_seconds": 600.0,
    });
    expect(s.npkValid, true);
    expect(s.npkStale, true);
    expect(s.npkProblem, contains("outdated"));
  });

  test('genuine zero is still a valid reading', () {
    final s = SensorData.fromJson({
      ...base(),
      "nitrogen": 0,
      "phosphorus": 0,
      "potassium": 0,
      "npk_valid": true,
      "npk_age_seconds": 1.0,
    });
    expect(s.npkValid, true);
    expect(s.nitrogen, 0.0);
  });
}
