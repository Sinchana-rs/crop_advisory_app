import 'package:flutter_test/flutter_test.dart';
import 'package:crop_advisory_app/services/sensor_service.dart';

void main() {
  test('parses soil, temperature, humidity, rain and pump', () {
    final s = SensorData.fromJson({
      "success": true,
      "soil_moisture": 41.0,
      "temperature": 27.5,
      "humidity": 60.0,
      "rain": true,
      "pump_status": "ON",
    });
    expect(s.soilMoisture, 41.0);
    expect(s.temperature, 27.5);
    expect(s.humidity, 60.0);
    expect(s.rain, true);
    expect(s.pumpOn, true);
  });

  test('missing fields fall back to safe defaults', () {
    final s = SensorData.fromJson({"success": true});
    expect(s.soilMoisture, 0.0);
    expect(s.rain, false);
    expect(s.pumpOn, false);
  });

  test('extra fields from an older backend are ignored', () {
    final s = SensorData.fromJson({
      "success": true,
      "soil_moisture": 30,
      "temperature": 25,
      "humidity": 50,
      "rain": false,
      "pump_status": "OFF",
      "nitrogen": 10,
      "npk_valid": true,
    });
    expect(s.soilMoisture, 30.0);
    expect(s.pumpOn, false);
  });
}
