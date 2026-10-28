@echo off
title BreathePure Android APK Installer
color 0A
cd /d "%~dp0"

echo ================================================================
echo        BreathePure AQI - Android Device Installation
echo ================================================================
echo.

set ADB="C:\Users\HP\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if not exist %ADB% (
  where adb >nul 2>nul
  if %errorlevel% equ 0 (
    set ADB=adb
  ) else (
    echo [ERROR] ADB not found. Please ensure Android SDK platform-tools is installed.
    pause
    exit /b 1
  )
)

echo Checking for connected Android devices...
%ADB% devices
echo.

echo Enabling USB Port Forwarding (5000:5000)...
%ADB% reverse tcp:5000 tcp:5000 2>nul

if exist "BreathePure_AQI.apk" (
  echo.
  echo Installing BreathePure_AQI.apk onto connected phone...
  %ADB% install -r "BreathePure_AQI.apk"
  if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] BreathePure App successfully installed on your phone!
  ) else (
    echo.
    echo [FAILED] Installation failed. Ensure USB Debugging is ON and phone is unlocked.
  )
) else (
  echo [ERROR] BreathePure_AQI.apk not found in this folder!
)

echo.
pause
