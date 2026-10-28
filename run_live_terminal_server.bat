@echo off
title BreathePure IoT Live Backend Monitor (Node.js)
color 0A
cd /d "%~dp0\aqi_backend"

echo ================================================================
echo   BreathePure IoT Live Node.js Server Monitor
echo   Listening on http://localhost:5000 / 0.0.0.0:5000
echo   Live Login / Logout, ESP8266 and Telemetry Events Will Appear Below
echo ================================================================
echo.

echo Forwarding port 5000 to connected Android devices...
"C:\Users\HP\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse tcp:5000 tcp:5000 2>nul

where node >nul 2>nul
if %errorlevel% equ 0 (
  node server.js
) else (
  "C:\Program Files\nodejs\node.exe" server.js
)

pause
