/*
  BreathePure IoT - ESP8266 & MQ-135 Air Quality Sensor
  Integrated for: SAKSHAM / BreathePure App
*/

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>

// ─── Network Configuration ──────────────────────────────────────────────────
const char* ssid        = "SAKSHAM";
const char* password    = "bdcoe123";

// Replace with your laptop's Wi-Fi hotspot IP if changed:
// Default endpoint is /api/iot/telemetry (also supports /data)
const char* serverUrl   = "http://192.168.137.150:5000/api/iot/telemetry";
const char* DEVICE_ID   = "ESP8266_NODE_01";
const char* DEVICE_KEY  = "esp8266_breathepure_key";

// ─── Sensor Pin & Constants ────────────────────────────────────────────────
const int mq135Pin      = A0;  // Analog pin connected to MQ-135 AOUT
const float RZERO       = 76.63; // Baseline resistance in clean air

// ─── Read & Filter MQ-135 Analog Value ─────────────────────────────────────
int readFilteredRawMQ135() {
  long sum = 0;
  const int samples = 5;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(mq135Pin);
    delay(20);
  }
  return (int)(sum / samples);
}

// ─── Calculate Approximate PPM (CO2 / Harmful Gases) ──────────────────────
int calculatePPM(int rawValue) {
  // ESP8266 ADC is 0 - 1023 (0 - 3.3V with onboard resistor divider)
  float vRL = ((float)rawValue / 1023.0) * 3.3;
  if (vRL <= 0.05) vRL = 0.05; // avoid division by zero
  float rS = (3.3 - vRL) / (vRL / 10.0); // 10k RL load resistor

  int ppm = (int)(116.6020682 * pow((rS / RZERO), -2.769034857));
  if (ppm < 250) {
    ppm = 250 + (rawValue / 3);
  }
  return ppm;
}

// ─── Convert PPM to Standard AQI (Air Quality Index) ───────────────────────
int calculateAQI(int ppm) {
  if (ppm <= 350) {
    return (int)((ppm / 350.0) * 50);
  } else if (ppm <= 500) {
    return 51 + (int)(((ppm - 350.0) / 150.0) * 49);
  } else if (ppm <= 800) {
    return 101 + (int)(((ppm - 500.0) / 300.0) * 49);
  } else {
    return 151 + (int)(((ppm - 800.0) / 400.0) * 50);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(mq135Pin, INPUT);
  delay(1000);

  Serial.println("\n==========================================");
  Serial.println("  BreathePure IoT - ESP8266 + MQ-135");
  Serial.println("==========================================");

  // Connect to Wi-Fi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  Serial.print("[Wi-Fi] Connecting to: ");
  Serial.println(ssid);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[Wi-Fi] Connected successfully!");
    Serial.print("[Wi-Fi] Device IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("[Wi-Fi] Gateway IP: ");
    Serial.println(WiFi.gatewayIP());
  } else {
    Serial.println("\n[Wi-Fi] Connection timed out. Will retry in loop.");
  }
}

void loop() {
  // Check Wi-Fi connection
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[Wi-Fi] Reconnecting...");
    WiFi.reconnect();
    delay(3000);
    return;
  }

  // 1. Read sensor
  int rawValue = readFilteredRawMQ135();
  int co2ppm   = calculatePPM(rawValue);
  int aqi      = calculateAQI(co2ppm);

  // Default environmental estimates (or hook up DHT11 sensor)
  float temperature = 27.5;
  float humidity    = 58.0;
  int battery       = 85;

  Serial.printf("\n[Sensor] Raw: %d | PPM: %d | AQI: %d\n", rawValue, co2ppm, aqi);

  // 2. Prepare HTTP POST request
  WiFiClient client;
  HTTPClient http;

  if (http.begin(client, serverUrl)) {
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-Key", DEVICE_KEY);

    // JSON payload compatible with both your legacy sketch and BreathePure backend
    char jsonPayload[256];
    snprintf(jsonPayload, sizeof(jsonPayload),
      "{\"deviceId\":\"%s\",\"apiKey\":\"%s\",\"value\":%d,\"mq135_raw\":%d,\"ppm\":%d,\"aqi\":%d,\"temperature\":%.1f,\"humidity\":%.1f,\"battery\":%d}",
      DEVICE_ID, DEVICE_KEY, rawValue, rawValue, co2ppm, aqi, temperature, humidity, battery
    );

    Serial.print("[HTTP] Sending: ");
    Serial.println(jsonPayload);

    int httpResponseCode = http.POST(jsonPayload);

    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.printf("[HTTP] Success (Status %d): %s\n", httpResponseCode, response.c_str());
    } else {
      Serial.printf("[HTTP] POST failed, error: %s\n", http.errorToString(httpResponseCode).c_str());
      Serial.println("[HTTP] Check if backend server is running and IP is reachable.");
    }

    http.end();
  } else {
    Serial.println("[HTTP] Unable to connect to server URL");
  }

  // Send readings every 3 seconds
  delay(3000);
}
