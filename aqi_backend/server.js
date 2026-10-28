/**
 * BreathePure IoT Node.js Backend Server
 * High-performance backend supporting ESP8266 NodeMCU + MQ-135 Gas Sensor and Flutter Mobile App.
 */

const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.PORT || 5000;
const DEFAULT_DEVICE_KEY = 'esp8266_breathepure_key';
const DB_FILE = path.join(__dirname, 'server_data.json');

const app = express();

// ---------------------------------------------------------------------
// Middleware configuration
// ---------------------------------------------------------------------
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Origin', 'Content-Type', 'Authorization', 'X-Device-Key'],
  maxAge: 86400
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logger for important endpoints
app.use((req, res, next) => {
  const p = req.path;
  if (p !== '/api/health' && p !== '/api/iot/latest' && p !== '/api/auth/activity') {
    const timeStr = new Date().toTimeString().substring(0, 8);
    const ip = req.ip || req.socket.remoteAddress || 'client';
    console.log(`[${timeStr}] 🌐 [${req.method}] ${p} from ${ip}`);
  }
  next();
});

// ---------------------------------------------------------------------
// In-Memory Database State with File Persistence
// ---------------------------------------------------------------------
let db = {
  users: [],
  tokens: {},
  authActivity: [],
  telemetry: [],
  alerts: [],
  deviceStatus: {
    deviceId: 'ESP8266_NODE_01',
    isOnline: true,
    lastHeartbeat: new Date().toISOString(),
    battery: 85,
    firmware: 'v1.2.0',
  },
};

let simulationEnabled = true;
let simulationTimer = null;

// Helpers: Random string & Cryptographic Hashing
function generateRandomString(length = 16) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  const bytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    result += chars[bytes[i] % chars.length];
  }
  return result;
}

function generateSalt(length = 16) {
  return generateRandomString(length);
}

// Exactly compatible with the existing Dart backend SHA-256 scheme: sha256(password::salt)
function hashPassword(password, salt) {
  return crypto.createHash('sha256').update(`${password}::${salt}`).digest('hex');
}

function getAqiCategory(aqi) {
  if (aqi <= 50) return 'Good';
  if (aqi <= 100) return 'Moderate';
  if (aqi <= 150) return 'Unhealthy (Sensitive)';
  if (aqi <= 200) return 'Unhealthy';
  return 'Very Unhealthy';
}

function ppmToAqi(ppm) {
  if (ppm <= 350) return Math.round((ppm / 350) * 50);
  if (ppm <= 500) return Math.round(50 + ((ppm - 350) / 150) * 50);
  if (ppm <= 800) return Math.round(100 + ((ppm - 500) / 300) * 50);
  if (ppm <= 1200) return Math.round(150 + ((ppm - 800) / 400) * 50);
  const calculated = Math.round(200 + ((ppm - 1200) / 800) * 100);
  return Math.min(Math.max(calculated, 201), 500);
}

// Load DB from disk
function loadDatabase() {
  try {
    if (fs.existsSync(DB_FILE)) {
      const data = fs.readFileSync(DB_FILE, 'utf-8');
      const parsed = JSON.parse(data);
      if (parsed && typeof parsed === 'object') {
        db = {
          users: parsed.users || [],
          tokens: parsed.tokens || {},
          authActivity: parsed.authActivity || [],
          telemetry: parsed.telemetry || [],
          alerts: parsed.alerts || [],
          deviceStatus: parsed.deviceStatus || {
            deviceId: 'ESP8266_NODE_01',
            isOnline: true,
            lastHeartbeat: new Date().toISOString(),
            battery: 85,
            firmware: 'v1.2.0',
          },
        };
        console.log(`[DB] Successfully loaded database (${db.users.length} users, ${db.telemetry.length} readings).`);
      }
    }
  } catch (err) {
    console.error(`[DB] Error reading database: ${err.message}. Initializing defaults.`);
  }
}

