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

// Result of one NPK sensor read. Declared here (before any
// function) so the Arduino auto-generated prototypes can see it.
struct NPKReading {
  bool valid;
  uint16_t nitrogen;
  uint16_t phosphorus;
  uint16_t potassium;
  const char* error;
};

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
// READ NPK (RS485 / MODBUS RTU)
// ======================================================
//
// Reads N, P and K from the RS485 NPK sensor with a
// Modbus RTU "read holding registers" request.
//
// The register map below is the one used by the common
// 3-in-1 / 7-in-1 RS485 NPK probes (slave 0x01,
// registers 0x001E, 0x001F, 0x0020 = N, P, K in mg/kg).
// CHECK IT AGAINST YOUR SENSOR'S DATASHEET. If your
// probe uses another address, baud rate or register map,
// change only the constants here.
//
// A failed read is reported as invalid. It is NEVER sent
// as 0, so the app can tell "no reading" from "0 mg/kg".
//

const uint8_t  NPK_SLAVE_ADDRESS = 0x01;
const uint16_t NPK_FIRST_REGISTER = 0x001E;
const uint16_t NPK_REGISTER_COUNT = 3;
const uint16_t NPK_MAX_VALID_VALUE = 1999;
const unsigned long NPK_RESPONSE_TIMEOUT_MS = 600;
const int NPK_MAX_ATTEMPTS = 2;

uint16_t modbusCRC16(
    const uint8_t* data,
    size_t length
) {

  uint16_t crc = 0xFFFF;

  for (size_t i = 0; i < length; i++) {

    crc ^= data[i];

    for (int bit = 0; bit < 8; bit++) {

      if (crc & 0x0001) {

        crc = (crc >> 1) ^ 0xA001;

      } else {

        crc >>= 1;
      }
    }
  }

  return crc;
}

void printHexBytes(
    const char* label,
    const uint8_t* data,
    size_t length
) {

  Serial.print(label);

  for (size_t i = 0; i < length; i++) {

    if (data[i] < 0x10) {

      Serial.print("0");
    }

    Serial.print(data[i], HEX);
    Serial.print(" ");
  }

  Serial.println();
}

// One request/response attempt.
// Returns nullptr on success, otherwise an error text.
const char* npkTryRead(NPKReading &out) {

  // ---- build request: addr, 0x03, reg hi/lo, count hi/lo, CRC lo/hi
  uint8_t request[8];

  request[0] = NPK_SLAVE_ADDRESS;
  request[1] = 0x03;
  request[2] = NPK_FIRST_REGISTER >> 8;
  request[3] = NPK_FIRST_REGISTER & 0xFF;
  request[4] = NPK_REGISTER_COUNT >> 8;
  request[5] = NPK_REGISTER_COUNT & 0xFF;

  uint16_t requestCrc = modbusCRC16(request, 6);

  request[6] = requestCrc & 0xFF;
  request[7] = requestCrc >> 8;

  // ---- throw away stale bytes
  while (NPKSerial.available()) {

    NPKSerial.read();
  }

  // ---- transmit (DE/RE high = driver enabled)
  digitalWrite(RS485_DE_RE, HIGH);
  delayMicroseconds(200);

  NPKSerial.write(request, sizeof(request));
  NPKSerial.flush();

  delayMicroseconds(200);

  // ---- receive (DE/RE low = receiver enabled)
  digitalWrite(RS485_DE_RE, LOW);

  printHexBytes("NPK TX: ", request, sizeof(request));

  // Normal answer: addr, 0x03, 0x06, 6 data bytes, CRC = 11 bytes
  const size_t EXPECTED_LENGTH =
      5 + (NPK_REGISTER_COUNT * 2);

  uint8_t response[32];
  size_t received = 0;

  unsigned long started = millis();

  while (millis() - started < NPK_RESPONSE_TIMEOUT_MS) {

    while (
        NPKSerial.available() &&
        received < sizeof(response)
    ) {

      response[received++] = NPKSerial.read();
      started = millis();
    }

    if (received >= EXPECTED_LENGTH) {

      break;
    }

    delay(2);
  }

  printHexBytes("NPK RX: ", response, received);

  if (received == 0) {

    return "no_response_timeout";
  }

  // ---- find the start of the frame (skips any noise byte)
  size_t start = 0;
  bool found = false;

  for (size_t i = 0; i + 2 < received; i++) {

    if (
        response[i] == NPK_SLAVE_ADDRESS &&
        (response[i + 1] == 0x03 ||
         response[i + 1] == 0x83)
    ) {

      start = i;
      found = true;
      break;
    }
  }

  if (!found) {

    return "bad_response_header";
  }

  // ---- Modbus exception: addr, 0x83, code, CRC
  if (response[start + 1] == 0x83) {

    if (received - start < 5) {

      return "short_response";
    }

    uint16_t exceptionCrc =
        modbusCRC16(&response[start], 3);

    if (
        response[start + 3] != (exceptionCrc & 0xFF) ||
        response[start + 4] != (exceptionCrc >> 8)
    ) {

      return "crc_mismatch";
    }

    Serial.print("NPK Modbus exception code: ");
    Serial.println(response[start + 2]);

    return "modbus_exception";
  }

  if (received - start < EXPECTED_LENGTH) {

    return "short_response";
  }

  if (response[start + 2] != NPK_REGISTER_COUNT * 2) {

    return "unexpected_byte_count";
  }

  uint16_t responseCrc =
      modbusCRC16(&response[start], EXPECTED_LENGTH - 2);

  if (
      response[start + EXPECTED_LENGTH - 2] !=
          (responseCrc & 0xFF) ||
      response[start + EXPECTED_LENGTH - 1] !=
          (responseCrc >> 8)
  ) {

    return "crc_mismatch";
  }

  // ---- registers are big-endian
  uint16_t n =
      (response[start + 3] << 8) | response[start + 4];

  uint16_t p =
      (response[start + 5] << 8) | response[start + 6];

  uint16_t k =
      (response[start + 7] << 8) | response[start + 8];

  if (
      n > NPK_MAX_VALID_VALUE ||
      p > NPK_MAX_VALID_VALUE ||
      k > NPK_MAX_VALID_VALUE
  ) {

    return "value_out_of_range";
  }

  out.nitrogen = n;
  out.phosphorus = p;
  out.potassium = k;

  return nullptr;
}

