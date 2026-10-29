#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

// ======================================================
// PIN CONFIGURATION
// ======================================================

#define MOISTURE_PIN 34
#define RELAY_PIN 20
#define DHT_PIN 27
#define RAIN_PIN 25

#define RS485_RX 16
#define RS485_TX 17
#define RS485_DE_RE 4

#define DHT_TYPE DHT11

// ======================================================
// WIFI
// ======================================================

const char* WIFI_SSID = "Sinchana24";
const char* WIFI_PASSWORD = "12345678";

// ======================================================
// FLASK SERVER
// ======================================================

const char* SERVER_URL =
    "http://10.69.1.205:5000/sensor_data";

// ======================================================
// TIMING
// ======================================================

// Send sensor data to Flask every 1 minute
const unsigned long SENSOR_INTERVAL =
    1UL * 60UL * 1000UL;

// Check pump condition every 1 second
const unsigned long PUMP_CHECK_INTERVAL =
    1000UL;

unsigned long lastSensorUpdate = 0;
unsigned long lastPumpCheck = 0;

// ======================================================
// SOIL MOISTURE CALIBRATION
// ======================================================

const int DRY_VALUE = 2448;
const int WET_VALUE = 1925;

// ======================================================
// PUMP THRESHOLDS
// ======================================================

// Pump ON below 30%
const float PUMP_ON_THRESHOLD = 30.0;

// Pump OFF at 40% or above
const float PUMP_OFF_THRESHOLD = 40.0;

// ======================================================
// RELAY CONFIGURATION
// ======================================================
//
// YOUR RELAY IS ASSUMED TO BE ACTIVE LOW:
//
// LOW  = Pump ON
// HIGH = Pump OFF
//
// If your relay behaves opposite, change these two
// values.
//

const int RELAY_ON = LOW;
const int RELAY_OFF = HIGH;

// ======================================================
// OBJECTS
// ======================================================

DHT dht(DHT_PIN, DHT_TYPE);

HardwareSerial NPKSerial(2);

// ======================================================
// PUMP STATE
// ======================================================

bool pumpOn = false;

// ======================================================
// CONNECT WIFI
// ======================================================

bool connectWiFi() {

  Serial.println();
  Serial.println("======================================");
  Serial.println("CONNECTING TO WIFI");
  Serial.println("======================================");

  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);

  if (WiFi.status() == WL_CONNECTED) {

    Serial.println("WiFi already connected.");

    return true;
  }

  WiFi.mode(WIFI_STA);

  WiFi.disconnect();

  delay(500);

  WiFi.begin(
      WIFI_SSID,
      WIFI_PASSWORD
  );

  int attempts = 0;

  while (
      WiFi.status() != WL_CONNECTED &&
      attempts < 40
  ) {

    delay(500);

    Serial.print(".");

    attempts++;
  }

  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {

    Serial.println("======================================");
    Serial.println("******** WIFI CONNECTED ********");
    Serial.println("======================================");

    Serial.print("SSID: ");
    Serial.println(WiFi.SSID());

    Serial.print("ESP32 IP: ");
    Serial.println(WiFi.localIP());

    Serial.print("Gateway: ");
    Serial.println(WiFi.gatewayIP());

    Serial.print("Signal: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");

    Serial.println("======================================");

    return true;
  }

  Serial.println("======================================");
  Serial.println("WIFI CONNECTION FAILED!");
  Serial.print("WiFi status: ");
  Serial.println(WiFi.status());
  Serial.println("======================================");

  return false;
}

// ======================================================
// READ SOIL MOISTURE
// ======================================================

float readSoilMoisture() {

  int rawValue = analogRead(MOISTURE_PIN);

  float moisture = map(
      rawValue,
      DRY_VALUE,
      WET_VALUE,
      0,
      100
  );

  moisture = constrain(
      moisture,
      0,
      100
  );

  return moisture;
}

// ======================================================
// READ NPK
// ======================================================
//
// Currently returns 0.
// RS485 NPK Modbus reading can be added later.
//

float readNitrogen() {

  return 0.0;
}

float readPhosphorus() {

  return 0.0;
}

float readPotassium() {

  return 0.0;
}

// ======================================================
// TURN PUMP ON
// ======================================================

void turnPumpOn() {

  if (!pumpOn) {

    digitalWrite(
        RELAY_PIN,
        RELAY_ON
    );

    pumpOn = true;

    Serial.println();
    Serial.println("**************************************");
    Serial.println("PUMP TURNED ON");
    Serial.println("**************************************");
  }
}

// ======================================================
// TURN PUMP OFF
// ======================================================

void turnPumpOff() {

  if (pumpOn) {

    digitalWrite(
        RELAY_PIN,
        RELAY_OFF
    );

    pumpOn = false;

    Serial.println();
    Serial.println("**************************************");
    Serial.println("PUMP TURNED OFF");
    Serial.println("**************************************");
  }
}