// Save DB to disk
function saveDatabase() {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf-8');
  } catch (err) {
    console.error(`[DB] Error saving database: ${err.message}`);
  }
}

// Seed demo data if database is brand new
function seedDefaultDataIfEmpty() {
  if (db.users.length === 0) {
    const salt = generateSalt();
    const hashedPassword = hashPassword('password123', salt);
    db.users.push({
      id: 'usr_demo_1',
      name: 'Arjun Sharma',
      email: 'arjun@breathepure.io',
      mobile: '9876543210',
      salt,
      passwordHash: hashedPassword,
      createdAt: new Date(Date.now() - 30 * 86400000).toISOString(),
    });
  }

  if (db.telemetry.length === 0) {
    const now = Date.now();
    for (let i = 24; i >= 0; i--) {
      const time = new Date(now - i * 3600000);
      const aqi = Math.round(65 + Math.sin(i / 3) * 20 + Math.floor(Math.random() * 15));
      const ppm = Math.round(300 + aqi * 1.2 + Math.floor(Math.random() * 20));
      const temp = Number((27.0 + Math.sin(i / 4) * 5 + Math.random() * 1.5).toFixed(1));
      const humidity = Number((55.0 + Math.cos(i / 4) * 8 + Math.random() * 2.0).toFixed(1));

      db.telemetry.push({
        id: `tel_${time.getTime()}`,
        timestamp: time.toISOString(),
        deviceId: 'ESP8266_NODE_01',
        mq135_raw: Math.round(ppm * 1.1),
        ppm,
        aqi,
        status: getAqiCategory(aqi),
        temperature: temp,
        humidity,
        battery: 75,
      });
    }
  }

  if (db.alerts.length === 0) {
    db.alerts.push(
      {
        id: 'alt_1',
        title: 'High CO₂ Detected',
        message: 'CO₂ reading reached 1240 ppm. Ventilate room immediately.',
        time: '10 min ago',
        severity: 'high',
        icon: 'co2',
        dismissed: false,
        createdAt: new Date(Date.now() - 10 * 60000).toISOString(),
      },
      {
        id: 'alt_2',
        title: 'AQI Spike Alert',
        message: 'AQI jumped to 115 in your area. Sensitive groups should stay indoors.',
        time: '45 min ago',
        severity: 'high',
        icon: 'air',
        dismissed: false,
        createdAt: new Date(Date.now() - 45 * 60000).toISOString(),
      },
      {
        id: 'alt_3',
        title: 'MQ135 Reading Elevated',
        message: 'Air contaminants approaching moderate-high threshold (380 ppm).',
        time: '2 hr ago',
        severity: 'medium',
        icon: 'sensors',
        dismissed: false,
        createdAt: new Date(Date.now() - 2 * 3600000).toISOString(),
      },
      {
        id: 'alt_4',
        title: 'ESP8266 Online',
        message: 'Hardware connected to Wi-Fi successfully.',
        time: '4 hr ago',
        severity: 'low',
        icon: 'wifi',
        dismissed: false,
        createdAt: new Date(Date.now() - 4 * 3600000).toISOString(),
      }
    );
  }

  saveDatabase();
}

// ---------------------------------------------------------------------
// Activity & Session Tracking
// ---------------------------------------------------------------------
function recordAuthActivity(type, userName, userEmail, userId, details) {
  const timestamp = new Date().toISOString();
  const icon = type === 'LOGIN' ? '🟢' : type === 'LOGOUT' ? '🔴' : type === 'SIGNUP' ? '✨' : '⚠️';

  console.log('');
  console.log('========================================================');
  console.log(`[USER ACTIVITY] ${icon} ${type}: ${userName} (${userEmail})`);
  console.log(`  Time:    ${timestamp}`);
  console.log(`  Details: ${details}`);
  console.log('========================================================');
  console.log('');

  if (!db.authActivity) db.authActivity = [];
  db.authActivity.unshift({
    id: `act_${Date.now()}`,
    type,
    userName,
    userEmail,
    userId,
    details,
    timestamp,
  });

  if (db.authActivity.length > 200) {
    db.authActivity = db.authActivity.slice(0, 200);
  }
  saveDatabase();
}

