import 'package:flutter/material.dart';

const _bg         = Color(0xFF0d1f1a);
const _accent     = Color(0xFF4ade80);
const _cardBg     = Color(0xFF132a1f);
const _cardBorder = Color(0xFF1e4030);
const _red        = Color(0xFFEF4444);
const _orange     = Color(0xFFF97316);
const _textDim    = Color(0xFF9CA3AF);

enum _Severity { high, medium, low }

class _Alert {
  final String title;
  final String message;
  final String time;
  final _Severity severity;
  final IconData icon;
  bool dismissed = false;
  _Alert({
    required this.title,
    required this.message,
    required this.time,
    required this.severity,
    required this.icon,
  });
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final List<_Alert> _alerts = [
    _Alert(
      title: 'High CO₂ Level',
      message: 'CO₂ reading at 1240 ppm — above safe threshold. Ventilate immediately.',
      time: '2 min ago',
      severity: _Severity.high,
      icon: Icons.co2_rounded,
    ),
    _Alert(
      title: 'AQI Spike Detected',
      message: 'AQI jumped to 143 at Cubbon Park. Sensitive groups should avoid the area.',
      time: '18 min ago',
      severity: _Severity.high,
      icon: Icons.air_rounded,
    ),
    _Alert(
      title: 'MQ135 Threshold',
      message: 'MQ135 sensor reading 390 ppm — approaching critical. Check ventilation.',
      time: '45 min ago',
      severity: _Severity.medium,
      icon: Icons.sensors_rounded,
    ),
    _Alert(
      title: 'Temperature High',
      message: 'Indoor temperature reached 36°C. Consider cooling measures.',
      time: '1 hr ago',
      severity: _Severity.medium,
      icon: Icons.thermostat_rounded,
    ),
    _Alert(
      title: 'Device Reconnected',
      message: 'ESP8266 reconnected after a 5-minute offline period.',
      time: '2 hr ago',
      severity: _Severity.low,
      icon: Icons.wifi_rounded,
    ),
    _Alert(
      title: 'AQI Improved',
      message: 'AQI dropped from 120 to 72. Air quality is now Moderate.',
      time: '3 hr ago',
      severity: _Severity.low,
      icon: Icons.check_circle_rounded,
    ),
    _Alert(
      title: 'Battery Low',
      message: 'ESP8266 battery at 20%. Please charge the device soon.',
      time: '5 hr ago',
      severity: _Severity.medium,
      icon: Icons.battery_alert_rounded,
    ),
  ];

  int _filterIndex = 0; // 0=All, 1=High, 2=Medium, 3=Low

  List<_Alert> get _filtered {
    final visible = _alerts.where((a) => !a.dismissed).toList();
    if (_filterIndex == 0) return visible;
    final sev = [_Severity.high, _Severity.medium, _Severity.low][_filterIndex - 1];
    return visible.where((a) => a.severity == sev).toList();
  }

  Color _severityColor(_Severity s) {
    switch (s) {
      case _Severity.high:   return _red;
      case _Severity.medium: return _orange;
      case _Severity.low:    return _accent;
    }
  }

  String _severityLabel(_Severity s) {
    switch (s) {
      case _Severity.high:   return 'High';
      case _Severity.medium: return 'Medium';
      case _Severity.low:    return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = _alerts.where((a) => !a.dismissed && a.severity == _Severity.high).length;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(activeCount),
            _buildFilterRow(),
            if (activeCount > 0) _buildActiveBar(activeCount),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildAlertCard(filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alerts',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              if (activeCount > 0)
                Text('$activeCount active alert${activeCount > 1 ? "s" : ""}',
                    style: const TextStyle(color: _red, fontSize: 12)),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                for (final a in _alerts) {
                  a.dismissed = true;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _cardBg,
                border: Border.all(color: _cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Clear All',
                  style: TextStyle(color: _textDim, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    const filters = ['All', 'High', 'Medium', 'Low'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (i) {
            final active = i == _filterIndex;
            Color chipColor;
            if (i == 1) {
              chipColor = _red;
            } else if (i == 2) {
              chipColor = _orange;
            } else if (i == 3) {
              chipColor = _accent;
            } else {
              chipColor = _accent;
            }

            return Padding(
              padding: EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _filterIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? chipColor : _cardBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: active ? chipColor : _cardBorder),
                  ),
                  child: Text(
                    filters[i],
                    style: TextStyle(
                      color: active ? Colors.black : _textDim,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActiveBar(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.1),
        border: Border.all(color: _red.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _red, size: 18),
          const SizedBox(width: 8),
          Text(
            '$count critical alert${count > 1 ? "s" : ""} require your attention',
            style: const TextStyle(color: _red, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(_Alert alert) {
    final color = _severityColor(alert.severity);
    return Dismissible(
      key: ObjectKey(alert),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => setState(() => alert.dismissed = true),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _red, size: 26),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: alert.severity == _Severity.high
              ? _red.withValues(alpha: 0.4)
              : _cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(alert.icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(alert.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_severityLabel(alert.severity),
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(alert.message,
                      style: const TextStyle(
                          color: _textDim, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: _textDim, size: 12),
                      const SizedBox(width: 4),
                      Text(alert.time,
                          style: const TextStyle(
                              color: _textDim, fontSize: 11)),
                      const Spacer(),
                      const Text('Swipe to dismiss',
                          style: TextStyle(color: _cardBorder, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: _accent, size: 64),
          const SizedBox(height: 16),
          const Text('All Clear!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('No alerts right now.\nAir quality is being monitored.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textDim, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
