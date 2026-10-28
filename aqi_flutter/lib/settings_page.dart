import 'dart:async';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/iot_service.dart';
import 'services/api_config.dart';
import 'services/server_config_dialog.dart';
import 'login_page.dart';

const _bg         = Color(0xFF0d1f1a);
const _accent     = Color(0xFF4ade80);
const _cardBg     = Color(0xFF132a1f);
const _cardBorder = Color(0xFF1e4030);
const _yellow     = Color(0xFFFACC15);
const _red        = Color(0xFFEF4444);
const _textDim    = Color(0xFF9CA3AF);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifAQI      = true;
  bool _notifCO2      = true;
  bool _notifDevice   = false;
  bool _darkMode      = true;
  bool _autoRefresh   = true;
  String _refreshRate = 'Every 5 min';
  String _aqiUnit     = 'US AQI';

  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _activities = [];
  Timer? _activityTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchActivities();
    _activityTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _fetchActivities();
    });
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _fetchActivities() async {
    final list = await IotService.fetchAuthActivities();
    if (mounted) {
      setState(() => _activities = list);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('Notifications'),
            const SizedBox(height: 10),
            _buildCard(children: [
              _buildToggle(
                icon: Icons.air_rounded,
                label: 'AQI Alerts',
                subtitle: 'Notify when AQI exceeds 100',
                value: _notifAQI,
                onChanged: (v) => setState(() => _notifAQI = v),
              ),
              _divider(),
              _buildToggle(
                icon: Icons.co2_rounded,
                label: 'CO₂ Alerts',
                subtitle: 'Notify when CO₂ exceeds 1000 ppm',
                value: _notifCO2,
                onChanged: (v) => setState(() => _notifCO2 = v),
              ),
              _divider(),
              _buildToggle(
                icon: Icons.wifi_rounded,
                label: 'Device Status',
                subtitle: 'Notify on ESP8266 disconnect',
                value: _notifDevice,
                onChanged: (v) => setState(() => _notifDevice = v),
              ),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('Display'),
            const SizedBox(height: 10),
            _buildCard(children: [
              _buildToggle(
                icon: Icons.dark_mode_rounded,
                label: 'Dark Mode',
                subtitle: 'Always on dark theme',
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
              ),
              _divider(),
              _buildToggle(
                icon: Icons.refresh_rounded,
                label: 'Auto Refresh',
                subtitle: 'Automatically refresh sensor data',
                value: _autoRefresh,
                onChanged: (v) => setState(() => _autoRefresh = v),
              ),
              _divider(),
              _buildDropdown(
                icon: Icons.timer_outlined,
                label: 'Refresh Rate',
                value: _refreshRate,
                options: ['Every 1 min', 'Every 5 min', 'Every 10 min', 'Every 30 min'],
                onChanged: (v) => setState(() => _refreshRate = v!),
              ),
              _divider(),
              _buildDropdown(
                icon: Icons.straighten_rounded,
                label: 'AQI Standard',
                value: _aqiUnit,
                options: ['US AQI', 'EU AQI', 'China AQI', 'India NAQI'],
                onChanged: (v) => setState(() => _aqiUnit = v!),
              ),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('Device'),
            const SizedBox(height: 10),
            _buildCard(children: [
              _buildInfoRow(Icons.memory_rounded, 'ESP8266 Node', 'Online', _accent),
              _divider(),
              _buildInfoRow(Icons.dns_rounded, 'Server Base URL', ApiConfig.baseUrl, _accent),
              _divider(),
              _buildActionRow(Icons.settings_ethernet_rounded, 'Configure Server IP', _accent, onTap: () {
                ServerConfigDialog.show(context).then((_) => setState(() {}));
              }),
              _divider(),
              _buildInfoRow(Icons.battery_5_bar_rounded, 'Battery', '85%', _yellow),
              _divider(),
              _buildInfoRow(Icons.sensors_rounded, 'MQ135 Gas Sensor', 'Active', _accent),
              _divider(),
              _buildActionRow(Icons.sync_rounded, 'Sync Device Now', _accent, onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device synchronized!'), behavior: SnackBarBehavior.floating),
                );
              }),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('Live User Activity (Login / Logout)'),
            const SizedBox(height: 10),
            _buildActivityLogCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('About'),
            const SizedBox(height: 10),
            _buildCard(children: [
              _buildInfoRow(Icons.info_outline_rounded,      'App Version', '1.0.0',             _textDim),
              _divider(),
              _buildInfoRow(Icons.code_rounded,              'Built With',  'Flutter + ESP8266', _textDim),
              _divider(),
              _buildActionRow(Icons.privacy_tip_outlined,    'Privacy Policy',                   _textDim),
              _divider(),
              _buildActionRow(Icons.help_outline_rounded,    'Help & Support',                   _textDim),
            ]),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Settings & Activity',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = _currentUser?['name'] ?? 'Arjun Sharma';
    final email = _currentUser?['email'] ?? 'arjun@breathepure.io';
    final mobile = _currentUser?['mobile'] ?? '+91 98765 43210';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withValues(alpha: 0.15),
              border: Border.all(color: _accent.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.person_rounded, color: _accent, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 3),
                Text(email,
                    style: const TextStyle(color: _textDim, fontSize: 13)),
                const SizedBox(height: 3),
                Text(mobile,
                    style: const TextStyle(color: _textDim, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 4, backgroundColor: _accent),
                SizedBox(width: 5),
                Text('Active', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogCard() {
    if (_activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
        ),
        child: const Center(
          child: Text(
            'No user sessions recorded yet.',
            style: TextStyle(color: _textDim, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activities.take(6).length,
        separatorBuilder: (_, _) => _divider(),
        itemBuilder: (context, index) {
          final act = _activities[index];
          final type = (act['type'] ?? 'EVENT') as String;
          final userName = (act['userName'] ?? 'User') as String;
          final email = (act['userEmail'] ?? '') as String;
          final timeStr = (act['timestamp'] ?? '') as String;
          
          DateTime? dt = DateTime.tryParse(timeStr);
          final timeFormatted = dt != null 
              ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}'
              : 'Just now';

          Color badgeColor;
          IconData icon;
          String label;

          if (type == 'LOGIN') {
            badgeColor = _accent;
            icon = Icons.login_rounded;
            label = 'LOGGED IN';
          } else if (type == 'LOGOUT') {
            badgeColor = _red;
            icon = Icons.logout_rounded;
            label = 'LOGGED OUT';
          } else if (type == 'SIGNUP') {
            badgeColor = _yellow;
            icon = Icons.person_add_alt_1_rounded;
            label = 'NEW SIGNUP';
          } else {
            badgeColor = Colors.orange;
            icon = Icons.warning_amber_rounded;
            label = type;
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: badgeColor, size: 18),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  email.isNotEmpty ? email : 'App user',
                  style: const TextStyle(color: _textDim, fontSize: 12),
                ),
                Text(
                  timeFormatted,
                  style: TextStyle(color: _textDim.withValues(alpha: 0.8), fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _textDim,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: _textDim, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _accent,
            activeTrackColor: _accent.withValues(alpha: 0.3),
            inactiveThumbColor: _textDim,
            inactiveTrackColor: _cardBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 14))),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            dropdownColor: _cardBg,
            underline: const SizedBox(),
            style: const TextStyle(color: _accent, fontSize: 13),
            icon: const Icon(Icons.expand_more_rounded, color: _textDim, size: 18),
            items: options
                .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o, style: const TextStyle(color: _accent))))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: _textDim, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 14))),
            const Icon(Icons.chevron_right_rounded, color: _cardBorder, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(color: _cardBorder, height: 1, indent: 14, endIndent: 14);

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to log out?',
                style: TextStyle(color: _textDim)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: _textDim)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AQILoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Log Out', style: TextStyle(color: _red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _red.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: _red, size: 20),
            SizedBox(width: 10),
            Text('Log Out',
                style: TextStyle(
                    color: _red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
