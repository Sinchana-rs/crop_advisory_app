import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sensor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/language_service.dart';
import 'login_screen.dart';
import 'irrigation_screen.dart';
import 'fertilizer_screen.dart';
import 'voice_assistant_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'crop_price_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SensorData? sensor;
  Timer? timer;
  String sensorError = "";

  @override
  void initState() {
    super.initState();
    loadSensors();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => loadSensors());
  }

  Future<void> loadSensors() async {
    try {
      final data = await SensorService.fetch();
      if (!mounted) return;
      setState(() {
        sensor = data;
        sensorError = "";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => sensorError = "Waiting for ESP32 sensor data...");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: LanguageService.lang,
      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: Color(0xffEEF6E8),
          body: Row(
            children: [
              Container(
                width: 230,
                height: double.infinity,
                color: Color(0xff102015),
                padding: EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.energy_savings_leaf,
                              color: Colors.lightGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              LanguageService.t("appName"),
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 35),

                      menuItem(context, Icons.dashboard,
                          LanguageService.t("dashboard"), null, true),

                      menuItem(context, Icons.water_drop,
                          LanguageService.t("irrigation"), IrrigationScreen(), false),

                      menuItem(context, Icons.agriculture,
                          LanguageService.t("fertilizer"), FertilizerScreen(), false),

                      menuItem(context, Icons.mic,
                          LanguageService.t("voice"), VoiceAssistantScreen(), false),

                      menuItem(context, Icons.currency_rupee,
                          LanguageService.t("prices"), CropPriceScreen(), false),

                      menuItem(context, Icons.person,
                          LanguageService.t("profile"), ProfileScreen(), false),

                      menuItem(context, Icons.settings,
                          LanguageService.t("settings"), SettingsScreen(), false),

                      SizedBox(height: 25),

                      Text(
                        LanguageService.t("language"),
                        style: TextStyle(color: Colors.white70),
                      ),

                      DropdownButton<String>(
                        value: LanguageService.lang.value,
                        dropdownColor: Color(0xff102015),
                        style: TextStyle(color: Colors.white),
                        items: [
                          DropdownMenuItem(value: "en", child: Text("English")),
                          DropdownMenuItem(value: "kn", child: Text("ಕನ್ನಡ")),
                          DropdownMenuItem(value: "hi", child: Text("हिंदी")),
                        ],
                        onChanged: (v) => LanguageService.lang.value = v!,
                      ),

                      SizedBox(height: 20),

                      InkWell(
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.white70),
                            SizedBox(width: 8),
                            Text(
                              LanguageService.t("logout"),
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService.t("welcome"),
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),

                      SizedBox(height: 5),

                      Text(
                        LanguageService.t("dashboard"),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 25),

                      Row(
                        children: [
                          statCard(LanguageService.t("soil"),
                              sensor == null ? "--" : "${sensor!.soilMoisture.toStringAsFixed(0)}%",
                              Icons.grass),
                          statCard(LanguageService.t("temp"),
                              sensor == null ? "--" : "${sensor!.temperature.toStringAsFixed(1)}°C",
                              Icons.thermostat),
                          statCard(LanguageService.t("humidity"),
                              sensor == null ? "--" : "${sensor!.humidity.toStringAsFixed(0)}%",
                              Icons.water_drop),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          statCard("Rain",
                              sensor == null ? "--" : (sensor!.rain ? "DETECTED" : "NO RAIN"),
                              Icons.umbrella),
                          statCard("NPK",
                              sensor == null ? "--" :
                              "N ${sensor!.nitrogen.toStringAsFixed(0)} / P ${sensor!.phosphorus.toStringAsFixed(0)} / K ${sensor!.potassium.toStringAsFixed(0)}",
                              Icons.science),
                          statCard("Pump",
                              sensor == null ? "--" : (sensor!.pumpOn ? "ON" : "OFF"),
                              Icons.water_drop),
                        ],
                      ),
                      if (sensorError.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(sensorError, style: TextStyle(color: Colors.orange[800])),
                      ],

                      SizedBox(height: 25),

                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                margin: EdgeInsets.all(18),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Image.network(
                                  "https://images.unsplash.com/photo-1500382017468-9049fed747ef",
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LanguageService.t("crop"),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(LanguageService.t("farmStatus")),
                                    SizedBox(height: 8),
                                    Text(
                                      LanguageService.t("good"),
                                      style: TextStyle(
                                        fontSize: 28,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                      SizedBox(height: 25),

                      Row(
                        children: [
                          featureCard(context, LanguageService.t("irrigation"),
                              Icons.water_drop, IrrigationScreen()),
                          featureCard(context, LanguageService.t("fertilizer"),
                              Icons.agriculture, FertilizerScreen()),
                          featureCard(context, LanguageService.t("voice"),
                              Icons.mic, VoiceAssistantScreen()),
                          featureCard(context, LanguageService.t("prices"),
                              Icons.currency_rupee, CropPriceScreen()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget menuItem(BuildContext context, IconData icon, String title,
      Widget? page, bool selected) {
    return InkWell(
      onTap: page == null ? null : () => openPage(context, page),
      child: Container(
        margin: EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.lightGreenAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.black : Colors.white70),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style:
                    TextStyle(color: selected ? Colors.black : Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 15),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: 32),
            SizedBox(height: 15),
            Text(title, style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget featureCard(
      BuildContext context, String title, IconData icon, Widget page) {
    return Expanded(
      child: InkWell(
        onTap: () => openPage(context, page),
        child: Container(
          height: 150,
          margin: EdgeInsets.only(right: 15),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xffDDF5D3),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.green.shade800, size: 35),
              Spacer(),
              Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}