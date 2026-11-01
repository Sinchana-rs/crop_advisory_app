import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  // ============================================================
  // CURRENT LANGUAGE
  // ============================================================
  //
  // en = English
  // kn = Kannada
  // hi = Hindi
  //
  static ValueNotifier<String> lang = ValueNotifier<String>("en");

  static const String _prefsKey = "app_language";

  static const List<String> supported = ["en", "kn", "hi"];

  // ============================================================
  // LOAD / SAVE (call once in main() before runApp)
  // ============================================================
  //
  // The saved language is restored on every app start, and every
  // later change to LanguageService.lang is saved automatically,
  // so the language is never reset to English by a restart or by
  // a screen that assigns lang.value directly.
  //

  static bool _initialised = false;

  static Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);

      if (saved != null && supported.contains(saved)) {
        lang.value = saved;
      }
    } catch (e) {
      debugPrint("LanguageService.init error: $e");
    }

    lang.addListener(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, lang.value);
      } catch (e) {
        debugPrint("LanguageService save error: $e");
      }
    });
  }

  // ============================================================
  // VOICE LANGUAGE
  // ============================================================

  static String voiceLang() => voiceLocaleFor(lang.value);

  static String voiceLocaleFor(String code) {
    if (code == "kn") return "kn-IN";
    if (code == "hi") return "hi-IN";
    return "en-IN";
  }

  // "kn-IN" -> "kn"
  static String codeFromLocale(String locale) {
    final c = locale.toLowerCase().split(RegExp(r"[-_]")).first;
    return supported.contains(c) ? c : "en";
  }

  // ============================================================
  // TRANSLATION FUNCTION
  // ============================================================

  static String t(String key) {
    return text[lang.value]?[key] ??
        text["en"]?[key] ??
        key;
  }

  // ============================================================
  // CHANGE LANGUAGE
  // ============================================================

  static void changeLanguage(String language) {
    if (supported.contains(language)) {
      lang.value = language;
    }
  }

  // ============================================================
  // ALL TRANSLATIONS
  // ============================================================

  static final Map<String, Map<String, String>> text = {
    // ============================================================
    // ENGLISH
    // ============================================================

    "en": {
      // ----------------------------------------------------------
      // GENERAL
      // ----------------------------------------------------------

      "appName": "AgriSense AI",
      "dashboard": "Dashboard",
      "welcome": "Welcome Farmer",
      "soil": "Soil Moisture",
      "temp": "Temperature",
      "humidity": "Humidity",
      "health": "Plant Health",
      "irrigation": "Smart Irrigation",
      "fertilizer": "Fertilizer Recommendation",
      "voice": "Voice Assistant",
      "prices": "Crop Prices",
      "profile": "Profile",
      "settings": "Settings",
      "logout": "Logout",
      "language": "Language",
      "crop": "Crop Field",
      "farmStatus": "Farm Status",
      "good": "Good",

      // ----------------------------------------------------------
      // COMMON
      // ----------------------------------------------------------

      "refresh": "Refresh",
      "loading": "Loading...",
      "error": "Error",
      "success": "Success",
      "save": "Save",
      "cancel": "Cancel",
      "submit": "Submit",
      "close": "Close",
      "back": "Back",
      "next": "Next",
      "continue": "Continue",
      "yes": "Yes",
      "no": "No",
      "ok": "OK",
      "select": "Select",
      "search": "Search",
      "update": "Update",
      "delete": "Delete",
      "edit": "Edit",
      "done": "Done",
      "retry": "Retry",
      "view": "View",
      "details": "Details",
      "recommendation": "Recommendation",
      "information": "Information",
      "noData": "No data available",
      "somethingWrong": "Something went wrong",

      // ----------------------------------------------------------
      // SENSOR
      // ----------------------------------------------------------

      "sensorData": "Sensor Data",
      "liveSensorData": "Live Sensor Data",
      "soilMoisture": "Soil Moisture",
      "temperature": "Temperature",
      "humidityValue": "Humidity",
      "rain": "Rain",
      "rainDetected": "Rain Detected",
      "noRain": "No Rain",
      "pumpStatus": "Pump Status",
      "pumpOn": "Pump ON",
      "pumpOff": "Pump OFF",
      "nitrogen": "Nitrogen Value",
      "phosphorus": "Phosphorus Value",
      "potassium": "Potassium Value",
      "lastUpdated": "Last Updated",

      // ----------------------------------------------------------
      // IRRIGATION
      // ----------------------------------------------------------

      "irrigationTitle": "Smart Irrigation AI",
      "moisture": "Soil Moisture %",
      "getAI": "Get AI Recommendation",
      "irrigationRecommendation":
          "Irrigation Recommendation",
      "waterNeeded": "Water Needed",
      "waterNotNeeded": "Water Not Needed",
      "startPump": "Start Pump",
      "stopPump": "Stop Pump",
      "pump": "Pump",
      "irrigationStatus": "Irrigation Status",
      "recommendedAction": "Recommended Action",

      // ----------------------------------------------------------
      // FERTILIZER - CAMEL CASE
      // ----------------------------------------------------------

      "fertilizerTitle": "Fertilizer AI",
      "cropName": "Crop Name",
      "soilType": "Soil Type",
      "soilPH": "Soil pH",
      "getFertilizer":
          "Get Fertilizer Recommendation",
      "fertilizerRecommendation":
          "Fertilizer Recommendation",
      "fertilizerName":
          "Recommended Fertilizer",
      "fertilizerUse":
          "Use of Fertilizer",
      "fertilizerBenefits":
          "Benefits",
      "fertilizerApplication":
          "Application Method",
      "fertilizerQuantity":
          "Recommended Quantity",
      "fertilizerTiming":
          "Application Timing",
      "fertilizerPrecautions":
          "Precautions",
      "enterCrop":
          "Enter crop name",
      "enterPH":
          "Enter soil pH",
      "enterValue":
          "Enter value",
      "enterSoilType":
          "Enter soil type",
      "selectSoilType":
          "Select soil type",

      // ----------------------------------------------------------
      // FERTILIZER - SNAKE CASE
      // These match your FertilizerScreen exactly.
      // ----------------------------------------------------------

      "fertilizer_recommendation":
          "Fertilizer Recommendation",

      "find_right_fertilizer":
          "Find the Right Fertilizer",

      "fertilizer_description":
          "Get an AI-based fertilizer recommendation based on your crop, soil type and soil pH.",

      "crop_name":
          "Crop Name",

      "crop_example":
          "Example: Tomato",

      "soil_type":
          "Soil Type",

      "soil_ph":
          "Soil pH",

      "ph_example":
          "Example: 6.5",

      "get_ai_fertilizer":
          "Get AI Fertilizer",

      "generating_recommendation":
          "Generating Recommendation...",

      "ai_fertilizer_recommendation":
          "AI Fertilizer Recommendation",

      "analysis_based_on":
          "Analysis Based On",

      "fertilizer_important_note":
          "Use fertilizer according to recommended quantities and local agricultural guidelines.",

      "analyzing_soil_crop":
          "Analyzing Soil & Crop",

      "agrisense_generating_fertilizer":
          "AgriSense AI is generating your fertilizer recommendation.",

      "please_enter_crop_name":
          "Please enter crop name",

      "please_select_soil_type":
          "Please select soil type",

      "please_enter_valid_ph":
          "Please enter a valid pH value",

      "ph_between_0_14":
          "pH must be between 0 and 14",

      "unable_to_generate_recommendation":
          "Unable to generate recommendation",

      "server_error":
          "Server Error",

      "cannot_connect_ai_server":
          "Cannot connect to AI server",

      "ai_taking_too_long":
          "AI is taking too long to respond",

      "ai_quota_reached":
          "AI quota has been reached",

      "api_key_problem":
          "There is a problem with the API key",

      // ----------------------------------------------------------
      // SOIL TYPES
      // ----------------------------------------------------------

      "loamy": "Loamy",
      "clay": "Clay",
      "sandy": "Sandy",
      "silty": "Silty",
      "black_soil": "Black Soil",
      "red_soil": "Red Soil",
      "alluvial_soil": "Alluvial Soil",

      // ----------------------------------------------------------
      // VOICE
      // ----------------------------------------------------------

      "voiceTitle":
          "Voice Assistant Agent",
      "startSpeaking":
          "Start Speaking",
      "stopListening":
          "Stop Listening",
      "stopVoice":
          "Stop Voice",
      "youSaid":
          "You Said:",
      "assistantReply":
          "Assistant Reply:",
      "listening":
          "Listening...",
      "processing":
          "Processing...",
      "speakNow":
          "Speak now",
      "voiceError":
          "Unable to process your voice",

      // ----------------------------------------------------------
      // PROFILE
      // ----------------------------------------------------------

      "farmerName":
          "Farmer Name",
      "email":
          "Email",
      "location":
          "Location",
      "phone":
          "Phone Number",
      "changeLanguage":
          "Change Language",
      "editProfile":
          "Edit Profile",
      "updateProfile":
          "Update Profile",
      "profileUpdated":
          "Profile updated successfully",

      "mainCrop":
          "Main Crop",
      "farmSize":
          "Farm Size",
      "profileDescription":
          "Your farming profile information",

      // ----------------------------------------------------------
      // SETTINGS
      // ----------------------------------------------------------

      "settingsTitle":
          "Settings",
      "languageSettings":
          "Language Settings",
      "selectLanguage":
          "Select Language",
      "english":
          "English",
      "kannada":
          "Kannada",
      "hindi":
          "Hindi",
      "account":
          "Account",
      "appSettings":
          "App Settings",

      // ----------------------------------------------------------
      // CROP PRICES
      // ----------------------------------------------------------

      "marketPrices":
          "Current Crop Market Prices",
      "cropPrices":
          "Crop Prices",
      "market":
          "Market",
      "price":
          "Price",
      "minimumPrice":
          "Minimum Price",
      "maximumPrice":
          "Maximum Price",
      "modalPrice":
          "Modal Price",
      "perQuintal":
          "per Quintal",
      "loadingPrices":
          "Loading crop prices...",
      "priceError":
          "Unable to load crop prices",
      "priceNote":
          "Current market prices are fetched from the government data source.",

      // ----------------------------------------------------------
      // LOGIN
      // ----------------------------------------------------------

      "login":
          "Login",
      "register":
          "Register",
      "password":
          "Password",
      "confirmPassword":
          "Confirm Password",
      "forgotPassword":
          "Forgot Password?",
      "emailID":
          "Email ID",
      "rememberMe":
          "Remember me",
      "dontHaveAccount":
          "Don't have an account? Register",
      "alreadyHaveAccount":
          "Already have an account? Login",
      "loginFailed":
          "Login failed",
      "registerFailed":
          "Registration failed",
      "accountCreated":
          "Account created successfully",
      "resetEmailSent":
          "Password reset email sent",
      "invalidEmail":
          "Please enter a valid email",
      "invalidPassword":
          "Password must be at least 6 characters",
      "passwordMismatch":
          "Passwords do not match",

      // ----------------------------------------------------------
      // DASHBOARD
      // ----------------------------------------------------------

      "currentStatus":
          "Current Status",
      "overview":
          "Overview",
      "quickActions":
          "Quick Actions",
      "viewPrices":
          "View Crop Prices",
      "checkFertilizer":
          "Check Fertilizer",
      "checkIrrigation":
          "Check Irrigation",
      "askAssistant":
          "Ask Assistant",

      // ----------------------------------------------------------
      // IRRIGATION SCREEN
      // ----------------------------------------------------------

      "smartIrrigation": "Smart Irrigation",
      "smartIrrigationSubtitle":
          "Get an AI irrigation recommendation from your farm sensor data",
      "farmSensorData": "Farm Sensor Data",
      "enterSoilMoisture": "Enter soil moisture (%)",
      "enterTemperature": "Enter temperature (°C)",
      "enterHumidity": "Enter humidity (%)",
      "aiRecommendation": "Get AI Recommendation",
      "analyzing": "Analyzing...",
      "aiIrrigationRecommendation": "AI Irrigation Recommendation",
      "pleaseEnterAllValues": "Please enter all values",
      "pleaseEnterValidValues": "Please enter valid numeric values",
      "unableToConnect": "Unable to connect to the server",
      "serverError": "Server Error",
      "irrigationInfo":
          "Recommendations are based on soil moisture, temperature and humidity. Always check your field before starting the pump.",
      "pumpState_ON": "ON",
      "pumpState_OFF": "OFF",
      "pumpState_OPTIONAL": "OPTIONAL",
      "irr_critical_rec": "Irrigation is highly required.",
      "irr_critical_msg":
          "The soil is very dry. Start irrigation immediately.",
      "irr_low_rec": "Irrigation is recommended.",
      "irr_low_msg":
          "The soil moisture is low. Provide irrigation to the crop.",
      "irr_moderate_rec": "Moderate irrigation may be required.",
      "irr_moderate_msg":
          "The soil has moderate moisture. Monitor the soil and irrigate if required.",
      "irr_sufficient_rec": "Irrigation is not required.",
      "irr_sufficient_msg":
          "The soil has sufficient moisture. Irrigation can remain OFF.",

      // ----------------------------------------------------------
      // VOICE SCREEN
      // ----------------------------------------------------------

      "voiceSubtitle":
          "Ask any farming question and listen to the answer",
      "tapMicrophone": "Tap the microphone to speak",
      "questionPlaceholder": "Your question will appear here",
      "answerPlaceholder": "The answer will appear here",
      "thinking": "Thinking...",
      "aiSpeaking": "AI is speaking...",
      "smartFarming": "Smart farming with AgriSense AI",
      "speechNotAvailable":
          "Speech recognition is not available on this device",
      "connectionError":
          "Cannot connect to the server. Please check your connection.",
      "audioUnavailable":
          "The recommendation is shown on screen, but audio could not be played.",
      "audioPreparing": "Preparing audio...",
      "quotaReached":
          "The AI service has reached its quota. Please try again later.",
      "apiKeyProblem":
          "There is a problem with the AI service configuration.",
      "voiceNoAnswer":
          "Sorry, I could not generate an answer. Please try again.",

      // ----------------------------------------------------------
      // CROP PRICE SCREEN
      // ----------------------------------------------------------

      "commodityCrop": "Crop / Commodity",
      "state": "State",
      "district": "District",
      "date": "Date",
      "minPrice": "Min Price",
      "maxPrice": "Max Price",
      "getCurrentPrices": "Get Current Prices",
      "livePricesNote":
          "Prices are fetched live from the government market data source.",

      // ----------------------------------------------------------
      // PROFILE SCREEN
      // ----------------------------------------------------------

      "editModeEnabled": "Edit mode enabled",
      "noEmail": "No email",
      "profileSaved": "Profile saved successfully",

      // ----------------------------------------------------------
      // LOGIN / SPLASH
      // ----------------------------------------------------------

      "appTagline": "Multi-Agent Crop Advisory System",
      "pleaseEnterEmail": "Please enter your email address.",
      "pleaseEnterPassword": "Please enter your password.",
      "pleaseEnterValidEmail": "Please enter a valid email address.",
      "authInvalidCredential":
          "No account found with this email or the password is incorrect.",
      "authWrongPassword": "Incorrect password. Please try again.",
      "authUserDisabled": "This account has been disabled.",
      "authTooManyRequests":
          "Too many login attempts. Please try again later.",
      "authNetworkError":
          "Network error. Please check your internet connection.",
      "authLoginFailedGeneric":
          "Login failed. Please check your email and password.",
      "somethingWentWrongTryAgain":
          "Something went wrong. Please try again.",
      "pleaseEnterNewPassword": "Please enter a password.",
      "passwordMin6":
          "Password must contain at least 6 characters.",
      "accountCreatedLogin":
          "Account created successfully. You can now login.",
      "authEmailInUse":
          "An account already exists with this email. Please login.",
      "authWeakPassword":
          "Password is too weak. Use at least 6 characters.",
      "authOperationNotAllowed":
          "Email/password registration is not enabled.",
      "authRegisterFailedGeneric":
          "Registration failed. Please try again.",
      "enterRegisteredEmail":
          "Please enter your registered email first.",
      "resetEmailSentTo": "Password reset email sent to",
      "authNoAccountEmail":
          "No account is registered with this email.",
      "authUnableSendReset": "Unable to send password reset email.",
      "sensorServerError": "Sensor server error",
      "sensorUnavailable": "Sensor data unavailable",
      // ----------------------------------------------------------
      // LOGIN / REGISTER + SENSOR WAIT (added)
      // ----------------------------------------------------------

      "auth_enter_email": "Please enter your email address.",
      "auth_enter_password": "Please enter your password.",
      "auth_enter_new_password": "Please enter a password.",
      "auth_valid_email": "Please enter a valid email address.",
      "auth_bad_credentials": "No account found with this email or the password is incorrect.",
      "auth_wrong_password": "Incorrect password. Please try again.",
      "auth_user_disabled": "This account has been disabled.",
      "auth_too_many": "Too many login attempts. Please try again later.",
      "auth_network": "Network error. Please check your internet connection.",
      "auth_login_failed": "Login failed. Please check your email and password.",
      "auth_generic": "Something went wrong. Please try again.",
      "auth_password_min6": "Password must contain at least 6 characters.",
      "auth_account_created": "Account created successfully. You can now login.",
      "auth_email_in_use": "An account already exists with this email. Please login.",
      "auth_weak_password": "Password is too weak. Use at least 6 characters.",
      "auth_op_not_allowed": "Email/password registration is not enabled in Firebase.",
      "auth_register_failed": "Registration failed. Please try again.",
      "auth_enter_registered_email": "Please enter your registered email first.",
      "auth_reset_sent": "Password reset email sent to {email}",
      "auth_no_account": "No account is registered with this email.",
      "auth_reset_failed": "Unable to send password reset email.",
      "auth_email_hint": "Email ID",
      "auth_password_hint": "Password",
      "auth_login": "Login",
      "auth_forgot": "Forgot Password?",
      "auth_register_prompt": "Don't have an account? Register",
      "waitingForSensor": "Waiting for ESP32 sensor data...",

      // Pump status labels (added)
      "pump_ON": "ON",
      "pump_OFF": "OFF",
      "pump_OPTIONAL": "OPTIONAL",
    },

    // ============================================================
    // KANNADA
    // ============================================================

    "kn": {
      // ----------------------------------------------------------
      // GENERAL
      // ----------------------------------------------------------

      "appName":
          "ಅಗ್ರಿಸೆನ್ಸ್ ಎಐ",
      "dashboard":
          "ಡ್ಯಾಶ್‌ಬೋರ್ಡ್",
      "welcome":
          "ಸ್ವಾಗತ ರೈತರೆ",
      "soil":
          "ಮಣ್ಣಿನ ತೇವಾಂಶ",
      "temp":
          "ತಾಪಮಾನ",
      "humidity":
          "ಆರ್ದ್ರತೆ",
      "health":
          "ಸಸ್ಯ ಆರೋಗ್ಯ",
      "irrigation":
          "ಸ್ಮಾರ್ಟ್ ನೀರಾವರಿ",
      "fertilizer":
          "ಗೊಬ್ಬರ ಶಿಫಾರಸು",
      "voice":
          "ಧ್ವನಿ ಸಹಾಯಕ",
      "prices":
          "ಬೆಳೆ ಬೆಲೆಗಳು",
      "profile":
          "ಪ್ರೊಫೈಲ್",
      "settings":
          "ಸೆಟ್ಟಿಂಗ್‌ಗಳು",
      "logout":
          "ಲಾಗ್ ಔಟ್",
      "language":
          "ಭಾಷೆ",
      "crop":
          "ಬೆಳೆ ಹೊಲ",
      "farmStatus":
          "ಹೊಲದ ಸ್ಥಿತಿ",
      "good":
          "ಉತ್ತಮ",

      // ----------------------------------------------------------
      // COMMON
      // ----------------------------------------------------------

      "refresh":
          "ರಿಫ್ರೆಶ್",
      "loading":
          "ಲೋಡ್ ಆಗುತ್ತಿದೆ...",
      "error":
          "ದೋಷ",
      "success":
          "ಯಶಸ್ವಿ",
      "save":
          "ಉಳಿಸಿ",
      "cancel":
          "ರದ್ದುಮಾಡಿ",
      "submit":
          "ಸಲ್ಲಿಸಿ",
      "close":
          "ಮುಚ್ಚಿ",
      "back":
          "ಹಿಂದೆ",
      "next":
          "ಮುಂದೆ",
      "continue":
          "ಮುಂದುವರಿಸಿ",
      "yes":
          "ಹೌದು",
      "no":
          "ಇಲ್ಲ",
      "ok":
          "ಸರಿ",
      "select":
          "ಆಯ್ಕೆಮಾಡಿ",
      "search":
          "ಹುಡುಕಿ",
      "update":
          "ನವೀಕರಿಸಿ",
      "delete":
          "ಅಳಿಸಿ",
      "edit":
          "ತಿದ್ದು",
      "done":
          "ಮುಗಿದಿದೆ",
      "retry":
          "ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ",
      "view":
          "ವೀಕ್ಷಿಸಿ",
      "details":
          "ವಿವರಗಳು",
      "recommendation":
          "ಶಿಫಾರಸು",
      "information":
          "ಮಾಹಿತಿ",
      "noData":
          "ಯಾವುದೇ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ",
      "somethingWrong":
          "ಏನೋ ತಪ್ಪಾಗಿದೆ",

      // ----------------------------------------------------------
      // SENSOR
      // ----------------------------------------------------------

      "sensorData":
          "ಸೆನ್ಸರ್ ಮಾಹಿತಿ",
      "liveSensorData":
          "ಲೈವ್ ಸೆನ್ಸರ್ ಮಾಹಿತಿ",
      "soilMoisture":
          "ಮಣ್ಣಿನ ತೇವಾಂಶ",
      "temperature":
          "ತಾಪಮಾನ",
      "humidityValue":
          "ಆರ್ದ್ರತೆ",
      "rain":
          "ಮಳೆ",
      "rainDetected":
          "ಮಳೆ ಪತ್ತೆಯಾಗಿದೆ",
      "noRain":
          "ಮಳೆ ಇಲ್ಲ",
      "pumpStatus":
          "ಪಂಪ್ ಸ್ಥಿತಿ",
      "pumpOn":
          "ಪಂಪ್ ಆನ್",
      "pumpOff":
          "ಪಂಪ್ ಆಫ್",
      "nitrogen":
          "ನೈಟ್ರೋಜನ್ ಮೌಲ್ಯ",
      "phosphorus":
          "ಫಾಸ್ಫರಸ್ ಮೌಲ್ಯ",
      "potassium":
          "ಪೊಟ್ಯಾಸಿಯಂ ಮೌಲ್ಯ",
      "lastUpdated":
          "ಕೊನೆಯ ನವೀಕರಣ",

      // ----------------------------------------------------------
      // IRRIGATION
      // ----------------------------------------------------------

      "irrigationTitle":
          "ಸ್ಮಾರ್ಟ್ ನೀರಾವರಿ ಎಐ",
      "moisture":
          "ಮಣ್ಣಿನ ತೇವಾಂಶ %",
      "getAI":
          "ಎಐ ಶಿಫಾರಸು ಪಡೆಯಿರಿ",
      "irrigationRecommendation":
          "ನೀರಾವರಿ ಶಿಫಾರಸು",
      "waterNeeded":
          "ನೀರು ಅಗತ್ಯವಿದೆ",
      "waterNotNeeded":
          "ನೀರು ಅಗತ್ಯವಿಲ್ಲ",
      "startPump":
          "ಪಂಪ್ ಪ್ರಾರಂಭಿಸಿ",
      "stopPump":
          "ಪಂಪ್ ನಿಲ್ಲಿಸಿ",
      "pump":
          "ಪಂಪ್",
      "irrigationStatus":
          "ನೀರಾವರಿ ಸ್ಥಿತಿ",
      "recommendedAction":
          "ಶಿಫಾರಸು ಮಾಡಿದ ಕ್ರಮ",

      // ----------------------------------------------------------
      // FERTILIZER - CAMEL CASE
      // ----------------------------------------------------------

      "fertilizerTitle":
          "ಗೊಬ್ಬರ ಎಐ",
      "cropName":
          "ಬೆಳೆ ಹೆಸರು",
      "soilType":
          "ಮಣ್ಣಿನ ಪ್ರಕಾರ",
      "soilPH":
          "ಮಣ್ಣಿನ pH",
      "getFertilizer":
          "ಗೊಬ್ಬರ ಶಿಫಾರಸು ಪಡೆಯಿರಿ",
      "fertilizerRecommendation":
          "ಗೊಬ್ಬರ ಶಿಫಾರಸು",
      "fertilizerName":
          "ಶಿಫಾರಸು ಮಾಡಿದ ಗೊಬ್ಬರ",
      "fertilizerUse":
          "ಗೊಬ್ಬರದ ಬಳಕೆ",
      "fertilizerBenefits":
          "ಪ್ರಯೋಜನಗಳು",
      "fertilizerApplication":
          "ಅನ್ವಯಿಸುವ ವಿಧಾನ",
      "fertilizerQuantity":
          "ಶಿಫಾರಸು ಮಾಡಿದ ಪ್ರಮಾಣ",
      "fertilizerTiming":
          "ಅನ್ವಯಿಸುವ ಸಮಯ",
      "fertilizerPrecautions":
          "ಮುನ್ನೆಚ್ಚರಿಕೆಗಳು",
      "enterCrop":
          "ಬೆಳೆಯ ಹೆಸರನ್ನು ನಮೂದಿಸಿ",
      "enterPH":
          "ಮಣ್ಣಿನ pH ನಮೂದಿಸಿ",
      "enterValue":
          "ಮೌಲ್ಯವನ್ನು ನಮೂದಿಸಿ",
      "enterSoilType":
          "ಮಣ್ಣಿನ ಪ್ರಕಾರ ನಮೂದಿಸಿ",
      "selectSoilType":
          "ಮಣ್ಣಿನ ಪ್ರಕಾರ ಆಯ್ಕೆಮಾಡಿ",

      // ----------------------------------------------------------
      // FERTILIZER - SNAKE CASE
      // ----------------------------------------------------------

      "fertilizer_recommendation":
          "ಗೊಬ್ಬರ ಶಿಫಾರಸು",

      "find_right_fertilizer":
          "ಸರಿಯಾದ ಗೊಬ್ಬರವನ್ನು ಕಂಡುಹಿಡಿಯಿರಿ",

      "fertilizer_description":
          "ನಿಮ್ಮ ಬೆಳೆ, ಮಣ್ಣಿನ ಪ್ರಕಾರ ಮತ್ತು ಮಣ್ಣಿನ pH ಆಧರಿಸಿ AI ಮೂಲಕ ಗೊಬ್ಬರ ಶಿಫಾರಸು ಪಡೆಯಿರಿ.",

      "crop_name":
          "ಬೆಳೆಯ ಹೆಸರು",

      "crop_example":
          "ಉದಾಹರಣೆ: ಟೊಮ್ಯಾಟೊ",

      "soil_type":
          "ಮಣ್ಣಿನ ಪ್ರಕಾರ",

      "soil_ph":
          "ಮಣ್ಣಿನ pH",

      "ph_example":
          "ಉದಾಹರಣೆ: 6.5",

      "get_ai_fertilizer":
          "AI ಗೊಬ್ಬರ ಶಿಫಾರಸು ಪಡೆಯಿರಿ",

      "generating_recommendation":
          "ಶಿಫಾರಸು ರಚಿಸಲಾಗುತ್ತಿದೆ...",

      "ai_fertilizer_recommendation":
          "AI ಗೊಬ್ಬರ ಶಿಫಾರಸು",

      "analysis_based_on":
          "ವಿಶ್ಲೇಷಣೆಯ ಆಧಾರ",

      "fertilizer_important_note":
          "ಶಿಫಾರಸು ಮಾಡಿದ ಪ್ರಮಾಣ ಮತ್ತು ಸ್ಥಳೀಯ ಕೃಷಿ ಮಾರ್ಗಸೂಚಿಗಳ ಪ್ರಕಾರ ಗೊಬ್ಬರವನ್ನು ಬಳಸಿ.",

      "analyzing_soil_crop":
          "ಮಣ್ಣು ಮತ್ತು ಬೆಳೆಯನ್ನು ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ",

      "agrisense_generating_fertilizer":
          "AgriSense AI ನಿಮ್ಮ ಗೊಬ್ಬರ ಶಿಫಾರಸನ್ನು ರಚಿಸುತ್ತಿದೆ.",

      "please_enter_crop_name":
          "ದಯವಿಟ್ಟು ಬೆಳೆಯ ಹೆಸರನ್ನು ನಮೂದಿಸಿ",

      "please_select_soil_type":
          "ದಯವಿಟ್ಟು ಮಣ್ಣಿನ ಪ್ರಕಾರವನ್ನು ಆಯ್ಕೆಮಾಡಿ",

      "please_enter_valid_ph":
          "ದಯವಿಟ್ಟು ಸರಿಯಾದ pH ಮೌಲ್ಯವನ್ನು ನಮೂದಿಸಿ",

      "ph_between_0_14":
          "pH 0 ರಿಂದ 14 ರ ನಡುವೆ ಇರಬೇಕು",

      "unable_to_generate_recommendation":
          "ಶಿಫಾರಸು ರಚಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ",

      "server_error":
          "ಸರ್ವರ್ ದೋಷ",

      "cannot_connect_ai_server":
          "AI ಸರ್ವರ್‌ಗೆ ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ",

      "ai_taking_too_long":
          "AI ಉತ್ತರಿಸಲು ಹೆಚ್ಚು ಸಮಯ ತೆಗೆದುಕೊಳ್ಳುತ್ತಿದೆ",

      "ai_quota_reached":
          "AI ಕೋಟಾ ಮುಗಿದಿದೆ",

      "api_key_problem":
          "API ಕೀ ಸಮಸ್ಯೆ ಇದೆ",

      // ----------------------------------------------------------
      // SOIL TYPES
      // ----------------------------------------------------------

      "loamy":
          "ಲೋಮಿ ಮಣ್ಣು",
      "clay":
          "ಜೇಡಿ ಮಣ್ಣು",
      "sandy":
          "ಮರಳು ಮಣ್ಣು",
      "silty":
          "ಹೂಳು ಮಣ್ಣು",
      "black_soil":
          "ಕಪ್ಪು ಮಣ್ಣು",
      "red_soil":
          "ಕೆಂಪು ಮಣ್ಣು",
      "alluvial_soil":
          "ಮೆಕ್ಕಲು ಮಣ್ಣು",

      // ----------------------------------------------------------
      // VOICE
      // ----------------------------------------------------------

      "voiceTitle":
          "ಧ್ವನಿ ಸಹಾಯಕ ಏಜೆಂಟ್",
      "startSpeaking":
          "ಮಾತನಾಡಲು ಪ್ರಾರಂಭಿಸಿ",
      "stopListening":
          "ಕೇಳುವುದನ್ನು ನಿಲ್ಲಿಸಿ",
      "stopVoice":
          "ಧ್ವನಿ ನಿಲ್ಲಿಸಿ",
      "youSaid":
          "ನೀವು ಹೇಳಿದ್ದು:",
      "assistantReply":
          "ಸಹಾಯಕನ ಉತ್ತರ:",
      "listening":
          "ಕೇಳಲಾಗುತ್ತಿದೆ...",
      "processing":
          "ಪ್ರಕ್ರಿಯೆಗೊಳಿಸಲಾಗುತ್ತಿದೆ...",
      "speakNow":
          "ಈಗ ಮಾತನಾಡಿ",
      "voiceError":
          "ನಿಮ್ಮ ಧ್ವನಿಯನ್ನು ಪ್ರಕ್ರಿಯೆಗೊಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ",

      // ----------------------------------------------------------
      // PROFILE
      // ----------------------------------------------------------

      "farmerName":
          "ರೈತನ ಹೆಸರು",
      "email":
          "ಇಮೇಲ್",
      "location":
          "ಸ್ಥಳ",
      "phone":
          "ಫೋನ್ ಸಂಖ್ಯೆ",
      "changeLanguage":
          "ಭಾಷೆ ಬದಲಿಸಿ",
      "editProfile":
          "ಪ್ರೊಫೈಲ್ ತಿದ್ದು",
      "updateProfile":
          "ಪ್ರೊಫೈಲ್ ನವೀಕರಿಸಿ",
      "profileUpdated":
          "ಪ್ರೊಫೈಲ್ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ",

      "mainCrop":
          "ಮುಖ್ಯ ಬೆಳೆ",
      "farmSize":
          "ಹೊಲದ ವಿಸ್ತೀರ್ಣ",
      "profileDescription":
          "ನಿಮ್ಮ ಕೃಷಿ ಪ್ರೊಫೈಲ್ ಮಾಹಿತಿ",

      // ----------------------------------------------------------
      // SETTINGS
      // ----------------------------------------------------------

      "settingsTitle":
          "ಸೆಟ್ಟಿಂಗ್‌ಗಳು",
      "languageSettings":
          "ಭಾಷಾ ಸೆಟ್ಟಿಂಗ್‌ಗಳು",
      "selectLanguage":
          "ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ",
      "english":
          "ಇಂಗ್ಲಿಷ್",
      "kannada":
          "ಕನ್ನಡ",
      "hindi":
          "ಹಿಂದಿ",
      "account":
          "ಖಾತೆ",
      "appSettings":
          "ಆಪ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳು",

      // ----------------------------------------------------------
      // CROP PRICES
      // ----------------------------------------------------------

      "marketPrices":
          "ಪ್ರಸ್ತುತ ಬೆಳೆ ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು",
      "cropPrices":
          "ಬೆಳೆ ಬೆಲೆಗಳು",
      "market":
          "ಮಾರುಕಟ್ಟೆ",
      "price":
          "ಬೆಲೆ",
      "minimumPrice":
          "ಕನಿಷ್ಠ ಬೆಲೆ",
      "maximumPrice":
          "ಗರಿಷ್ಠ ಬೆಲೆ",
      "modalPrice":
          "ಮೋಡಲ್ ಬೆಲೆ",
      "perQuintal":
          "ಪ್ರತಿ ಕ್ವಿಂಟಲ್‌ಗೆ",
      "loadingPrices":
          "ಬೆಳೆ ಬೆಲೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...",
      "priceError":
          "ಬೆಳೆ ಬೆಲೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ",
      "priceNote":
          "ಪ್ರಸ್ತುತ ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳನ್ನು ಸರ್ಕಾರಿ ಡೇಟಾ ಮೂಲದಿಂದ ಪಡೆಯಲಾಗುತ್ತದೆ.",

      // ----------------------------------------------------------
      // LOGIN
      // ----------------------------------------------------------

      "login":
          "ಲಾಗಿನ್",
      "register":
          "ನೋಂದಣಿ",
      "password":
          "ಪಾಸ್‌ವರ್ಡ್",
      "confirmPassword":
          "ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ",
      "forgotPassword":
          "ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿರುವಿರಾ?",
      "emailID":
          "ಇಮೇಲ್ ಐಡಿ",
      "rememberMe":
          "ನನ್ನನ್ನು ನೆನಪಿನಲ್ಲಿಡಿ",
      "dontHaveAccount":
          "ಖಾತೆ ಇಲ್ಲವೇ? ನೋಂದಣಿ ಮಾಡಿ",
      "alreadyHaveAccount":
          "ಈಗಾಗಲೇ ಖಾತೆ ಇದೆಯೇ? ಲಾಗಿನ್ ಮಾಡಿ",
      "loginFailed":
          "ಲಾಗಿನ್ ವಿಫಲವಾಗಿದೆ",
      "registerFailed":
          "ನೋಂದಣಿ ವಿಫಲವಾಗಿದೆ",
      "accountCreated":
          "ಖಾತೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ರಚಿಸಲಾಗಿದೆ",
      "resetEmailSent":
          "ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಇಮೇಲ್ ಕಳುಹಿಸಲಾಗಿದೆ",
      "invalidEmail":
          "ದಯವಿಟ್ಟು ಸರಿಯಾದ ಇಮೇಲ್ ನಮೂದಿಸಿ",
      "invalidPassword":
          "ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳನ್ನು ಹೊಂದಿರಬೇಕು",
      "passwordMismatch":
          "ಪಾಸ್‌ವರ್ಡ್‌ಗಳು ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ",

      // ----------------------------------------------------------
      // DASHBOARD
      // ----------------------------------------------------------

      "currentStatus":
          "ಪ್ರಸ್ತುತ ಸ್ಥಿತಿ",
      "overview":
          "ಅವಲೋಕನ",
      "quickActions":
          "ತ್ವರಿತ ಕ್ರಮಗಳು",
      "viewPrices":
          "ಬೆಳೆ ಬೆಲೆಗಳನ್ನು ವೀಕ್ಷಿಸಿ",
      "checkFertilizer":
          "ಗೊಬ್ಬರ ಪರಿಶೀಲಿಸಿ",
      "checkIrrigation":
          "ನೀರಾವರಿ ಪರಿಶೀಲಿಸಿ",
      "askAssistant":
          "ಸಹಾಯಕರನ್ನು ಕೇಳಿ",

      // ----------------------------------------------------------
      // IRRIGATION SCREEN
      // ----------------------------------------------------------

      "smartIrrigation": "ಸ್ಮಾರ್ಟ್ ನೀರಾವರಿ",
      "smartIrrigationSubtitle":
          "ನಿಮ್ಮ ಹೊಲದ ಸೆನ್ಸರ್ ಮಾಹಿತಿಯಿಂದ ಎಐ ನೀರಾವರಿ ಶಿಫಾರಸು ಪಡೆಯಿರಿ",
      "farmSensorData": "ಹೊಲದ ಸೆನ್ಸರ್ ಮಾಹಿತಿ",
      "enterSoilMoisture": "ಮಣ್ಣಿನ ತೇವಾಂಶ (%) ನಮೂದಿಸಿ",
      "enterTemperature": "ತಾಪಮಾನ (°C) ನಮೂದಿಸಿ",
      "enterHumidity": "ಆರ್ದ್ರತೆ (%) ನಮೂದಿಸಿ",
      "aiRecommendation": "ಎಐ ಶಿಫಾರಸು ಪಡೆಯಿರಿ",
      "analyzing": "ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ...",
      "aiIrrigationRecommendation": "ಎಐ ನೀರಾವರಿ ಶಿಫಾರಸು",
      "pleaseEnterAllValues": "ದಯವಿಟ್ಟು ಎಲ್ಲಾ ಮೌಲ್ಯಗಳನ್ನು ನಮೂದಿಸಿ",
      "pleaseEnterValidValues":
          "ದಯವಿಟ್ಟು ಸರಿಯಾದ ಸಂಖ್ಯೆಯ ಮೌಲ್ಯಗಳನ್ನು ನಮೂದಿಸಿ",
      "unableToConnect": "ಸರ್ವರ್‌ಗೆ ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ",
      "serverError": "ಸರ್ವರ್ ದೋಷ",
      "irrigationInfo":
          "ಶಿಫಾರಸುಗಳು ಮಣ್ಣಿನ ತೇವಾಂಶ, ತಾಪಮಾನ ಮತ್ತು ಆರ್ದ್ರತೆಯನ್ನು ಆಧರಿಸಿವೆ. ಪಂಪ್ ಪ್ರಾರಂಭಿಸುವ ಮೊದಲು ನಿಮ್ಮ ಹೊಲವನ್ನು ಪರಿಶೀಲಿಸಿ.",
      "pumpState_ON": "ಆನ್",
      "pumpState_OFF": "ಆಫ್",
      "pumpState_OPTIONAL": "ಐಚ್ಛಿಕ",
      "irr_critical_rec": "ನೀರಾವರಿ ತುಂಬಾ ಅಗತ್ಯವಿದೆ.",
      "irr_critical_msg":
          "ಮಣ್ಣು ತುಂಬಾ ಒಣಗಿದೆ. ತಕ್ಷಣ ನೀರಾವರಿ ಪ್ರಾರಂಭಿಸಿ.",
      "irr_low_rec": "ನೀರಾವರಿ ಮಾಡಲು ಶಿಫಾರಸು ಮಾಡಲಾಗಿದೆ.",
      "irr_low_msg":
          "ಮಣ್ಣಿನ ತೇವಾಂಶ ಕಡಿಮೆಯಿದೆ. ಬೆಳೆಗೆ ನೀರು ಒದಗಿಸಿ.",
      "irr_moderate_rec": "ಸ್ವಲ್ಪ ನೀರಾವರಿ ಬೇಕಾಗಬಹುದು.",
      "irr_moderate_msg":
          "ಮಣ್ಣಿನಲ್ಲಿ ಮಧ್ಯಮ ತೇವಾಂಶವಿದೆ. ಮಣ್ಣನ್ನು ಗಮನಿಸಿ, ಅಗತ್ಯವಿದ್ದರೆ ನೀರು ಹಾಕಿ.",
      "irr_sufficient_rec": "ನೀರಾವರಿ ಅಗತ್ಯವಿಲ್ಲ.",
      "irr_sufficient_msg":
          "ಮಣ್ಣಿನಲ್ಲಿ ಸಾಕಷ್ಟು ತೇವಾಂಶವಿದೆ. ನೀರಾವರಿ ಆಫ್ ಆಗಿರಬಹುದು.",

      // ----------------------------------------------------------
      // VOICE SCREEN
      // ----------------------------------------------------------

      "voiceSubtitle":
          "ಯಾವುದೇ ಕೃಷಿ ಪ್ರಶ್ನೆ ಕೇಳಿ ಮತ್ತು ಉತ್ತರವನ್ನು ಆಲಿಸಿ",
      "tapMicrophone": "ಮಾತನಾಡಲು ಮೈಕ್ರೋಫೋನ್ ಒತ್ತಿ",
      "questionPlaceholder": "ನಿಮ್ಮ ಪ್ರಶ್ನೆ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ",
      "answerPlaceholder": "ಉತ್ತರ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ",
      "thinking": "ಯೋಚಿಸಲಾಗುತ್ತಿದೆ...",
      "aiSpeaking": "ಎಐ ಮಾತನಾಡುತ್ತಿದೆ...",
      "smartFarming": "ಅಗ್ರಿಸೆನ್ಸ್ ಎಐ ಜೊತೆ ಸ್ಮಾರ್ಟ್ ಕೃಷಿ",
      "speechNotAvailable":
          "ಈ ಸಾಧನದಲ್ಲಿ ಧ್ವನಿ ಗುರುತಿಸುವಿಕೆ ಲಭ್ಯವಿಲ್ಲ",
      "connectionError":
          "ಸರ್ವರ್‌ಗೆ ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ. ನಿಮ್ಮ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ.",
      "audioUnavailable":
          "ಶಿಫಾರಸು ಪರದೆಯಲ್ಲಿ ಕಾಣಿಸುತ್ತಿದೆ, ಆದರೆ ಆಡಿಯೋ ಪ್ಲೇ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.",
      "audioPreparing": "ಆಡಿಯೋ ಸಿದ್ಧಪಡಿಸಲಾಗುತ್ತಿದೆ...",
      "quotaReached":
          "ಎಐ ಸೇವೆಯ ಮಿತಿ ಮುಗಿದಿದೆ. ದಯವಿಟ್ಟು ನಂತರ ಪ್ರಯತ್ನಿಸಿ.",
      "apiKeyProblem": "ಎಐ ಸೇವೆಯ ಸಂರಚನೆಯಲ್ಲಿ ಸಮಸ್ಯೆ ಇದೆ.",
      "voiceNoAnswer":
          "ಕ್ಷಮಿಸಿ, ಉತ್ತರ ರಚಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",

      // ----------------------------------------------------------
      // CROP PRICE SCREEN
      // ----------------------------------------------------------

      "commodityCrop": "ಬೆಳೆ / ಸರಕು",
      "state": "ರಾಜ್ಯ",
      "district": "ಜಿಲ್ಲೆ",
      "date": "ದಿನಾಂಕ",
      "minPrice": "ಕನಿಷ್ಠ ಬೆಲೆ",
      "maxPrice": "ಗರಿಷ್ಠ ಬೆಲೆ",
      "getCurrentPrices": "ಪ್ರಸ್ತುತ ಬೆಲೆಗಳನ್ನು ಪಡೆಯಿರಿ",
      "livePricesNote":
          "ಬೆಲೆಗಳನ್ನು ಸರ್ಕಾರಿ ಮಾರುಕಟ್ಟೆ ಡೇಟಾ ಮೂಲದಿಂದ ನೇರವಾಗಿ ಪಡೆಯಲಾಗುತ್ತದೆ.",

      // ----------------------------------------------------------
      // PROFILE SCREEN
      // ----------------------------------------------------------

      "editModeEnabled": "ತಿದ್ದುಪಡಿ ಮೋಡ್ ಸಕ್ರಿಯವಾಗಿದೆ",
      "noEmail": "ಇಮೇಲ್ ಇಲ್ಲ",
      "profileSaved": "ಪ್ರೊಫೈಲ್ ಯಶಸ್ವಿಯಾಗಿ ಉಳಿಸಲಾಗಿದೆ",

      // ----------------------------------------------------------
      // LOGIN / SPLASH
      // ----------------------------------------------------------

      "appTagline": "ಬಹು-ಏಜೆಂಟ್ ಬೆಳೆ ಸಲಹಾ ವ್ಯವಸ್ಥೆ",
      "pleaseEnterEmail": "ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ.",
      "pleaseEnterPassword": "ದಯವಿಟ್ಟು ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ.",
      "pleaseEnterValidEmail":
          "ದಯವಿಟ್ಟು ಸರಿಯಾದ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ.",
      "authInvalidCredential":
          "ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಖಾತೆ ಸಿಗಲಿಲ್ಲ ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್ ತಪ್ಪಾಗಿದೆ.",
      "authWrongPassword":
          "ಪಾಸ್‌ವರ್ಡ್ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
      "authUserDisabled": "ಈ ಖಾತೆಯನ್ನು ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ.",
      "authTooManyRequests":
          "ಹಲವು ಲಾಗಿನ್ ಪ್ರಯತ್ನಗಳು. ದಯವಿಟ್ಟು ನಂತರ ಪ್ರಯತ್ನಿಸಿ.",
      "authNetworkError":
          "ನೆಟ್‌ವರ್ಕ್ ದೋಷ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ.",
      "authLoginFailedGeneric":
          "ಲಾಗಿನ್ ವಿಫಲವಾಗಿದೆ. ನಿಮ್ಮ ಇಮೇಲ್ ಮತ್ತು ಪಾಸ್‌ವರ್ಡ್ ಪರಿಶೀಲಿಸಿ.",
      "somethingWentWrongTryAgain":
          "ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
      "pleaseEnterNewPassword": "ದಯವಿಟ್ಟು ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ.",
      "passwordMin6":
          "ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳನ್ನು ಹೊಂದಿರಬೇಕು.",
      "accountCreatedLogin":
          "ಖಾತೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ರಚಿಸಲಾಗಿದೆ. ಈಗ ಲಾಗಿನ್ ಮಾಡಬಹುದು.",
      "authEmailInUse":
          "ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಈಗಾಗಲೇ ಖಾತೆ ಇದೆ. ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಮಾಡಿ.",
      "authWeakPassword":
          "ಪಾಸ್‌ವರ್ಡ್ ದುರ್ಬಲವಾಗಿದೆ. ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳನ್ನು ಬಳಸಿ.",
      "authOperationNotAllowed":
          "ಇಮೇಲ್/ಪಾಸ್‌ವರ್ಡ್ ನೋಂದಣಿ ಸಕ್ರಿಯವಾಗಿಲ್ಲ.",
      "authRegisterFailedGeneric":
          "ನೋಂದಣಿ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
      "enterRegisteredEmail":
          "ದಯವಿಟ್ಟು ಮೊದಲು ನೋಂದಾಯಿತ ಇಮೇಲ್ ನಮೂದಿಸಿ.",
      "resetEmailSentTo": "ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಇಮೇಲ್ ಕಳುಹಿಸಲಾಗಿದೆ:",
      "authNoAccountEmail":
          "ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಯಾವುದೇ ಖಾತೆ ನೋಂದಾಯಿಸಲಾಗಿಲ್ಲ.",
      "authUnableSendReset":
          "ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಇಮೇಲ್ ಕಳುಹಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.",
      "sensorServerError": "ಸೆನ್ಸರ್ ಸರ್ವರ್ ದೋಷ",
      "sensorUnavailable": "ಸೆನ್ಸರ್ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ",
      // ----------------------------------------------------------
      // LOGIN / REGISTER + SENSOR WAIT (added)
      // ----------------------------------------------------------

      "auth_enter_email": "ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ.",
      "auth_enter_password": "ದಯವಿಟ್ಟು ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ.",
      "auth_enter_new_password": "ದಯವಿಟ್ಟು ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ.",
      "auth_valid_email": "ದಯವಿಟ್ಟು ಮಾನ್ಯವಾದ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ.",
      "auth_bad_credentials": "ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಯಾವುದೇ ಖಾತೆ ಕಂಡುಬಂದಿಲ್ಲ ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್ ತಪ್ಪಾಗಿದೆ.",
      "auth_wrong_password": "ಪಾಸ್‌ವರ್ಡ್ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
      "auth_user_disabled": "ಈ ಖಾತೆಯನ್ನು ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ.",
      "auth_too_many": "ಹಲವು ಬಾರಿ ಲಾಗಿನ್ ಪ್ರಯತ್ನಿಸಲಾಗಿದೆ. ದಯವಿಟ್ಟು ನಂತರ ಪ್ರಯತ್ನಿಸಿ.",
      "auth_network": "ನೆಟ್‌ವರ್ಕ್ ದೋಷ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ.",
      "auth_login_failed": "ಲಾಗಿನ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಮೇಲ್ ಮತ್ತು ಪಾಸ್‌ವರ್ಡ್ ಪರಿಶೀಲಿಸಿ.",
      "auth_generic": "ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
      "auth_password_min6": "ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳನ್ನು ಹೊಂದಿರಬೇಕು.",
      "auth_account_created": "ಖಾತೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ರಚಿಸಲಾಗಿದೆ. ಈಗ ನೀವು ಲಾಗಿನ್ ಮಾಡಬಹುದು.",
      "auth_email_in_use": "ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಈಗಾಗಲೇ ಖಾತೆ ಇದೆ. ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಮಾಡಿ.",
      "auth_weak_password": "ಪಾಸ್‌ವರ್ಡ್ ತುಂಬಾ ದುರ್ಬಲವಾಗಿದೆ. ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳನ್ನು ಬಳಸಿ.",
      "auth_op_not_allowed": "ಇಮೇಲ್/ಪಾಸ್‌ವರ್ಡ್ ನೋಂದಣಿಯನ್ನು Firebase ನಲ್ಲಿ ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿಲ್ಲ.",
      "auth_register_failed": "ನೋಂದಣಿ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
      "auth_enter_registered_email": "ದಯವಿಟ್ಟು ಮೊದಲು ನೋಂದಾಯಿತ ಇಮೇಲ್ ನಮೂದಿಸಿ.",
      "auth_reset_sent": "{email} ಗೆ ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಇಮೇಲ್ ಕಳುಹಿಸಲಾಗಿದೆ",
      "auth_no_account": "ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಯಾವುದೇ ಖಾತೆ ನೋಂದಾಯಿಸಲಾಗಿಲ್ಲ.",
      "auth_reset_failed": "ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸುವ ಇಮೇಲ್ ಕಳುಹಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.",
      "auth_email_hint": "ಇಮೇಲ್ ಐಡಿ",
      "auth_password_hint": "ಪಾಸ್‌ವರ್ಡ್",
      "auth_login": "ಲಾಗಿನ್",
      "auth_forgot": "ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿರಾ?",
      "auth_register_prompt": "ಖಾತೆ ಇಲ್ಲವೇ? ನೋಂದಣಿ ಮಾಡಿ",
      "waitingForSensor": "ESP32 ಸೆನ್ಸರ್ ಡೇಟಾಗಾಗಿ ಕಾಯಲಾಗುತ್ತಿದೆ...",

      // Pump status labels (added)
      "pump_ON": "ಆನ್",
      "pump_OFF": "ಆಫ್",
      "pump_OPTIONAL": "ಐಚ್ಛಿಕ",
    },

    // ============================================================
    // HINDI
    // ============================================================

    "hi": {
      // ----------------------------------------------------------
      // GENERAL
      // ----------------------------------------------------------

      "appName":
          "एग्रीसेंस एआई",
      "dashboard":
          "डैशबोर्ड",
      "welcome":
          "स्वागत है किसान",
      "soil":
          "मिट्टी की नमी",
      "temp":
          "तापमान",
      "humidity":
          "नमी",
      "health":
          "पौधे का स्वास्थ्य",
      "irrigation":
          "स्मार्ट सिंचाई",
      "fertilizer":
          "खाद सिफारिश",
      "voice":
          "वॉइस असिस्टेंट",
      "prices":
          "फसल कीमतें",
      "profile":
          "प्रोफाइल",
      "settings":
          "सेटिंग्स",
      "logout":
          "लॉग आउट",
      "language":
          "भाषा",
      "crop":
          "फसल खेत",
      "farmStatus":
          "खेत की स्थिति",
      "good":
          "अच्छा",

      // ----------------------------------------------------------
      // COMMON
      // ----------------------------------------------------------

      "refresh":
          "रिफ्रेश",
      "loading":
          "लोड हो रहा है...",
      "error":
          "त्रुटि",
      "success":
          "सफल",
      "save":
          "सहेजें",
      "cancel":
          "रद्द करें",
      "submit":
          "जमा करें",
      "close":
          "बंद करें",
      "back":
          "पीछे",
      "next":
          "आगे",
      "continue":
          "जारी रखें",
      "yes":
          "हाँ",
      "no":
          "नहीं",
      "ok":
          "ठीक है",
      "select":
          "चुनें",
      "search":
          "खोजें",
      "update":
          "अपडेट करें",
      "delete":
          "हटाएं",
      "edit":
          "संपादित करें",
      "done":
          "पूर्ण",
      "retry":
          "पुनः प्रयास करें",
      "view":
          "देखें",
      "details":
          "विवरण",
      "recommendation":
          "सिफारिश",
      "information":
          "जानकारी",
      "noData":
          "कोई जानकारी उपलब्ध नहीं है",
      "somethingWrong":
          "कुछ गलत हो गया",

      // ----------------------------------------------------------
      // SENSOR
      // ----------------------------------------------------------

      "sensorData":
          "सेंसर डेटा",
      "liveSensorData":
          "लाइव सेंसर डेटा",
      "soilMoisture":
          "मिट्टी की नमी",
      "temperature":
          "तापमान",
      "humidityValue":
          "नमी",
      "rain":
          "बारिश",
      "rainDetected":
          "बारिश का पता चला",
      "noRain":
          "बारिश नहीं है",
      "pumpStatus":
          "पंप की स्थिति",
      "pumpOn":
          "पंप चालू",
      "pumpOff":
          "पंप बंद",
      "nitrogen":
          "नाइट्रोजन मान",
      "phosphorus":
          "फॉस्फोरस मान",
      "potassium":
          "पोटैशियम मान",
      "lastUpdated":
          "अंतिम अपडेट",

      // ----------------------------------------------------------
      // IRRIGATION
      // ----------------------------------------------------------

      "irrigationTitle":
          "स्मार्ट सिंचाई एआई",
      "moisture":
          "मिट्टी की नमी %",
      "getAI":
          "एआई सुझाव प्राप्त करें",
      "irrigationRecommendation":
          "सिंचाई की सिफारिश",
      "waterNeeded":
          "पानी की आवश्यकता है",
      "waterNotNeeded":
          "पानी की आवश्यकता नहीं है",
      "startPump":
          "पंप शुरू करें",
      "stopPump":
          "पंप बंद करें",
      "pump":
          "पंप",
      "irrigationStatus":
          "सिंचाई की स्थिति",
      "recommendedAction":
          "अनुशंसित कार्रवाई",

      // ----------------------------------------------------------
      // FERTILIZER - CAMEL CASE
      // ----------------------------------------------------------

      "fertilizerTitle":
          "खाद एआई",
      "cropName":
          "फसल का नाम",
      "soilType":
          "मिट्टी का प्रकार",
      "soilPH":
          "मिट्टी pH",
      "getFertilizer":
          "खाद सुझाव प्राप्त करें",
      "fertilizerRecommendation":
          "खाद की सिफारिश",
      "fertilizerName":
          "अनुशंसित खाद",
      "fertilizerUse":
          "खाद का उपयोग",
      "fertilizerBenefits":
          "लाभ",
      "fertilizerApplication":
          "उपयोग की विधि",
      "fertilizerQuantity":
          "अनुशंसित मात्रा",
      "fertilizerTiming":
          "उपयोग का समय",
      "fertilizerPrecautions":
          "सावधानियां",
      "enterCrop":
          "फसल का नाम दर्ज करें",
      "enterPH":
          "मिट्टी का pH दर्ज करें",
      "enterValue":
          "मान दर्ज करें",
      "enterSoilType":
          "मिट्टी का प्रकार दर्ज करें",
      "selectSoilType":
          "मिट्टी का प्रकार चुनें",

      // ----------------------------------------------------------
      // FERTILIZER - SNAKE CASE
      // ----------------------------------------------------------

      "fertilizer_recommendation":
          "खाद की सिफारिश",

      "find_right_fertilizer":
          "सही खाद खोजें",

      "fertilizer_description":
          "आपकी फसल, मिट्टी के प्रकार और मिट्टी के pH के आधार पर AI द्वारा खाद की सिफारिश प्राप्त करें।",

      "crop_name":
          "फसल का नाम",

      "crop_example":
          "उदाहरण: टमाटर",

      "soil_type":
          "मिट्टी का प्रकार",

      "soil_ph":
          "मिट्टी का pH",

      "ph_example":
          "उदाहरण: 6.5",

      "get_ai_fertilizer":
          "AI खाद सिफारिश प्राप्त करें",

      "generating_recommendation":
          "सिफारिश तैयार की जा रही है...",

      "ai_fertilizer_recommendation":
          "AI खाद सिफारिश",

      "analysis_based_on":
          "विश्लेषण का आधार",

      "fertilizer_important_note":
          "अनुशंसित मात्रा और स्थानीय कृषि दिशानिर्देशों के अनुसार खाद का उपयोग करें।",

      "analyzing_soil_crop":
          "मिट्टी और फसल का विश्लेषण किया जा रहा है",

      "agrisense_generating_fertilizer":
          "AgriSense AI आपकी खाद की सिफारिश तैयार कर रहा है।",

      "please_enter_crop_name":
          "कृपया फसल का नाम दर्ज करें",

      "please_select_soil_type":
          "कृपया मिट्टी का प्रकार चुनें",

      "please_enter_valid_ph":
          "कृपया सही pH मान दर्ज करें",

      "ph_between_0_14":
          "pH 0 से 14 के बीच होना चाहिए",

      "unable_to_generate_recommendation":
          "सिफारिश तैयार नहीं की जा सकी",

      "server_error":
          "सर्वर त्रुटि",

      "cannot_connect_ai_server":
          "AI सर्वर से कनेक्ट नहीं हो पा रहा है",

      "ai_taking_too_long":
          "AI उत्तर देने में बहुत समय ले रहा है",

      "ai_quota_reached":
          "AI कोटा समाप्त हो गया है",

      "api_key_problem":
          "API कुंजी में समस्या है",

      // ----------------------------------------------------------
      // SOIL TYPES
      // ----------------------------------------------------------

      "loamy":
          "दोमट मिट्टी",
      "clay":
          "चिकनी मिट्टी",
      "sandy":
          "रेतीली मिट्टी",
      "silty":
          "गाद वाली मिट्टी",
      "black_soil":
          "काली मिट्टी",
      "red_soil":
          "लाल मिट्टी",
      "alluvial_soil":
          "जलोढ़ मिट्टी",

      // ----------------------------------------------------------
      // VOICE
      // ----------------------------------------------------------

      "voiceTitle":
          "वॉइस असिस्टेंट एजेंट",
      "startSpeaking":
          "बोलना शुरू करें",
      "stopListening":
          "सुनना बंद करें",
      "stopVoice":
          "आवाज़ बंद करें",
      "youSaid":
          "आपने कहा:",
      "assistantReply":
          "सहायक का उत्तर:",
      "listening":
          "सुना जा रहा है...",
      "processing":
          "प्रक्रिया जारी है...",
      "speakNow":
          "अब बोलें",
      "voiceError":
          "आपकी आवाज़ को संसाधित नहीं किया जा सका",

      // ----------------------------------------------------------
      // PROFILE
      // ----------------------------------------------------------

      "farmerName":
          "किसान का नाम",
      "email":
          "ईमेल",
      "location":
          "स्थान",
      "phone":
          "फोन नंबर",
      "changeLanguage":
          "भाषा बदलें",
      "editProfile":
          "प्रोफाइल संपादित करें",
      "updateProfile":
          "प्रोफाइल अपडेट करें",
      "profileUpdated":
          "प्रोफाइल सफलतापूर्वक अपडेट हो गई",

      "mainCrop":
          "मुख्य फसल",
      "farmSize":
          "खेत का क्षेत्रफल",
      "profileDescription":
          "आपकी कृषि प्रोफाइल की जानकारी",

      // ----------------------------------------------------------
      // SETTINGS
      // ----------------------------------------------------------

      "settingsTitle":
          "सेटिंग्स",
      "languageSettings":
          "भाषा सेटिंग्स",
      "selectLanguage":
          "भाषा चुनें",
      "english":
          "अंग्रेज़ी",
      "kannada":
          "कन्नड़",
      "hindi":
          "हिंदी",
      "account":
          "खाता",
      "appSettings":
          "ऐप सेटिंग्स",

      // ----------------------------------------------------------
      // CROP PRICES
      // ----------------------------------------------------------

      "marketPrices":
          "वर्तमान फसल बाजार कीमतें",
      "cropPrices":
          "फसल कीमतें",
      "market":
          "बाज़ार",
      "price":
          "कीमत",
      "minimumPrice":
          "न्यूनतम कीमत",
      "maximumPrice":
          "अधिकतम कीमत",
      "modalPrice":
          "मॉडल कीमत",
      "perQuintal":
          "प्रति क्विंटल",
      "loadingPrices":
          "फसल की कीमतें लोड हो रही हैं...",
      "priceError":
          "फसल की कीमतें लोड नहीं हो सकीं",
      "priceNote":
          "वर्तमान बाजार कीमतें सरकारी डेटा स्रोत से प्राप्त की जाती हैं।",

      // ----------------------------------------------------------
      // LOGIN
      // ----------------------------------------------------------

      "login":
          "लॉगिन",
      "register":
          "रजिस्टर",
      "password":
          "पासवर्ड",
      "confirmPassword":
          "पासवर्ड की पुष्टि करें",
      "forgotPassword":
          "पासवर्ड भूल गए?",
      "emailID":
          "ईमेल आईडी",
      "rememberMe":
          "मुझे याद रखें",
      "dontHaveAccount":
          "खाता नहीं है? रजिस्टर करें",
      "alreadyHaveAccount":
          "पहले से खाता है? लॉगिन करें",
      "loginFailed":
          "लॉगिन विफल हुआ",
      "registerFailed":
          "रजिस्ट्रेशन विफल हुआ",
      "accountCreated":
          "खाता सफलतापूर्वक बनाया गया",
      "resetEmailSent":
          "पासवर्ड रीसेट ईमेल भेजा गया",
      "invalidEmail":
          "कृपया सही ईमेल दर्ज करें",
      "invalidPassword":
          "पासवर्ड कम से कम 6 अक्षरों का होना चाहिए",
      "passwordMismatch":
          "पासवर्ड मेल नहीं खाते",

      // ----------------------------------------------------------
      // DASHBOARD
      // ----------------------------------------------------------

      "currentStatus":
          "वर्तमान स्थिति",
      "overview":
          "अवलोकन",
      "quickActions":
          "त्वरित कार्रवाई",
      "viewPrices":
          "फसल की कीमतें देखें",
      "checkFertilizer":
          "खाद की जांच करें",
      "checkIrrigation":
          "सिंचाई की जांच करें",
      "askAssistant":
          "सहायक से पूछें",

      // ----------------------------------------------------------
      // IRRIGATION SCREEN
      // ----------------------------------------------------------

      "smartIrrigation": "स्मार्ट सिंचाई",
      "smartIrrigationSubtitle":
          "अपने खेत के सेंसर डेटा से एआई सिंचाई सिफारिश पाएं",
      "farmSensorData": "खेत का सेंसर डेटा",
      "enterSoilMoisture": "मिट्टी की नमी (%) दर्ज करें",
      "enterTemperature": "तापमान (°C) दर्ज करें",
      "enterHumidity": "आर्द्रता (%) दर्ज करें",
      "aiRecommendation": "एआई सिफारिश पाएं",
      "analyzing": "विश्लेषण हो रहा है...",
      "aiIrrigationRecommendation": "एआई सिंचाई सिफारिश",
      "pleaseEnterAllValues": "कृपया सभी मान दर्ज करें",
      "pleaseEnterValidValues": "कृपया सही संख्यात्मक मान दर्ज करें",
      "unableToConnect": "सर्वर से कनेक्ट नहीं हो सका",
      "serverError": "सर्वर त्रुटि",
      "irrigationInfo":
          "सिफारिशें मिट्टी की नमी, तापमान और आर्द्रता पर आधारित हैं। पंप चालू करने से पहले अपना खेत जरूर जांचें।",
      "pumpState_ON": "चालू",
      "pumpState_OFF": "बंद",
      "pumpState_OPTIONAL": "वैकल्पिक",
      "irr_critical_rec": "सिंचाई की बहुत आवश्यकता है।",
      "irr_critical_msg":
          "मिट्टी बहुत सूखी है। तुरंत सिंचाई शुरू करें।",
      "irr_low_rec": "सिंचाई करने की सिफारिश की जाती है।",
      "irr_low_msg":
          "मिट्टी में नमी कम है। फसल को पानी दें।",
      "irr_moderate_rec": "थोड़ी सिंचाई की आवश्यकता हो सकती है।",
      "irr_moderate_msg":
          "मिट्टी में मध्यम नमी है। मिट्टी पर नज़र रखें और जरूरत हो तो सिंचाई करें।",
      "irr_sufficient_rec": "सिंचाई की आवश्यकता नहीं है।",
      "irr_sufficient_msg":
          "मिट्टी में पर्याप्त नमी है। सिंचाई बंद रह सकती है।",

      // ----------------------------------------------------------
      // VOICE SCREEN
      // ----------------------------------------------------------

      "voiceSubtitle":
          "कोई भी खेती का सवाल पूछें और जवाब सुनें",
      "tapMicrophone": "बोलने के लिए माइक्रोफोन दबाएं",
      "questionPlaceholder": "आपका सवाल यहाँ दिखाई देगा",
      "answerPlaceholder": "जवाब यहाँ दिखाई देगा",
      "thinking": "सोच रहा है...",
      "aiSpeaking": "एआई बोल रहा है...",
      "smartFarming": "एग्रीसेंस एआई के साथ स्मार्ट खेती",
      "speechNotAvailable":
          "इस डिवाइस पर आवाज़ पहचान उपलब्ध नहीं है",
      "connectionError":
          "सर्वर से कनेक्ट नहीं हो पा रहा है। कृपया अपना कनेक्शन जांचें।",
      "audioUnavailable":
          "सिफारिश स्क्रीन पर दिखाई गई है, लेकिन ऑडियो नहीं चल सका।",
      "audioPreparing": "ऑडियो तैयार हो रहा है...",
      "quotaReached":
          "एआई सेवा की सीमा पूरी हो गई है। कृपया बाद में प्रयास करें।",
      "apiKeyProblem": "एआई सेवा के कॉन्फ़िगरेशन में समस्या है।",
      "voiceNoAnswer":
          "क्षमा करें, जवाब नहीं बन सका। कृपया फिर से प्रयास करें।",

      // ----------------------------------------------------------
      // CROP PRICE SCREEN
      // ----------------------------------------------------------

      "commodityCrop": "फसल / वस्तु",
      "state": "राज्य",
      "district": "जिला",
      "date": "तारीख",
      "minPrice": "न्यूनतम कीमत",
      "maxPrice": "अधिकतम कीमत",
      "getCurrentPrices": "वर्तमान कीमतें देखें",
      "livePricesNote":
          "कीमतें सरकारी मंडी डेटा स्रोत से सीधे ली जाती हैं।",

      // ----------------------------------------------------------
      // PROFILE SCREEN
      // ----------------------------------------------------------

      "editModeEnabled": "संपादन मोड चालू है",
      "noEmail": "कोई ईमेल नहीं",
      "profileSaved": "प्रोफाइल सफलतापूर्वक सहेजी गई",

      // ----------------------------------------------------------
      // LOGIN / SPLASH
      // ----------------------------------------------------------

      "appTagline": "मल्टी-एजेंट फसल सलाहकार प्रणाली",
      "pleaseEnterEmail": "कृपया अपना ईमेल पता दर्ज करें।",
      "pleaseEnterPassword": "कृपया अपना पासवर्ड दर्ज करें।",
      "pleaseEnterValidEmail": "कृपया सही ईमेल पता दर्ज करें।",
      "authInvalidCredential":
          "इस ईमेल से कोई खाता नहीं मिला या पासवर्ड गलत है।",
      "authWrongPassword": "पासवर्ड गलत है। कृपया फिर से प्रयास करें।",
      "authUserDisabled": "यह खाता बंद कर दिया गया है।",
      "authTooManyRequests":
          "बहुत अधिक लॉगिन प्रयास। कृपया बाद में प्रयास करें।",
      "authNetworkError":
          "नेटवर्क त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।",
      "authLoginFailedGeneric":
          "लॉगिन विफल हुआ। कृपया अपना ईमेल और पासवर्ड जांचें।",
      "somethingWentWrongTryAgain":
          "कुछ गलत हो गया। कृपया फिर से प्रयास करें।",
      "pleaseEnterNewPassword": "कृपया पासवर्ड दर्ज करें।",
      "passwordMin6":
          "पासवर्ड में कम से कम 6 अक्षर होने चाहिए।",
      "accountCreatedLogin":
          "खाता सफलतापूर्वक बन गया। अब आप लॉगिन कर सकते हैं।",
      "authEmailInUse":
          "इस ईमेल से पहले से खाता मौजूद है। कृपया लॉगिन करें।",
      "authWeakPassword":
          "पासवर्ड कमज़ोर है। कम से कम 6 अक्षरों का उपयोग करें।",
      "authOperationNotAllowed":
          "ईमेल/पासवर्ड रजिस्ट्रेशन चालू नहीं है।",
      "authRegisterFailedGeneric":
          "रजिस्ट्रेशन विफल हुआ। कृपया फिर से प्रयास करें।",
      "enterRegisteredEmail":
          "कृपया पहले अपना पंजीकृत ईमेल दर्ज करें।",
      "resetEmailSentTo": "पासवर्ड रीसेट ईमेल भेजा गया:",
      "authNoAccountEmail":
          "इस ईमेल से कोई खाता पंजीकृत नहीं है।",
      "authUnableSendReset":
          "पासवर्ड रीसेट ईमेल नहीं भेजा जा सका।",
      "sensorServerError": "सेंसर सर्वर त्रुटि",
      "sensorUnavailable": "सेंसर डेटा उपलब्ध नहीं है",
      // ----------------------------------------------------------
      // LOGIN / REGISTER + SENSOR WAIT (added)
      // ----------------------------------------------------------

      "auth_enter_email": "कृपया अपना ईमेल पता दर्ज करें।",
      "auth_enter_password": "कृपया अपना पासवर्ड दर्ज करें।",
      "auth_enter_new_password": "कृपया पासवर्ड दर्ज करें।",
      "auth_valid_email": "कृपया मान्य ईमेल पता दर्ज करें।",
      "auth_bad_credentials": "इस ईमेल से कोई खाता नहीं मिला या पासवर्ड गलत है।",
      "auth_wrong_password": "पासवर्ड गलत है। कृपया फिर से प्रयास करें।",
      "auth_user_disabled": "यह खाता अक्षम कर दिया गया है।",
      "auth_too_many": "लॉगिन के बहुत अधिक प्रयास हुए। कृपया बाद में पुनः प्रयास करें।",
      "auth_network": "नेटवर्क त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।",
      "auth_login_failed": "लॉगिन विफल रहा। कृपया अपना ईमेल और पासवर्ड जांचें।",
      "auth_generic": "कुछ गलत हो गया। कृपया फिर से प्रयास करें।",
      "auth_password_min6": "पासवर्ड में कम से कम 6 अक्षर होने चाहिए।",
      "auth_account_created": "खाता सफलतापूर्वक बन गया। अब आप लॉगिन कर सकते हैं।",
      "auth_email_in_use": "इस ईमेल से पहले से खाता मौजूद है। कृपया लॉगिन करें।",
      "auth_weak_password": "पासवर्ड बहुत कमजोर है। कम से कम 6 अक्षर उपयोग करें।",
      "auth_op_not_allowed": "Firebase में ईमेल/पासवर्ड पंजीकरण सक्षम नहीं है।",
      "auth_register_failed": "पंजीकरण विफल रहा। कृपया फिर से प्रयास करें।",
      "auth_enter_registered_email": "कृपया पहले अपना पंजीकृत ईमेल दर्ज करें।",
      "auth_reset_sent": "पासवर्ड रीसेट ईमेल {email} पर भेज दिया गया है",
      "auth_no_account": "इस ईमेल से कोई खाता पंजीकृत नहीं है।",
      "auth_reset_failed": "पासवर्ड रीसेट ईमेल भेजा नहीं जा सका।",
      "auth_email_hint": "ईमेल आईडी",
      "auth_password_hint": "पासवर्ड",
      "auth_login": "लॉगिन",
      "auth_forgot": "पासवर्ड भूल गए?",
      "auth_register_prompt": "खाता नहीं है? रजिस्टर करें",
      "waitingForSensor": "ESP32 सेंसर डेटा की प्रतीक्षा है...",

      // Pump status labels (added)
      "pump_ON": "चालू",
      "pump_OFF": "बंद",
      "pump_OPTIONAL": "वैकल्पिक",
    },
  };
}

// ============================================================
// LANGUAGE BUILDER
// ============================================================
//
// This automatically rebuilds the screen whenever the language
// is changed.
//
// Example:
//
// LanguageBuilder(
//   builder: (context) {
//     return Text(
//       LanguageService.t("dashboard"),
//     );
//   },
// )
//
// ============================================================

class LanguageBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const LanguageBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.lang,
      builder: (context, language, child) {
        return builder(context);
      },
    );
  }
}