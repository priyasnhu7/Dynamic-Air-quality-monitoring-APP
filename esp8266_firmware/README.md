# ESP8266 + MQ-135 Hardware Setup Guide

This guide describes how to connect the **MQ-135 Air Quality Sensor** to the **ESP8266** (NodeMCU or Wemos D1 Mini) and stream live data to your BreathePure IoT backend.

---

## 1. Pin Wiring Diagram

| MQ-135 Pin | ESP8266 Pin (NodeMCU) | Description |
| :--- | :--- | :--- |
| **VCC** | **VIN (or 5V)** | MQ-135 heater requires 5V for accurate calibration |
| **GND** | **GND** | Ground connection |
| **AOUT (Analog Out)** | **A0** | Analog air pollution reading (0 - 1023) |
| **DOUT (Digital Out)** | *Not connected* | Digital threshold pin (optional) |

*Optional: If using a **DHT11** for real temperature & humidity:*
* DHT11 **VCC** -> 3.3V / 5V
* DHT11 **GND** -> GND
* DHT11 **DATA** -> Pin **D4** (GPIO2)

---

## 2. Arduino IDE Setup Instructions

1. Open **Arduino IDE**.
2. Go to **File > Preferences** and add the ESP8266 board URL:
   ```
   http://arduino.esp8266.com/stable/package_esp8266com_index.json
   ```
3. Go to **Tools > Board > Boards Manager...**, search for `esp8266` and install it.
4. Select your board under **Tools > Board > ESP8266 Boards > NodeMCU 1.0 (ESP-12E Module)**.
5. Open [`breathepure_esp8266.ino`](./breathepure_esp8266.ino).
6. Update your Wi-Fi credentials and local computer IP:
   ```cpp
   const char* WIFI_SSID     = "YOUR_HOME_WIFI";
   const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
   const char* BACKEND_URL   = "http://192.168.x.x:5000/api/iot/telemetry";
   ```
7. Click **Upload** and open the **Serial Monitor** at **115200 baud** to see real-time transmission.
