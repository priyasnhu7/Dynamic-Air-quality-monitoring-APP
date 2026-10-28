import 'package:flutter/material.dart';

const _bg         = Color(0xFF0d1f1a);
const _accent     = Color(0xFF4ade80);
const _cardBg     = Color(0xFF132a1f);
const _cardBorder = Color(0xFF1e4030);
const _yellow     = Color(0xFFFACC15);
const _red        = Color(0xFFEF4444);
const _orange     = Color(0xFFF97316);
const _textDim    = Color(0xFF9CA3AF);

class _Location {
  final String name;
  final String area;
  final int aqi;
  final double top;
  final double left;
  const _Location(this.name, this.area, this.aqi, this.top, this.left);
}

const _locations = [
  _Location('Home', 'Koramangala',    82,  0.38, 0.50),
  _Location('Work', 'Indiranagar',    55,  0.25, 0.65),
  _Location('Park', 'Cubbon Park',   143,  0.55, 0.38),
  _Location('Mall', 'Whitefield',     99,  0.42, 0.72),
  _Location('Lake', 'Ulsoor',         38,  0.28, 0.42),
];

Color _aqiColor(int aqi) {
  if (aqi <= 50)  return _accent;
  if (aqi <= 100) return _yellow;
  if (aqi <= 150) return _orange;
  return _red;
}

String _aqiLabel(int aqi) {
  if (aqi <= 50)  return 'Good';
  if (aqi <= 100) return 'Moderate';
  if (aqi <= 150) return 'Unhealthy*';
  return 'Unhealthy';
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMapArea()),
            _buildLegend(),
            if (_selected != null) _buildInfoCard(_locations[_selected!]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Air Quality Map',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.layers_rounded, color: _accent, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Map background grid
            Container(
              decoration: const BoxDecoration(color: Color(0xFF0b1a14)),
              child: CustomPaint(
                painter: _GridPainter(),
                child: const SizedBox.expand(),
              ),
            ),
            // Road lines (decorative)
            CustomPaint(
              painter: _RoadPainter(),
              child: const SizedBox.expand(),
            ),
            // Location pins
            ..._locations.asMap().entries.map((e) {
              final i   = e.key;
              final loc = e.value;
              final color = _aqiColor(loc.aqi);
              return Positioned.fill(
                child: LayoutBuilder(builder: (context, constraints) {
                  return Stack(children: [
                    Positioned(
                      top: constraints.maxHeight * loc.top - 28,
                      left: constraints.maxWidth  * loc.left - 22,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = _selected == i ? null : i),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _selected == i ? color : color.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
                                ],
                              ),
                              child: Text(
                                '${loc.aqi}',
                                style: TextStyle(
                                  color: _selected == i ? Colors.black : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            CustomPaint(
                              painter: _TrianglePainter(color),
                              size: const Size(10, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]);
                }),
              );
            }),
            // Center compass
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _cardBg.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: _cardBorder),
                ),
                child: const Icon(Icons.explore_rounded, color: _accent, size: 22),
              ),
            ),
            // "Map preview" label
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _cardBg.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cardBorder),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.map_rounded, color: _accent, size: 13),
                    SizedBox(width: 5),
                    Text('Bengaluru, India', style: TextStyle(color: _textDim, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(_accent, 'Good (0–50)'),
          _legendItem(_yellow, 'Moderate (51–100)'),
          _legendItem(_orange, 'Unhealthy* (101–150)'),
          _legendItem(_red,    'Unhealthy (151+)'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _textDim, fontSize: 9)),
      ],
    );
  }

  Widget _buildInfoCard(_Location loc) {
    final color = _aqiColor(loc.aqi);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(loc.area, style: const TextStyle(color: _textDim, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${loc.aqi}', style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
              Text(_aqiLabel(loc.aqi), style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// Grid painter for map background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1e4030).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// Road painter
class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1e4030)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final paint2 = Paint()
      ..color = const Color(0xFF1e4030)
      ..strokeWidth = 3;
    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.35), paint);
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.65), paint2);
    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), paint2);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.6, size.height), paint);
    // Diagonal
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width * 0.5, size.height * 0.2), paint2);
  }
  @override
  bool shouldRepaint(_) => false;
}

// Triangle for pin pointer
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path  = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}