function createSession(userId) {
  const token = `jwt_${generateRandomString(32)}`;
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 30 * 86400000); // 30 days
  db.tokens[token] = {
    userId,
    createdAt: now.toISOString(),
    expiresAt: expiresAt.toISOString(),
  };
  saveDatabase();
  return token;
}

function authenticateRequest(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.substring(7);
  const session = db.tokens[token];
  if (!session) return null;

  if (new Date(session.expiresAt) < new Date()) {
    delete db.tokens[token];
    saveDatabase();
    return null;
  }

  const user = db.users.find(u => u.id === session.userId);
  return user || null;
}

// ---------------------------------------------------------------------
// Simulation Engine for realistic IoT data stream
// ---------------------------------------------------------------------
function startSimulationTimer() {
  if (simulationTimer) clearInterval(simulationTimer);
  simulationTimer = setInterval(() => {
    if (!simulationEnabled) return;
    injectSimulatedReading();
  }, 5000);
}

function injectSimulatedReading() {
  const lastReading = db.telemetry.length > 0 ? db.telemetry[db.telemetry.length - 1] : null;
  const baseAqi = lastReading ? lastReading.aqi : 80;
  const deltaAqi = Math.floor(Math.random() * 7) - 3; // -3 to +3
  const newAqi = Math.min(Math.max(baseAqi + deltaAqi, 40), 160);

  const basePpm = 300 + Math.round(newAqi * 1.15) + (Math.floor(Math.random() * 10) - 5);
  const temp = Number((28.5 + (Math.random() * 0.8 - 0.4)).toFixed(1));
  const humidity = Number((60.0 + (Math.random() * 1.2 - 0.6)).toFixed(1));

  const reading = {
    id: `tel_${Date.now()}`,
    timestamp: new Date().toISOString(),
    deviceId: 'ESP8266_NODE_01',
    mq135_raw: Math.round(basePpm * 1.1),
    ppm: basePpm,
    aqi: newAqi,
    status: getAqiCategory(newAqi),
    temperature: temp,
    humidity: humidity,
    battery: 72,
  };

  db.telemetry.push(reading);
  if (db.telemetry.length > 500) {
    db.telemetry = db.telemetry.slice(db.telemetry.length - 500);
  }

  db.deviceStatus = {
    deviceId: 'ESP8266_NODE_01',
    isOnline: true,
    lastHeartbeat: new Date().toISOString(),
    battery: 72,
    firmware: 'v1.2.0',
  };

  saveDatabase();

  const timeStr = new Date().toTimeString().substring(0, 8);
  console.log(`[${timeStr}] 📡 [LIVE TELEMETRY] AQI: ${newAqi} (${getAqiCategory(newAqi)}) | PPM: ${basePpm} | Temp: ${reading.temperature}°C | Hum: ${reading.humidity}% | ESP8266: Online`);
}

// ---------------------------------------------------------------------
// API Routes
// ---------------------------------------------------------------------

// Health Check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    server: 'BreathePure IoT Node.js Backend',
    time: new Date().toISOString(),
  });
});

