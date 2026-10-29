import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/sensor_service.dart';
import '../services/language_service.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  Timer? _sensorTimer;

  bool liveMode = true;

  final moistureController = TextEditingController();
  final temperatureController = TextEditingController();
  final humidityController = TextEditingController();

  bool loading = false;

  String recommendation = "";
  String pumpStatus = "";
  String message = "";

  double? soilMoisture;
  double? temperature;
  double? humidity;

  @override
  void initState() {
    super.initState();

    _loadLiveSensors();

    _sensorTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadLiveSensors(),
    );
  }

  Future<void> _loadLiveSensors() async {
    try {
      final s = await SensorService.fetch();

      if (!mounted) return;

      moistureController.text =
          s.soilMoisture.toStringAsFixed(0);

      temperatureController.text =
          s.temperature.toStringAsFixed(1);

      humidityController.text =
          s.humidity.toStringAsFixed(1);

      await predictIrrigation(fromLiveSensor: true);
    } catch (_) {
      // Keep the existing screen usable if the ESP32 is offline.
    }
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();

    moistureController.dispose();
    temperatureController.dispose();
    humidityController.dispose();

    super.dispose();
  }

  // =========================================================
  // PREDICT IRRIGATION
  // =========================================================

  Future<void> predictIrrigation({
    bool fromLiveSensor = false,
  }) async {
    FocusScope.of(context).unfocus();

    if (moistureController.text.trim().isEmpty ||
        temperatureController.text.trim().isEmpty ||
        humidityController.text.trim().isEmpty) {
      showMessage(
        LanguageService.t("pleaseEnterAllValues"),
      );
      return;
    }

    final moisture =
        double.tryParse(moistureController.text.trim());

    final temp =
        double.tryParse(temperatureController.text.trim());

    final hum =
        double.tryParse(humidityController.text.trim());

    if (moisture == null ||
        temp == null ||
        hum == null) {
      showMessage(
        LanguageService.t("pleaseEnterValidValues"),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          apiBaseUrl + "/predict_irrigation",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "soil_moisture": moisture,
          "temperature": temp,
          "humidity": hum,

          // Selected language is also sent to Flask.
          "lang": LanguageService.lang.value,
        }),
      );

      debugPrint(
        "Irrigation Status: ${response.statusCode}",
      );

      debugPrint(
        "Irrigation Response: ${response.body}",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          soilMoisture =
              (data["soil_moisture"] as num?)?.toDouble();

          temperature =
              (data["temperature"] as num?)?.toDouble();

          humidity =
              (data["humidity"] as num?)?.toDouble();

          recommendation =
              data["recommendation"]?.toString() ?? "";

          pumpStatus =
              data["pump_status"]?.toString() ?? "";

          message =
              data["message"]?.toString() ?? "";

          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        showMessage(
          "${LanguageService.t("serverError")}: "
          "${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint(
        "IRRIGATION ERROR: $e",
      );

      setState(() {
        loading = false;
      });

      showMessage(
        LanguageService.t("unableToConnect"),
      );
    }
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // CLEAR
  // =========================================================

  void clearData() {
    moistureController.clear();
    temperatureController.clear();
    humidityController.clear();

    setState(() {
      recommendation = "";
      pumpStatus = "";
      message = "";

      soilMoisture = null;
      temperature = null;
      humidity = null;
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: LanguageService.lang,
      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F1),

          // =====================================================
          // APP BAR
          // =====================================================

          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,

            title: Row(
              children: [
                const Icon(
                  Icons.water_drop,
                  size: 28,
                ),

                const SizedBox(width: 10),

                Text(
                  LanguageService.t("irrigationTitle"),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // =====================================================
          // BODY
          // =====================================================

          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // =================================================
                  // HEADER
                  // =================================================

                  Center(
                    child: Column(
                      children: [

                        Container(
                          width: 80,
                          height: 80,

                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.water_drop,
                            size: 45,
                            color: Color(0xFF2E7D32),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          LanguageService.t(
                            "smartIrrigation",
                          ),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          LanguageService.t(
                            "smartIrrigationSubtitle",
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // SENSOR INPUT CARD
                  // =================================================

                  Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.05),

                          blurRadius: 15,

                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            const Icon(
                              Icons.sensors,
                              color: Color(0xFF2E7D32),
                            ),

                            const SizedBox(width: 10),

                            Text(
                              LanguageService.t(
                                "farmSensorData",
                              ),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // SOIL MOISTURE

                        inputBox(
                          LanguageService.t(
                            "moisture",
                          ),
                          LanguageService.t(
                            "enterSoilMoisture",
                          ),
                          moistureController,
                          Icons.water_drop,
                        ),

                        const SizedBox(height: 15),

                        // TEMPERATURE

                        inputBox(
                          LanguageService.t(
                            "temperature",
                          ),
                          LanguageService.t(
                            "enterTemperature",
                          ),
                          temperatureController,
                          Icons.thermostat,
                        ),

                        const SizedBox(height: 15),

                        // HUMIDITY

                        inputBox(
                          LanguageService.t(
                            "humidity",
                          ),
                          LanguageService.t(
                            "enterHumidity",
                          ),
                          humidityController,
                          Icons.cloud,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // BUTTONS
                  // =================================================

                  Row(
                    children: [

                      Expanded(
                        child: SizedBox(
                          height: 55,

                          child: ElevatedButton.icon(
                            onPressed:
                                loading
                                    ? null
                                    : predictIrrigation,

                            icon: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,

                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome,
                                  ),

                            label: Text(
                              loading
                                  ? LanguageService.t(
                                      "analyzing",
                                    )
                                  : LanguageService.t(
                                      "aiRecommendation",
                                    ),
                            ),

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF2E7D32,
                              ),

                              foregroundColor:
                                  Colors.white,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      SizedBox(
                        height: 55,

                        width: 55,

                        child: OutlinedButton(
                          onPressed: clearData,

                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                const Color(
                              0xFF2E7D32,
                            ),

                            side:
                                const BorderSide(
                              color:
                                  Color(0xFF2E7D32),
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),

                            padding: EdgeInsets.zero,
                          ),

                          child: const Icon(
                            Icons.refresh,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // RESULT
                  // =================================================

                  if (recommendation.isNotEmpty)
                    buildResultCard(),

                  const SizedBox(height: 25),

                  // =================================================
                  // INFORMATION
                  // =================================================

                  Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.green.shade50,

                      borderRadius:
                          BorderRadius.circular(15),

                      border: Border.all(
                        color:
                            Colors.green.shade100,
                      ),
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF2E7D32),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            LanguageService.t(
                              "irrigationInfo",
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // INPUT BOX
  // =========================================================

  Widget inputBox(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      decoration: InputDecoration(
        labelText: label,

        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: const Color(0xFF2E7D32),
        ),

        filled: true,

        fillColor:
            const Color(0xFFF8FAF7),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),

          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),

          borderSide: BorderSide(
            color: Colors.green.shade100,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),

          borderSide: const BorderSide(
            color: Color(0xFF2E7D32),
            width: 2,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // RESULT CARD
  // =========================================================

  Widget buildResultCard() {
    final bool pumpOn =
        pumpStatus.toUpperCase() == "ON";

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.green.shade200,
          width: 1.5,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.green.withOpacity(0.10),

            blurRadius: 15,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // TITLE

          Row(
            children: [

              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF2E7D32),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  LanguageService.t(
                    "aiIrrigationRecommendation",
                  ),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // SENSOR VALUES

          Row(
            children: [

              Expanded(
                child: sensorValue(
                  LanguageService.t(
                    "moisture",
                  ),
                  soilMoisture == null
                      ? "-"
                      : "${soilMoisture!.toStringAsFixed(0)}%",
                  Icons.water_drop,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: sensorValue(
                  LanguageService.t(
                    "temperature",
                  ),
                  temperature == null
                      ? "-"
                      : "${temperature!.toStringAsFixed(0)}°C",
                  Icons.thermostat,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: sensorValue(
                  LanguageService.t(
                    "humidity",
                  ),
                  humidity == null
                      ? "-"
                      : "${humidity!.toStringAsFixed(0)}%",
                  Icons.cloud,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(),

          const SizedBox(height: 15),

          // RECOMMENDATION

          Text(
            LanguageService.t(
              "recommendation",
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 20),

          // PUMP STATUS

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),

            decoration: BoxDecoration(
              color: pumpOn
                  ? Colors.blue.shade50
                  : Colors.grey.shade100,

              borderRadius:
                  BorderRadius.circular(14),

              border: Border.all(
                color: pumpOn
                    ? Colors.blue.shade200
                    : Colors.grey.shade300,
              ),
            ),

            child: Row(
              children: [

                Icon(
                  pumpOn
                      ? Icons.water
                      : Icons.water_drop_outlined,

                  color: pumpOn
                      ? Colors.blue.shade700
                      : Colors.grey.shade700,
                ),

                const SizedBox(width: 12),

                Text(
                  LanguageService.t(
                    "pumpStatus",
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                Text(
                  pumpStatus,

                  style: TextStyle(
                    fontWeight: FontWeight.bold,

                    color: pumpOn
                        ? Colors.blue.shade700
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // MESSAGE

          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(15),

            decoration: BoxDecoration(
              color: Colors.green.shade50,

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Icon(
                  Icons.eco,
                  color: Color(0xFF2E7D32),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    message,

                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SENSOR VALUE
  // =========================================================

  Widget sensorValue(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F1),

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            size: 22,
            color: const Color(0xFF2E7D32),
          ),

          const SizedBox(height: 6),

          Text(
            value,

            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}