// ======================================================
// AUTOMATIC PUMP CONTROL
// ======================================================
//
// Moisture < 30%
//       ↓
// Pump ON
//
// Moisture 30% - 39.9%
//       ↓
// Keep previous state
//
// Moisture >= 40%
//       ↓
// Pump OFF
//
// Rain detected
//       ↓
// Pump OFF
//
// ======================================================

void controlPump() {

  float soilMoisture =
      readSoilMoisture();

  bool rain =
      digitalRead(RAIN_PIN) == LOW;

  // ====================================================
  // RAIN DETECTED
  // ====================================================

  if (rain) {

    if (pumpOn) {

      Serial.println();
      Serial.println("RAIN DETECTED");
      Serial.println(
          "Automatically turning pump OFF."
      );

      turnPumpOff();
    }

    return;
  }

  // ====================================================
  // SOIL IS DRY
  // ====================================================

  if (
      soilMoisture <
      PUMP_ON_THRESHOLD
  ) {

    if (!pumpOn) {

      Serial.println();
      Serial.print("Soil Moisture: ");
      Serial.print(
          soilMoisture,
          1
      );
      Serial.println(" %");

      Serial.println(
          "Soil is dry."
      );

      Serial.println(
          "Turning pump ON."
      );

      turnPumpOn();
    }
  }

  // ====================================================
  // SOIL IS WET ENOUGH
  // ====================================================

  else if (
      soilMoisture >=
      PUMP_OFF_THRESHOLD
  ) {

    if (pumpOn) {

      Serial.println();
      Serial.print("Soil Moisture: ");
      Serial.print(
          soilMoisture,
          1
      );
      Serial.println(" %");

      Serial.println(
          "Soil moisture is sufficient."
      );

      Serial.println(
          "Automatically turning pump OFF."
      );

      turnPumpOff();
    }
  }

  // ====================================================
  // BETWEEN 30% AND 40%
  // ====================================================

  else {

    // Keep previous pump state.
  }
}

// ======================================================
// SEND SENSOR DATA TO FLASK
// ======================================================

void sendSensorData(
    float soilMoisture,
    float temperature,
    float humidity,
    bool rain,
    float nitrogen,
    float phosphorus,
    float potassium,
    bool currentPumpState
) {

  if (WiFi.status() != WL_CONNECTED) {

    Serial.println();
    Serial.println("WiFi disconnected.");
    Serial.println("Trying to reconnect...");

    if (!connectWiFi()) {

      Serial.println(
          "Cannot send data."
      );

      return;
    }
  }

  // ====================================================
  // CREATE JSON
  // ====================================================

  StaticJsonDocument<512> doc;

  doc["soil_moisture"] =
      soilMoisture;

  doc["temperature"] =
      temperature;

  doc["humidity"] =
      humidity;

  doc["rain"] =
      rain;

  doc["nitrogen"] =
      nitrogen;

  doc["phosphorus"] =
      phosphorus;

  doc["potassium"] =
      potassium;

  doc["pump_status"] =
      currentPumpState
          ? "ON"
          : "OFF";

  String jsonData;

  serializeJson(
      doc,
      jsonData
  );

  // ====================================================
  // PRINT JSON
  // ====================================================

  Serial.println();
  Serial.println("======================================");
  Serial.println("SENDING DATA TO SOFTWARE");
  Serial.println("======================================");

  Serial.println("JSON:");

  Serial.println(
      jsonData
  );

  // ====================================================
  // HTTP POST
  // ====================================================

  HTTPClient http;

  http.begin(
      SERVER_URL
  );

  http.addHeader(
      "Content-Type",
      "application/json"
  );

  http.setTimeout(
      10000
  );

  int httpCode =
      http.POST(jsonData);

  Serial.print(
      "Software HTTP status: "
  );

  Serial.println(
      httpCode
  );

  if (httpCode > 0) {

    String response =
        http.getString();

    Serial.println(
        "Software response:"
    );

    Serial.println(
        response
    );

  } else {

    Serial.print(
        "HTTP error: "
    );

    Serial.println(
        http.errorToString(
            httpCode
        )
    );
  }

  http.end();

  Serial.println(
      "======================================"
  );
}

// ======================================================
// READ AND SEND ALL SENSOR DATA
// ======================================================