// Authentication Routes
app.post('/api/auth/signup', (req, res) => {
  const { name, email, mobile, password } = req.body || {};

  const cleanName = (name || '').trim();
  const cleanEmail = (email || '').trim().toLowerCase();
  const cleanMobile = (mobile || '').trim();
  const cleanPassword = password || '';

  if (!cleanName || !cleanEmail || !cleanMobile || !cleanPassword) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  if (cleanPassword.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  const existing = db.users.find(u => u.email === cleanEmail || u.mobile === cleanMobile);
  if (existing) {
    return res.status(409).json({ error: 'An account with this email or mobile number already exists' });
  }

  const salt = generateSalt();
  const passwordHash = hashPassword(cleanPassword, salt);
  const userId = `usr_${Date.now()}`;

  const newUser = {
    id: userId,
    name: cleanName,
    email: cleanEmail,
    mobile: cleanMobile,
    salt,
    passwordHash,
    createdAt: new Date().toISOString(),
  };

  db.users.push(newUser);
  const token = createSession(userId);

  recordAuthActivity(
    'SIGNUP',
    cleanName,
    cleanEmail,
    userId,
    'New user registered from mobile / web'
  );

  res.status(201).json({
    success: true,
    token,
    user: {
      id: userId,
      name: cleanName,
      email: cleanEmail,
      mobile: cleanMobile,
    },
  });
});

app.post('/api/auth/login', (req, res) => {
  const { identifier, password } = req.body || {};
  const cleanId = (identifier || '').trim().toLowerCase();
  const cleanPass = password || '';

  if (!cleanId || !cleanPass) {
    return res.status(400).json({ error: 'Email/Phone and password are required' });
  }

  const user = db.users.find(u => u.email === cleanId || u.mobile === cleanId);
  if (!user) {
    console.log(`[AUTH EVENT] ❌ FAILED LOGIN ATTEMPT for identifier: "${cleanId}" at ${new Date().toISOString()}`);
    recordAuthActivity('LOGIN_FAILED', 'Unknown', cleanId, 'anonymous', 'Failed login attempt - user not found');
    return res.status(401).json({ error: 'Invalid credentials. User not found.' });
  }

  const actualHash = hashPassword(cleanPass, user.salt);
  if (actualHash !== user.passwordHash) {
    console.log(`[AUTH EVENT] ❌ FAILED LOGIN (WRONG PASSWORD) for: "${user.email}" at ${new Date().toISOString()}`);
    recordAuthActivity('LOGIN_FAILED', user.name || 'User', user.email || cleanId, user.id, 'Incorrect password entered');
    return res.status(401).json({ error: 'Incorrect password.' });
  }

  const token = createSession(user.id);
  recordAuthActivity('LOGIN', user.name || 'User', user.email || cleanId, user.id, 'User logged in successfully');

  res.json({
    success: true,
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      mobile: user.mobile,
    },
  });
});

app.post('/api/auth/forgot-password', (req, res) => {
  const { identifier } = req.body || {};
  const cleanId = (identifier || '').trim().toLowerCase();

  if (!cleanId) {
    return res.status(400).json({ error: 'Please provide registered email or mobile' });
  }

  const user = db.users.find(u => u.email === cleanId || u.mobile === cleanId);
  if (!user) {
    return res.status(404).json({ error: 'No account found with this identifier' });
  }

  const resetOtp = Math.floor(100000 + Math.random() * 900000).toString();
  console.log(`[AUTH EVENT] 🔑 PASSWORD RESET REQUEST for: ${cleanId} | OTP: ${resetOtp} at ${new Date().toISOString()}`);

  res.json({
    success: true,
    message: 'Password reset verification code sent.',
    otp: resetOtp,
  });
});

app.get('/api/auth/me', (req, res) => {
  const user = authenticateRequest(req);
  if (!user) {
    return res.status(401).json({ error: 'Unauthorized. Please login.' });
  }

  res.json({
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      mobile: user.mobile,
      createdAt: user.createdAt,
    },
  });
});

app.post('/api/auth/logout', (req, res) => {
  const authHeader = req.headers.authorization;
  let userName = 'User';
  let userEmail = '';
  let userId = '';

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    const session = db.tokens[token];
    if (session) {
      userId = session.userId || '';
      const u = db.users.find(user => user.id === userId);
      if (u) {
        userName = u.name || 'User';
        userEmail = u.email || '';
      }
      delete db.tokens[token];
      saveDatabase();
    }
  }

  recordAuthActivity('LOGOUT', userName, userEmail, userId, 'User logged out');
  res.json({ success: true, message: 'Logged out successfully' });
});