NPKReading readNPK() {

  NPKReading reading;

  reading.valid = false;
  reading.nitrogen = 0;
  reading.phosphorus = 0;
  reading.potassium = 0;
  reading.error = "not_read";

  for (int attempt = 1; attempt <= NPK_MAX_ATTEMPTS; attempt++) {

    const char* error = npkTryRead(reading);

    if (error == nullptr) {

      reading.valid = true;
      reading.error = nullptr;

      return reading;
    }

    reading.error = error;

    Serial.print("NPK read attempt ");
    Serial.print(attempt);
    Serial.print("/");
    Serial.print(NPK_MAX_ATTEMPTS);
    Serial.print(" failed: ");
    Serial.println(error);

    delay(150);
  }

  if (strcmp(reading.error, "no_response_timeout") == 0) {

    Serial.println(
        "NPK: no reply. Check sensor power (9-24V), "
        "A/B wiring, shared GND, baud rate and slave address."
    );
  }

  return reading;
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
    const NPKReading &npk,
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

  // NPK: real values only. When the read failed, send null
  // plus the reason instead of 0.
  if (npk.valid) {

    doc["nitrogen"] = npk.nitrogen;
    doc["phosphorus"] = npk.phosphorus;
    doc["potassium"] = npk.potassium;
    doc["npk_valid"] = true;

  } else {

    doc["nitrogen"] = nullptr;
    doc["phosphorus"] = nullptr;
    doc["potassium"] = nullptr;
    doc["npk_valid"] = false;
    doc["npk_error"] = npk.error;
  }

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

  NPKReading npk =
      readNPK();

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

  if (npk.valid) {

    Serial.print("Nitrogen       : ");
    Serial.print(npk.nitrogen);
    Serial.println(" mg/kg");

    Serial.print("Phosphorus     : ");
    Serial.print(npk.phosphorus);
    Serial.println(" mg/kg");

    Serial.print("Potassium      : ");
    Serial.print(npk.potassium);
    Serial.println(" mg/kg");

  } else {

    Serial.print("NPK            : NOT AVAILABLE (");
    Serial.print(npk.error);
    Serial.println(")");
  }

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
      npk,
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