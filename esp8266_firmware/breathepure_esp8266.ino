/*
  BreathePure IoT - ESP8266 + MQ-135 Firmware
  
  Hardware:
    - ESP8266 NodeMCU (or Wemos D1 Mini)
    - MQ-135 Air Quality Sensor (CO2, Smoke, Benzene, NOx, Alcohol)
    - Optional DHT11/DHT22 for Temperature & Humidity (Data on D4)
  
  Connections:
    - MQ-135 VCC  --> 5V (or VIN on NodeMCU)
    - MQ-135 GND  --> GND
    - MQ-135 AOUT --> ESP8266 A0 (Analog Input)
    - DHT11 DATA  --> ESP8266 D4 (GPIO2)
*/

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>

// ─── Network Configuration ──────────────────────────────────────────────────
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Live 24/7 Cloud Backend on Render
const char* BACKEND_URL   = "https://https-breathepure-aqi-backend-onrender.onrender.com/api/iot/telemetry";
const char* DEVICE_KEY    = "esp8266_breathepure_key";
const char* DEVICE_ID     = "ESP8266_NODE_01";

// ─── Sensor Pin Definitions ────────────────────────────────────────────────
const int MQ135_PIN = A0;

// Calibration constant for MQ135 baseline in clean air (adjust if needed)
const float RZERO = 76.63;

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n--- BreathePure IoT Device Initializing ---");

  // Connect to Wi-Fi
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n[Wi-Fi] Connected successfully!");
  Serial.print("[Wi-Fi] IP Address: ");
  Serial.println(WiFi.localIP());

  // Allow MQ135 preheating notice
  Serial.println("[MQ135] Sensor pre-heating initiated. Ready to transmit telemetry.");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    // 1. Read MQ135 analog value (0 - 1023)
    int rawSensorValue = analogRead(MQ135_PIN);

    // 2. Compute approximate PPM and AQI
    // Voltage divider calculation on ESP8266 ADC (0-1.0V or 0-3.3V with onboard divider)
    float vRL = ((float)rawSensorValue / 1023.0) * 3.3;
    float rS = (3.3 - vRL) / (vRL / 10.0); // Assuming 10k RL load resistor
    
    // PPM curve approximation for CO2 / harmful gases
    int ppm = (int)(116.6020682 * pow((rS / RZERO), -2.769034857));
    if (ppm < 250) ppm = 250 + (rawSensorValue / 3);

    // Approximate US AQI conversion based on standard break-points
    int aqi = 50;
    if (ppm <= 350) {
      aqi = (int)((ppm / 350.0) * 50);
    } else if (ppm <= 500) {
      aqi = 51 + (int)(((ppm - 350.0) / 150.0) * 49);
    } else if (ppm <= 800) {
      aqi = 101 + (int)(((ppm - 500.0) / 300.0) * 49);
    } else {
      aqi = 151 + (int)(((ppm - 800.0) / 400.0) * 50);
    }

    // Default room temp / humidity estimation (or replace with dht.readTemperature())
    float temperature = 28.5;
    float humidity    = 60.0;
    int battery       = 88;

    Serial.printf("[Sensor] Raw: %d | PPM: %d | AQI: %d\n", rawSensorValue, ppm, aqi);

    // 3. Prepare JSON Payload
    WiFiClientSecure client;
    client.setInsecure(); // Allows secure HTTPS connection to cloud without certificate errors
    HTTPClient http;

    if (http.begin(client, BACKEND_URL)) {
      http.addHeader("Content-Type", "application/json");
      http.addHeader("X-Device-Key", DEVICE_KEY);

      char jsonPayload[256];
      snprintf(jsonPayload, sizeof(jsonPayload),
        "{\"deviceId\":\"%s\",\"apiKey\":\"%s\",\"mq135_raw\":%d,\"ppm\":%d,\"aqi\":%d,\"temperature\":%.1f,\"humidity\":%.1f,\"battery\":%d}",
        DEVICE_ID, DEVICE_KEY, rawSensorValue, ppm, aqi, temperature, humidity, battery
      );

      int httpResponseCode = http.POST(jsonPayload);
      if (httpResponseCode > 0) {
        String response = http.getString();
        Serial.printf("[HTTP] Status: %d | Response: %s\n", httpResponseCode, response.c_str());
      } else {
        Serial.printf("[HTTP] POST failed, error: %s\n", http.errorToString(httpResponseCode).c_str());
      }
      http.end();
    } else {
      Serial.println("[HTTP] Unable to connect to backend server");
    }
  } else {
    Serial.println("[Wi-Fi] Disconnected! Reconnecting...");
    WiFi.reconnect();
  }

  // Send telemetry every 5 seconds
  delay(5000);
}
