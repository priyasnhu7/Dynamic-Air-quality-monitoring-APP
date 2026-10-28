@echo off
title BreathePure IoT Live Backend Monitor (Node.js)
color 0A
echo ===================================================
echo  Starting BreathePure IoT Node.js Backend Server
echo ===================================================
cd /d "%~dp0"

echo Reverse proxying ADB port 5000 for Android devices...
"C:\Users\HP\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse tcp:5000 tcp:5000 2>nul

where node >nul 2>nul
if %errorlevel% equ 0 (
  node server.js
) else (
  "C:\Program Files\nodejs\node.exe" server.js
)
