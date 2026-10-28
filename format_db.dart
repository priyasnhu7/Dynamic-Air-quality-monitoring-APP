import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('c:/Users/HP/Downloads/AQI APP/aqi_backend/server_data.json');
  if (file.existsSync()) {
    final raw = file.readAsStringSync();
    final data = jsonDecode(raw);
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(data));
    print('SUCCESS_FORMATTED');
  }
}
