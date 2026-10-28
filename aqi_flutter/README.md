# aqi_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run with the Android phone

Open the project root in VS Code and allow automatic tasks when prompted. VS Code
starts the backend from `aqi_backend` whenever the workspace opens. Connect the
phone over USB with USB debugging enabled, then run **Run Flutter App** from Run
and Debug. The launch configuration forwards port 5000 to the phone before
starting the app, so its `127.0.0.1:5000` API URL reaches the computer.

After restarting the VS Code window, wait for the backend terminal to report
that it is listening on port 5000 before using the app. If the phone is not
connected when launching, connect it and run the app again.
