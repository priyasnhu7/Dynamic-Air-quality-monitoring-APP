# BreathePure AQI Backend (Node.js + Express)

High-performance, lightweight Node.js IoT backend for **BreathePure**, supporting:
- 📱 **Flutter Mobile Application** (REST API & Real-time state)
- 🔌 **ESP8266 + MQ-135 Hardware Nodes** (HTTP Telemetry Stream)
- 📊 **Live Terminal Dashboard & Sensor Simulator** (Built-in data generator)

---

## 🚀 Quick Start

### 1. Start Server Directly
```bash
npm start
```
Or with automatic restart on file changes:
```bash
npm run dev
```

### 2. Double-Click Launchers
- **`start_server.bat`** (inside `aqi_backend`) - Forwards ADB port 5000 and starts the Node.js server.
- **`run_live_terminal_server.bat`** (in root workspace) - Live monitor window with color-coded telemetry and user auth logs.

---

## 📡 API Endpoints

### 🩺 System & Health
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/health` | Server status and timestamp |

### 🔐 Authentication
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/signup` | Register new account (`name`, `email`, `mobile`, `password`) |
| `POST` | `/api/auth/login` | Authenticate (`identifier`, `password`) |
| `POST` | `/api/auth/forgot-password` | Send password reset OTP |
| `GET` | `/api/auth/me` | Fetch profile (requires `Bearer <token>`) |
| `POST` | `/api/auth/logout` | Invalidate current session |
| `GET` | `/api/auth/activity` | Recent login/signup activity logs |

### 🌍 IoT Telemetry & Hardware
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/iot/telemetry` *(or `/data`)* | Ingest hardware packet from ESP8266 |
| `GET` | `/api/iot/latest` | Latest sensor readings & device heartbeat status |
| `GET` | `/api/iot/history?range=today\|week\|month` | Historical sensor graphs data |
| `GET` | `/api/iot/alerts` | List active air quality alerts |
| `POST` | `/api/iot/alerts/dismiss` | Dismiss specific alert or all alerts |
| `GET` | `/api/iot/status` | Hardware device connection status |
| `POST` | `/api/iot/simulation/toggle` | Enable or pause realistic sensor simulation |

---

## 💾 Database Persistence
All user accounts, sessions, alerts, and historical sensor readings persist to:
- [`server_data.json`](./server_data.json)
