import 'package:flutter/material.dart';

const _bg         = Color(0xFF0d1f1a);
const _accent     = Color(0xFF4ade80);
const _cardBg     = Color(0xFF132a1f);
const _cardBorder = Color(0xFF1e4030);
const _yellow     = Color(0xFFFACC15);
const _red        = Color(0xFFEF4444);
const _textDim    = Color(0xFF9CA3AF);

// ── Dummy data ────────────────────────────────────────────────────────────────
class _Reading {
  final String date;
  final String time;
  final int aqi;
  final int ppm;
  const _Reading(this.date, this.time, this.aqi, this.ppm);
}

const _todayData = [
  _Reading('Today', '08:00 AM', 72, 318),
  _Reading('Today', '10:00 AM', 85, 342),
  _Reading('Today', '12:00 PM', 102, 390),
  _Reading('Today', '02:00 PM', 91, 361),
  _Reading('Today', '04:00 PM', 78, 330),
  _Reading('Today', '06:00 PM', 63, 298),
  _Reading('Today', '08:00 PM', 82, 340),
];

const _weekData = [
  _Reading('Sep 01', '09:00 AM', 55, 275),
  _Reading('Sep 01', '06:00 PM', 68, 310),
  _Reading('Sep 02', '09:00 AM', 143, 430),
  _Reading('Sep 02', '06:00 PM', 130, 415),
  _Reading('Sep 03', '09:00 AM', 95, 370),
  _Reading('Sep 03', '06:00 PM', 88, 349),
  _Reading('Sep 04', '09:00 AM', 47, 260),
  _Reading('Sep 04', '06:00 PM', 52, 271),
  _Reading('Sep 05', '09:00 AM', 110, 400),
  _Reading('Sep 05', '06:00 PM', 99, 378),
  _Reading('Sep 06', '09:00 AM', 76, 325),
  _Reading('Sep 06', '06:00 PM', 82, 340),
];

const _monthData = [
  _Reading('Aug 10', '09:00 AM', 60, 290),
  _Reading('Aug 12', '09:00 AM', 155, 450),
  _Reading('Aug 14', '09:00 AM', 48, 265),
  _Reading('Aug 16', '09:00 AM', 122, 408),
  _Reading('Aug 18', '09:00 AM', 88, 349),
  _Reading('Aug 20', '09:00 AM', 73, 319),
  _Reading('Aug 22', '09:00 AM', 200, 510),
  _Reading('Aug 24', '09:00 AM', 35, 235),
  _Reading('Aug 26', '09:00 AM', 98, 375),
  _Reading('Aug 28', '09:00 AM', 142, 428),
  _Reading('Aug 30', '09:00 AM', 67, 305),
  _Reading('Sep 01', '09:00 AM', 55, 275),
  _Reading('Sep 03', '09:00 AM', 95, 370),
  _Reading('Sep 05', '09:00 AM', 110, 400),
  _Reading('Sep 07', '09:00 AM', 82, 340),
];

// ── Helpers ───────────────────────────────────────────────────────────────────
String _statusLabel(int aqi) {
  if (aqi <= 50)  return 'Good';
  if (aqi <= 100) return 'Moderate';
  if (aqi <= 150) return 'Unhealthy (Sensitive)';
  if (aqi <= 200) return 'Unhealthy';
  return 'Very Unhealthy';
}

Color _aqiColor(int aqi) {
  if (aqi <= 50)  return _accent;
  if (aqi <= 100) return _yellow;
  if (aqi <= 150) return const Color(0xFFF97316); // orange
  return _red;
}

// ── Screen ────────────────────────────────────────────────────────────────────
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _filterIndex = 0; // 0=Today, 1=This Week, 2=This Month

  static const _filters = ['Today', 'This Week', 'This Month'];

  List<_Reading> get _currentData =>
      [_todayData, _weekData, _monthData][_filterIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildFilterRow(),
            const SizedBox(height: 4),
            _buildSummaryBar(),
            const Divider(color: _cardBorder, thickness: 1, height: 1),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // 1. Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: _accent, size: 20),
          ),
        ],
      ),
    );
  }

  // 2. Filter pill row
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_filters.length, (i) {
          final active = i == _filterIndex;
          return Padding(
            padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? _accent : _cardBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: active ? _accent : _cardBorder,
                  ),
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    color: active ? Colors.black : _textDim,
                    fontWeight:
                        active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Summary bar (avg AQI + count)
  Widget _buildSummaryBar() {
    final data = _currentData;
    final avg = data.isEmpty
        ? 0
        : (data.map((e) => e.aqi).reduce((a, b) => a + b) / data.length)
            .round();
    final avgColor = _aqiColor(avg);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _summaryChip(Icons.air_rounded, 'Avg AQI', avg.toString(), avgColor),
          const SizedBox(width: 10),
          _summaryChip(Icons.list_alt_rounded, 'Readings',
              data.length.toString(), _accent),
          const SizedBox(width: 10),
          _summaryChip(
              Icons.trending_up_rounded,
              'Peak AQI',
              data.isEmpty
                  ? '0'
                  : data.map((e) => e.aqi).reduce((a, b) => a > b ? a : b).toString(),
              _red),
        ],
      ),
    );
  }

  Widget _summaryChip(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text(label,
                style:
                    const TextStyle(color: _textDim, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // 3. Reading list
  Widget _buildList() {
    final data = _currentData;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: data.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildReadingCard(data[i]),
    );
  }

  Widget _buildReadingCard(_Reading r) {
    final color  = _aqiColor(r.aqi);
    final status = _statusLabel(r.aqi);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          // Left: icon + date/time
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.air_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.date,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(r.time,
                    style: const TextStyle(
                        color: _textDim, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // MQ135 ppm
                    Text(
                      'MQ135: ${r.ppm} ppm',
                      style: const TextStyle(
                          color: _textDim, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: AQI value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                r.aqi.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('AQI',
                  style: const TextStyle(
                      color: _textDim, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
