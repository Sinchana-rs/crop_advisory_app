import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/language_service.dart';
import '../services/sensor_service.dart';

// ============================================================
// FLASK SERVER
// ============================================================


// ============================================================
// FERTILIZER SCREEN
// ============================================================

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

// ============================================================
// STATE
// ============================================================

class _FertilizerScreenState extends State<FertilizerScreen> {
  // ----------------------------------------------------------
  // CONTROLLERS
  // ----------------------------------------------------------

  final TextEditingController cropController =
      TextEditingController();

  final TextEditingController phController =
      TextEditingController();

  // ----------------------------------------------------------
  // SOIL TYPE
  // ----------------------------------------------------------

  String? selectedSoilType;

  final List<String> soilTypes = [
    "Loamy",
    "Clay",
    "Sandy",
    "Silty",
    "Black Soil",
    "Red Soil",
    "Alluvial Soil",
  ];

  // ----------------------------------------------------------
  // AI RESULT
  // ----------------------------------------------------------

  String aiRecommendation = "";

  bool showResult = false;

  bool isLoading = false;

  // Increases on every request / language change so a late answer
  // written in the previous language is never shown.
  int _requestId = 0;
  String _lastLang = LanguageService.lang.value;

  @override
  void initState() {
    super.initState();
    LanguageService.lang.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (LanguageService.lang.value == _lastLang) return;
    _lastLang = LanguageService.lang.value;

    if (!mounted) return;

    // The shown recommendation was written in the old language:
    // ask the server again so it matches the new language.
    if (showResult || isLoading) {
      getRecommendation();
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    LanguageService.lang.removeListener(_onLanguageChanged);
    _requestId++;
    cropController.dispose();
    phController.dispose();
    super.dispose();
  }

  // ==========================================================
  // GET AI FERTILIZER RECOMMENDATION
  // ==========================================================

  Future<void> getRecommendation() async {
    final crop = cropController.text.trim();

    final soil = selectedSoilType;

    final ph = double.tryParse(
      phController.text.trim(),
    );

    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (crop.isEmpty) {
      showError(
        LanguageService.t("please_enter_crop_name"),
      );
      return;
    }

    if (soil == null) {
      showError(
        LanguageService.t("please_select_soil_type"),
      );
      return;
    }

    if (ph == null) {
      showError(
        LanguageService.t("please_enter_valid_ph"),
      );
      return;
    }

    if (ph < 0 || ph > 14) {
      showError(
        LanguageService.t("ph_between_0_14"),
      );
      return;
    }

    // --------------------------------------------------------
    // SHOW LOADING
    // --------------------------------------------------------

    final int myRequest = ++_requestId;

    setState(() {
      isLoading = true;
      showResult = false;
      aiRecommendation = "";
    });

    try {
      print(
        "Sending fertilizer request to Flask...",
      );

      print(
        "Crop: $crop",
      );

      print(
        "Soil: $soil",
      );

      print(
        "pH: $ph",
      );

      print(
        "Language: ${LanguageService.lang.value}",
      );

      // ------------------------------------------------------
      // CALL FLASK
      // ------------------------------------------------------

      final response = await http
          .post(
            Uri.parse(
              "$apiBaseUrl/predict_fertilizer",
            ),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "crop": crop,
              "soil_type": soil,
              "ph": ph,

              // LANGUAGE
              // This allows Flask/AI to know which language
              // the recommendation should be generated in.
              "lang": LanguageService.lang.value,
            }),
          )
          .timeout(
            const Duration(
              seconds: 60,
            ),
          );

      print(
        "Flask status: ${response.statusCode}",
      );

      print(
        "Flask response: ${response.body}",
      );

      // ------------------------------------------------------
      // RESPONSE
      // ------------------------------------------------------

      // A newer request (e.g. after a language change) replaced this one.
      if (!mounted || myRequest != _requestId) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body);