app.get('/api/auth/activity', (req, res) => {
  const limit = parseInt(req.query.limit, 10) || 50;
  const list = db.authActivity || [];
  res.json({
    activities: list.slice(0, limit),
    total: list.length,
  });
});

// View all registered users (sanitized, safe)
app.get('/api/auth/users', (req, res) => {
  const users = (db.users || []).map(u => ({
    id: u.id,
    name: u.name,
    email: u.email,
    mobile: u.mobile,
    createdAt: u.createdAt,
  }));
  res.json({
    totalUsers: users.length,
    users,
  });
});

// IoT Ingestion (supports both /api/iot/telemetry and /data)
const handleTelemetryIngest = (req, res) => {
  const deviceKey = req.headers['x-device-key'] || req.query.apiKey;
  const body = req.body || {};

  const passedKey = deviceKey || body.apiKey;
  if (passedKey && passedKey !== DEFAULT_DEVICE_KEY) {
    return res.status(403).json({ error: 'Unauthorized device key' });
  }

  const deviceId = body.deviceId || 'ESP8266_NODE_01';
  const rawVal = Number(body.value ?? body.mq135_raw ?? body.ppm ?? 300.0);
  const mq135Raw = Number(body.mq135_raw ?? Math.round(rawVal));

  let ppm;
  if (body.ppm !== undefined && body.ppm !== null) {
    ppm = Number(body.ppm);
  } else if (rawVal > 0 && rawVal <= 1023) {
    ppm = Math.round(250 + rawVal * 0.95);
  } else {
    ppm = Math.round(rawVal);
  }

  const calculatedAqi = body.aqi !== undefined && body.aqi !== null ? Number(body.aqi) : ppmToAqi(ppm);
  const temp = body.temperature !== undefined ? Number(Number(body.temperature).toFixed(1)) : 28.0;
  const humidity = body.humidity !== undefined ? Number(Number(body.humidity).toFixed(1)) : 60.0;
  const battery = body.battery !== undefined ? Number(body.battery) : 85;

  // Real hardware connected: pause synthetic generator
  if (simulationEnabled) {
    simulationEnabled = false;
    console.log('[IoT] 🔌 Real ESP8266 hardware stream connected! Simulation paused.');
  }

  const reading = {
    id: `tel_${Date.now()}`,
    timestamp: new Date().toISOString(),
    deviceId,
    mq135_raw: mq135Raw,
    ppm,
    aqi: calculatedAqi,
    status: getAqiCategory(calculatedAqi),
    temperature: temp,
    humidity,
    battery,
  };

  db.telemetry.push(reading);
  if (db.telemetry.length > 500) {
    db.telemetry = db.telemetry.slice(db.telemetry.length - 500);
  }

  db.deviceStatus = {
    deviceId,
    isOnline: true,
    lastHeartbeat: new Date().toISOString(),
    battery,
    firmware: 'v1.2.0',
  };

  const timeStr = new Date().toTimeString().substring(0, 8);
  console.log(`[${timeStr}] 📡 [HARDWARE TELEMETRY] Raw: ${mq135Raw} | PPM: ${ppm} | AQI: ${calculatedAqi} (${getAqiCategory(calculatedAqi)}) | Temp: ${temp}°C | Device: ${deviceId}`);

  // Auto-alert trigger
  if (calculatedAqi > 120 || ppm > 800) {
    db.alerts.unshift({
      id: `alt_${Date.now()}`,
      title: calculatedAqi > 150 ? 'Hazardous AQI Alert' : 'Air Quality Warning',
      message: `Sensor detected AQI ${calculatedAqi} (${ppm} ppm). Ensure air ventilation immediately.`,
      time: 'Just now',
      severity: calculatedAqi > 150 ? 'high' : 'medium',
      icon: 'air',
      dismissed: false,
      createdAt: new Date().toISOString(),
    });
  }

  saveDatabase();

  res.status(201).json({
    success: true,
    message: 'Telemetry stored',
    reading,
  });
};