void readAndSendSensors() {

  Serial.println();
  Serial.println("======================================");
  Serial.println("READING SENSOR DATA");
  Serial.println("======================================");

  // ====================================================
  // SOIL MOISTURE
  // ====================================================

  float soilMoisture =
      readSoilMoisture();

  // ====================================================
  // DHT
  // ====================================================

  float temperature =
      dht.readTemperature();

  float humidity =
      dht.readHumidity();

  if (isnan(temperature)) {

    temperature = 0;
  }

  if (isnan(humidity)) {

    humidity = 0;
  }

  // ====================================================
  // RAIN SENSOR
  // ====================================================

  bool rain =
      digitalRead(RAIN_PIN) == LOW;

  // ====================================================
  // NPK
  // ====================================================

  float nitrogen =
      readNitrogen();

  float phosphorus =
      readPhosphorus();

  float potassium =
      readPotassium();

  // ====================================================
  // DISPLAY
  // ====================================================

  Serial.println();
  Serial.println("========== SYSTEM STATUS ==========");

  Serial.print(
      "Soil Moisture : "
  );

  Serial.print(
      soilMoisture,
      1
  );

  Serial.println(" %");

  Serial.print(
      "Temperature    : "
  );

  Serial.print(
      temperature,
      1
  );

  Serial.println(" °C");

  Serial.print(
      "Humidity       : "
  );

  Serial.print(
      humidity,
      1
  );

  Serial.println(" %");

  Serial.print(
      "Rain           : "
  );

  if (rain) {

    Serial.println(
        "DETECTED"
    );

  } else {

    Serial.println(
        "NOT DETECTED"
    );
  }

  Serial.println();

  Serial.print(
      "Nitrogen       : "
  );

  Serial.print(
      nitrogen,
      1
  );

  Serial.println(
      " mg/kg"
  );

  Serial.print(
      "Phosphorus     : "
  );

  Serial.print(
      phosphorus,
      1
  );

  Serial.println(
      " mg/kg"
  );

  Serial.print(
      "Potassium      : "
  );

  Serial.print(
      potassium,
      1
  );

  Serial.println(
      " mg/kg"
  );

  Serial.println();

  Serial.print(
      "Pump           : "
  );

  if (pumpOn) {

    Serial.println(
        "ON"
    );

  } else {

    Serial.println(
        "OFF"
    );
  }

  Serial.println(
      "==================================="
  );

  // ====================================================
  // SEND TO FLASK
  // ====================================================

  sendSensorData(
      soilMoisture,
      temperature,
      humidity,
      rain,
      nitrogen,
      phosphorus,
      potassium,
      pumpOn
  );
}

// ======================================================
// SETUP
// ======================================================

void setup() {

  Serial.begin(
      115200
  );

  delay(1000);

  Serial.println();
  Serial.println("======================================");
  Serial.println("             AGRISENSE AI");
  Serial.println("        ESP32 SENSOR SYSTEM");
  Serial.println("======================================");

  // ====================================================
  // PINS
  // ====================================================

  pinMode(
      MOISTURE_PIN,
      INPUT
  );

  pinMode(
      RELAY_PIN,
      OUTPUT
  );

  pinMode(
      RAIN_PIN,
      INPUT
  );

  // ====================================================
  // PUMP INITIAL STATE
  // ====================================================
  //
  // IMPORTANT:
  // Active LOW relay:
  //
  // HIGH = OFF
  //

  pumpOn = false;

  digitalWrite(
      RELAY_PIN,
      RELAY_OFF
  );

  Serial.println(
      "Pump initialized: OFF"
  );

  // ====================================================
  // DHT
  // ====================================================

  dht.begin();

  // ====================================================
  // RS485
  // ====================================================

  NPKSerial.begin(
      4800,
      SERIAL_8N1,
      RS485_RX,
      RS485_TX
  );

  pinMode(
      RS485_DE_RE,
      OUTPUT
  );

  digitalWrite(
      RS485_DE_RE,
      LOW
  );

  Serial.println(
      "Sensors initialized."
  );

  // ====================================================
  // WIFI
  // ====================================================

  connectWiFi();

  // ====================================================
  // INITIAL PUMP CHECK
  // ====================================================

  controlPump();

  // ====================================================
  // FIRST SENSOR DATA
  // ====================================================

  readAndSendSensors();

  // ====================================================
  // START TIMERS
  // ====================================================

  lastSensorUpdate =
      millis();

  lastPumpCheck =
      millis();

  Serial.println();
  Serial.println("======================================");
  Serial.println(
      "PUMP CONTROL: EVERY 1 SECOND"
  );
  Serial.println(
      "SERVER UPDATE: EVERY 1 MINUTE"
  );
  Serial.println("======================================");
}

// ======================================================
// LOOP
// ======================================================

void loop() {

  // ====================================================
  // CHECK WIFI
  // ====================================================

  if (
      WiFi.status() !=
      WL_CONNECTED
  ) {

    Serial.println();
    Serial.println(
        "WiFi disconnected."
    );

    connectWiFi();
  }

  // ====================================================
  // CONTINUOUS PUMP CONTROL
  // ====================================================
  //
  // Check moisture every 1 second.
  //
  // This means the pump does NOT have to wait for
  // the 1-minute Flask update.
  //

  if (
      millis() - lastPumpCheck >=
      PUMP_CHECK_INTERVAL
  ) {

    lastPumpCheck =
        millis();

    controlPump();
  }

  // ====================================================
  // SEND DATA EVERY 1 MINUTE
  // ====================================================

  if (
      millis() - lastSensorUpdate >=
      SENSOR_INTERVAL
  ) {

    lastSensorUpdate =
        millis();

    readAndSendSensors();

    Serial.println();
    Serial.println("======================================");
    Serial.println(
        "NEXT SENSOR UPDATE IN 1 MINUTE"
    );
    Serial.println("======================================");
  }

  // ====================================================
  // SMALL DELAY
  // ====================================================

  delay(50);
}