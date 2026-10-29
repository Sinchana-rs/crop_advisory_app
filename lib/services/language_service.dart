import 'package:flutter/material.dart';

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

  // ============================================================
  // VOICE LANGUAGE
  // ============================================================

  static String voiceLang() {
    if (lang.value == "kn") return "kn-IN";
    if (lang.value == "hi") return "hi-IN";
    return "en-IN";
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
    if (language == "en" ||
        language == "kn" ||
        language == "hi") {
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