app.post('/api/iot/telemetry', handleTelemetryIngest);
app.post('/data', handleTelemetryIngest);

app.get('/api/iot/latest', (req, res) => {
  const latest = db.telemetry.length > 0 ? db.telemetry[db.telemetry.length - 1] : null;
  const deviceStatus = db.deviceStatus || {};
  let isOnline = false;

  if (deviceStatus.lastHeartbeat) {
    const diff = (Date.now() - new Date(deviceStatus.lastHeartbeat).getTime()) / 1000;
    if (diff < 45) {
      isOnline = true;
    }
  }

  res.json({
    latest,
    deviceStatus: {
      ...deviceStatus,
      isOnline,
    },
  });
});

app.get('/api/iot/history', (req, res) => {
  const range = req.query.range || 'today';
  const now = new Date();
  let filtered = [];

  if (range === 'today') {
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    filtered = db.telemetry.filter(r => new Date(r.timestamp) >= startOfDay);
  } else if (range === 'week') {
    const sevenDaysAgo = new Date(now.getTime() - 7 * 86400000);
    filtered = db.telemetry.filter(r => new Date(r.timestamp) >= sevenDaysAgo);
  } else {
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 86400000);
    filtered = db.telemetry.filter(r => new Date(r.timestamp) >= thirtyDaysAgo);
  }

  if (filtered.length === 0 && db.telemetry.length > 0) {
    filtered = db.telemetry.slice(-12);
  }

  res.json({
    range,
    count: filtered.length,
    data: filtered,
  });
});

app.get('/api/iot/alerts', (req, res) => {
  res.json({
    alerts: db.alerts || [],
  });
});

app.post('/api/iot/alerts/dismiss', (req, res) => {
  const { id, all } = req.body || {};
  if (all) {
    db.alerts.forEach(a => { a.dismissed = true; });
  } else if (id) {
    const alert = db.alerts.find(a => a.id === id);
    if (alert) alert.dismissed = true;
  }
  saveDatabase();
  res.json({ success: true, message: 'Alert(s) dismissed' });
});

app.get('/api/iot/status', (req, res) => {
  const deviceStatus = db.deviceStatus || {};
  let isOnline = false;

  if (deviceStatus.lastHeartbeat) {
    const diff = (Date.now() - new Date(deviceStatus.lastHeartbeat).getTime()) / 1000;
    if (diff < 45) {
      isOnline = true;
    }
  }

  res.json({
    device: {
      ...deviceStatus,
      isOnline,
      sensor: 'MQ135 Gas Sensor',
      controller: 'ESP8266 Wi-Fi Microcontroller',
    },
  });
});

app.post('/api/iot/simulation/toggle', (req, res) => {
  simulationEnabled = !simulationEnabled;
  res.json({ simulationEnabled });
});

// 404 handler for unrecognized routes
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.originalUrl,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('[SERVER ERROR]', err);
  res.status(500).json({
    error: 'Internal server error',
    details: err.message,
  });
});

// ---------------------------------------------------------------------
// Server Initialization
// ---------------------------------------------------------------------
function startServer() {
  loadDatabase();
  seedDefaultDataIfEmpty();
  startSimulationTimer();

  app.listen(PORT, '0.0.0.0', () => {
    console.log('========================================================');
    console.log(' 🍃 BreathePure IoT Node.js Backend Server Started');
    console.log(` Listening on: http://0.0.0.0:${PORT}`);
    console.log(` Localhost:    http://localhost:${PORT}`);
    console.log(` Device Key:   ${DEFAULT_DEVICE_KEY}`);
    console.log(' Engine:       Node.js + Express.js');
    console.log('========================================================');
  });
}

startServer();