        if (data["success"] == true) {
          final recommendation =
              data["recommendation"] ??
              data["answer"] ??
              "";

          if (recommendation
              .toString()
              .trim()
              .isEmpty) {
            throw Exception(
              LanguageService.t(
                "unable_to_generate_recommendation",
              ),
            );
          }

          setState(() {
            aiRecommendation =
                recommendation.toString();

            showResult = true;
          });
        } else {
          // Never show the server's own (English) error text.
          throw Exception(
            _serverErrorMessage(
              data["error_type"]?.toString(),
              response.statusCode,
            ),
          );
        }
      } else {
        // ----------------------------------------------------
        // SERVER ERROR
        // ----------------------------------------------------

        String message =
            _serverErrorMessage(null, response.statusCode);

        try {
          final data =
              jsonDecode(response.body);

          message = _serverErrorMessage(
            data["error_type"]?.toString(),
            response.statusCode,
          );
        } catch (_) {}

        throw Exception(message);
      }
    } catch (e) {
      print(
        "FERTILIZER ERROR: $e",
      );

      if (!mounted || myRequest != _requestId) return;

      setState(() {
        showResult = false;
      });

      showError(
        getFriendlyErrorMessage(e),
      );
    } finally {
      if (mounted && myRequest == _requestId) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // SERVER ERROR -> TRANSLATED MESSAGE
  // ==========================================================

  String _serverErrorMessage(String? type, int status) {
    if (type == "quota") {
      return LanguageService.t("ai_quota_reached");
    }

    if (type == "api_key") {
      return LanguageService.t("api_key_problem");
    }

    return "${LanguageService.t("server_error")}: $status";
  }

  // ==========================================================
  // FRIENDLY ERROR MESSAGE
  // ==========================================================

  String getFriendlyErrorMessage(
    Object error,
  ) {
    final message =
        error.toString();

    if (message.contains("SocketException") ||
        message.contains("ClientException") ||
        message.contains("Failed to fetch")) {
      return LanguageService.t(
        "cannot_connect_ai_server",
      );
    }

    if (message.contains(
      "TimeoutException",
    )) {
      return LanguageService.t(
        "ai_taking_too_long",
      );
    }

    if (message.contains(
      "quota",
    )) {
      return LanguageService.t(
        "ai_quota_reached",
      );
    }

    if (message.contains(
      "API key",
    )) {
      return LanguageService.t(
        "api_key_problem",
      );
    }

    return message.replaceFirst(
      "Exception: ",
      "",
    );
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  void showError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor:
            Colors.red.shade700,
        duration:
            const Duration(
          seconds: 4,
        ),
      ),
    );
  }

  // ==========================================================
  // RESULT CARD
  // ==========================================================

  Widget recommendationCard() {
    if (!showResult ||
        aiRecommendation.trim().isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        top: 25,
      ),
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                Colors.green.withOpacity(
              0.12,
            ),
            blurRadius: 15,
            offset:
                const Offset(
              0,
              6,
            ),
          ),
        ],
        border:
            Border.all(
          color:
              Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // HEADER
          // --------------------------------------------------

          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Colors.green.shade100,
                child: Icon(
                  Icons.auto_awesome,
                  color:
                      Colors.green.shade800,
                  size: 28,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  LanguageService.t(
                    "ai_fertilizer_recommendation",
                  ),
                  style:
                      const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // --------------------------------------------------
          // INPUT SUMMARY
          // --------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(15),
            decoration:
                BoxDecoration(
              color:
                  Colors.green.shade50,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.t(
                    "analysis_based_on",
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.green.shade800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  "${LanguageService.t("crop")}: "
                  "${cropController.text.trim()}",
                  style:
                      const TextStyle(
                    fontSize: 14,
                  ),
                ),

                Text(
                  "${LanguageService.t("soil")}: "
                  "${getSoilTranslation(selectedSoilType ?? "")}",
                  style:
                      const TextStyle(
                    fontSize: 14,
                  ),
                ),

                Text(
                  "${LanguageService.t("soil_ph")}: "
                  "${phController.text.trim()}",
                  style:
                      const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // --------------------------------------------------
          // AI RESPONSE
          // --------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(18),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffF5FAF4,
              ),
              borderRadius:
                  BorderRadius.circular(16),
              border:
                  Border.all(
                color:
                    Colors.green.shade100,
              ),
            ),
            child: SelectableText(
              aiRecommendation,
              style:
                  const TextStyle(
                fontSize: 15,
                height: 1.65,
                color:
                    Colors.black87,
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // --------------------------------------------------
          // IMPORTANT NOTE
          // --------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(15),
            decoration:
                BoxDecoration(
              color:
                  Colors.orange.shade50,
              borderRadius:
                  BorderRadius.circular(14),
              border:
                  Border.all(
                color:
                    Colors.orange.shade100,
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 21,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    LanguageService.t(
                      "fertilizer_important_note",
                    ),
                    style:
                        const TextStyle(
                      fontSize: 13,
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

  // ==========================================================
  // LOADING CARD
  // ==========================================================

  Widget loadingCard() {
    if (!isLoading) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        top: 25,
      ),
      padding:
          const EdgeInsets.all(25),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              Colors.green.shade100,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 5,
          ),

          CircularProgressIndicator(
            color:
                Colors.green.shade700,
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            LanguageService.t(
              "analyzing_soil_crop",
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
              color:
                  Colors.green.shade800,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            LanguageService.t(
              "agrisense_generating_fertilizer",
            ),
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return ValueListenableBuilder(
      valueListenable:
          LanguageService.lang,

      builder:
          (context, value, child) {
        return Scaffold(
          backgroundColor:
              const Color(
            0xffF3F9F1,
          ),

          // --------------------------------------------------
          // APP BAR
          // --------------------------------------------------

          appBar: AppBar(
            title: Text(
              LanguageService.t(
                "fertilizer_recommendation",
              ),
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            backgroundColor:
                const Color(
              0xff2E7D32,
            ),

            foregroundColor:
                Colors.white,
          ),

          // --------------------------------------------------
          // BODY
          // --------------------------------------------------

          body: SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ------------------------------------------------
                // HEADING
                // ------------------------------------------------

                Text(
                  LanguageService.t(
                    "find_right_fertilizer",
                  ),
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.green.shade800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  LanguageService.t(
                    "fertilizer_description",
                  ),
                  style:
                      const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // ------------------------------------------------
                // CROP NAME
                // ------------------------------------------------

                TextField(
                  controller:
                      cropController,

                  textCapitalization:
                      TextCapitalization.words,

                  decoration:
                      InputDecoration(
                    labelText:
                        LanguageService.t(
                      "crop_name",
                    ),

                    hintText:
                        LanguageService.t(
                      "crop_example",
                    ),

                    prefixIcon:
                        Icon(
                      Icons.grass,
                      color:
                          Colors.green.shade700,
                    ),

                    filled: true,

                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.green.shade100,
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.green.shade600,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // ------------------------------------------------
                // SOIL TYPE
                // ------------------------------------------------

                DropdownButtonFormField<String>(
                  value:
                      selectedSoilType,

                  decoration:
                      InputDecoration(
                    labelText:
                        LanguageService.t(
                      "soil_type",
                    ),

                    prefixIcon:
                        Icon(
                      Icons.landscape,
                      color:
                          Colors.green.shade700,
                    ),

                    filled: true,

                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.green.shade100,
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.green.shade600,
                        width: 2,
                      ),
                    ),
                  ),

                  items:
                      soilTypes.map(
                    (soil) {
                      return DropdownMenuItem<String>(
                        value:
                            soil,

                        child: Text(
                          getSoilTranslation(
                            soil,
                          ),
                        ),
                      );
                    },
                  ).toList(),

                  onChanged:
                      isLoading
                          ? null
                          : (value) {
                              setState(() {
                                selectedSoilType =
                                    value;
                              });
                            },
                ),

                const SizedBox(
                  height: 18,
                ),

                // ------------------------------------------------
                // SOIL pH
                // ------------------------------------------------

                TextField(
                  controller:
                      phController,

                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),

                  decoration:
                      InputDecoration(
                    labelText:
                        LanguageService.t(
                      "soil_ph",
                    ),

                    hintText:
                        LanguageService.t(
                      "ph_example",
                    ),

                    prefixIcon:
                        Icon(
                      Icons.science,
                      color:
                          Colors.green.shade700,
                    ),

                    filled: true,

                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.green.shade100,
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.green.shade600,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // ------------------------------------------------
                // AI BUTTON
                // ------------------------------------------------

                SizedBox(
                  width:
                      double.infinity,

                  height:
                      55,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        isLoading
                            ? null
                            : getRecommendation,

                    icon:
                        const Icon(
                      Icons.auto_awesome,
                    ),

                    label:
                        Text(
                      isLoading
                          ? LanguageService.t(
                              "generating_recommendation",
                            )
                          : LanguageService.t(
                              "get_ai_fertilizer",
                            ),

                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xff2E7D32,
                      ),

                      foregroundColor:
                          Colors.white,

                      disabledBackgroundColor:
                          Colors.green.shade300,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),

                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                loadingCard(),

                // ------------------------------------------------
                // AI RESULT
                // ------------------------------------------------

                recommendationCard(),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // SOIL TYPE TRANSLATION
  // ==========================================================

  String getSoilTranslation(
    String soil,
  ) {
    switch (soil) {
      case "Loamy":
        return LanguageService.t(
          "loamy",
        );

      case "Clay":
        return LanguageService.t(
          "clay",
        );

      case "Sandy":
        return LanguageService.t(
          "sandy",
        );

      case "Silty":
        return LanguageService.t(
          "silty",
        );

      case "Black Soil":
        return LanguageService.t(
          "black_soil",
        );

      case "Red Soil":
        return LanguageService.t(
          "red_soil",
        );

      case "Alluvial Soil":
        return LanguageService.t(
          "alluvial_soil",
        );

      default:
        return soil;
    }
  }
}