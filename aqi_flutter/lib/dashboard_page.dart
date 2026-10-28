
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/iot_service.dart';
import 'history_page.dart';
import 'map_page.dart';
import 'alerts_page.dart';
import 'settings_page.dart';

// ─── Colour palette ───────────────────────────────────────────────────────────
const _bg         = Color(0xFF0d1f1a);
const _accent     = Color(0xFF4ade80);
const _cardBg     = Color(0xFF132a1f);
const _cardBorder = Color(0xFF1e4030);
const _yellow     = Color(0xFFFACC15);
const _red        = Color(0xFFEF4444);
const _textDim    = Color(0xFF9CA3AF);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Timer? _telemetryTimer;

  // Live telemetry state
  int _aqi = 82;
  String _aqiStatus = 'Moderate';
  int _mq135Ppm = 342;
  double _temperature = 28.5;
  double _humidity = 60.0;
  int _battery = 72;
  bool _isEspOnline = true;
  final String _alertMessage = 'High CO₂ detected (1240 ppm). Ventilate the room immediately.';

  @override
  void initState() {
    super.initState();
    _fetchLatestTelemetry();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _fetchLatestTelemetry();
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestTelemetry() async {
    final data = await IotService.fetchLatestTelemetry();
    if (!mounted || data == null) return;

    final latest = data['latest'] as Map<String, dynamic>?;
    final device = data['deviceStatus'] as Map<String, dynamic>?;

    setState(() {
      if (latest != null) {
        _aqi = (latest['aqi'] as num?)?.toInt() ?? _aqi;
        _aqiStatus = (latest['status'] as String?) ?? _aqiStatus;
        _mq135Ppm = (latest['ppm'] as num?)?.toInt() ?? _mq135Ppm;
        _temperature = (latest['temperature'] as num?)?.toDouble() ?? _temperature;
        _humidity = (latest['humidity'] as num?)?.toDouble() ?? _humidity;
      }
      if (device != null) {
        _battery = (device['battery'] as num?)?.toInt() ?? _battery;
        _isEspOnline = (device['isOnline'] as bool?) ?? _isEspOnline;
      }
    });
  }

  static const _navItems = [
    (icon: Icons.home_rounded,          label: 'Home'),
    (icon: Icons.bar_chart_rounded,     label: 'History'),
    (icon: Icons.map_rounded,           label: 'Map'),
    (icon: Icons.notifications_rounded, label: 'Alerts'),
    (icon: Icons.settings_rounded,      label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildAQICard(),
                  const SizedBox(height: 12),
                  _buildAlertBanner(),
                  const SizedBox(height: 12),
                  _buildSensorRow(),
                  const SizedBox(height: 12),
                  _buildChartCard(),
                  const SizedBox(height: 12),
                  _buildBottomRow(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const HistoryPage(),
          const MapPage(),
          const AlertsPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // 1. Header
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BreathePure IoT',
              style: TextStyle(
                color: _accent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.location_on_rounded, color: _textDim, size: 14),
                SizedBox(width: 3),
                Text('Bengaluru, India', style: TextStyle(color: _textDim, fontSize: 13)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: _iconBtn(Icons.notifications_outlined),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 4),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _cardBorder,
                child: const Icon(Icons.person_rounded, color: _accent, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(color: _cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _textDim, size: 20),
      );

  // 2. Big AQI Card
  Widget _buildAQICard() {
    return _card(
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 3),
              color: _cardBg,
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_aqi',
                  style: const TextStyle(color: _accent, fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const Text('AQI', style: TextStyle(color: _textDim, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _aqiStatus,
                  style: const TextStyle(color: _yellow, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Air quality is acceptable.\nSensitive groups may be affected.',
                  style: TextStyle(color: _textDim, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                _buildGradientBar(),
                const SizedBox(height: 8),
                const Text('🕐  Updated 2 min ago', style: TextStyle(color: _textDim, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBar() {
    const markerPos = 0.33;
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(colors: [_accent, _yellow, _red]),
            ),
          ),
          Positioned(
            left: totalWidth * markerPos - 6,
            top: -3,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _bg, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
              ),
            ),
          ),
        ],
      );
    });
  }

  // 3. Alert Banner
  Widget _buildAlertBanner() {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _yellow.withValues(alpha: 0.1),
          border: Border.all(color: _yellow.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: _yellow, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '⚠️  $_alertMessage',
                style: const TextStyle(color: _yellow, fontSize: 13, height: 1.4),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _yellow, size: 18),
          ],
        ),
      ),
    );
  }

  // 4. Three sensor cards
  Widget _buildSensorRow() {
    return Row(
      children: [
        Expanded(child: _sensorCard('MQ135', '$_mq135Ppm ppm', _aqiStatus, _yellow)),
        const SizedBox(width: 8),
        Expanded(child: _sensorCard('Temperature', '${_temperature.toStringAsFixed(1)} °C', 'Normal', _accent)),
        const SizedBox(width: 8),
        Expanded(child: _sensorCard('Humidity', '${_humidity.toStringAsFixed(0)}%', 'Good', _accent)),
      ],
    );
  }

  Widget _sensorCard(String label, String value, String status, Color statusColor) {
    return _card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _textDim, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Line Chart Card
  Widget _buildChartCard() {
    final spots = [
      const FlSpot(0, 95),
      const FlSpot(1, 88),
      const FlSpot(2, 102),
      const FlSpot(3, 78),
      const FlSpot(4, 85),
      const FlSpot(5, 82),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AQI Trend – Last 6 Hours',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: _cardBorder, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(color: _textDim, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        const labels = ['6h ago', '5h', '4h', '3h', '2h', 'Now'];
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(labels[i],
                              style: const TextStyle(color: _textDim, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: _accent,
                        strokeColor: _bg,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _accent.withValues(alpha: 0.25),
                          _accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                minX: 0,
                maxX: 5,
                minY: 60,
                maxY: 120,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Bottom row
  Widget _buildBottomRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildMapPlaceholder()),
          const SizedBox(width: 8),
          Expanded(child: _buildDeviceStatus()),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 2),
      child: _card(
        padding: EdgeInsets.zero,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0b1a14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.map_rounded, color: _cardBorder, size: 40),
              SizedBox(height: 8),
              Icon(Icons.location_pin, color: _accent, size: 28),
              SizedBox(height: 6),
              Text('Live Map', style: TextStyle(color: _textDim, fontSize: 12)),
              Text('Tap to view map', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceStatus() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _statusRow('ESP8266',  _isEspOnline ? 'Online' : 'Offline', _isEspOnline ? _accent : _red),
          const SizedBox(height: 10),
          _statusRow('Backend',  'Connected', _accent),
          const SizedBox(height: 10),
          _statusRow('Battery',  '$_battery%',       _yellow),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color badgeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _textDim, fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            value,
            style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // 7. Bottom Nav Bar
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item   = _navItems[i];
              final active = i == _selectedIndex;
              final color  = active ? _accent : _textDim;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = i);
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: color, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Helper: card container
  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: child,
    );
  }
}
