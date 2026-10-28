import 'package:flutter/material.dart';
import 'api_config.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final success = await ApiConfig.testConnection(_controller.text);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _isSuccess = success;
      if (success) {
        _testResult = 'Connected successfully to backend server!';
      } else {
        _testResult = 'Cannot reach server. Standalone Mode will be used.';
      }
    });
  }

  Future<void> _save() async {
    final newUrl = _controller.text.trim();
    if (newUrl.isNotEmpty) {
      await ApiConfig.setBaseUrl(newUrl);
    }
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server URL updated: ${ApiConfig.baseUrl}'),
          backgroundColor: const Color(0xFF4ade80),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF132a1f),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_rounded, color: Color(0xFF4ade80)),
                const SizedBox(width: 10),
                const Text(
                  'Backend Server Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your phone to the backend server running on your computer, or use offline Standalone Mode.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Server Base URL',
                labelStyle: const TextStyle(color: Color(0xFF4ade80)),
                hintText: 'https://https-breathepure-aqi-backend-onrender.onrender.com',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0d1f1a),
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF4ade80)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1e4030)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1e4030)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4ade80)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Quick Presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('PC Wi-Fi IP', ApiConfig.defaultLocalIp),
                _buildPresetChip('Localhost', ApiConfig.localhostIp),
                _buildPresetChip('Emulator', ApiConfig.emulatorIp),
              ],
            ),
            const SizedBox(height: 16),
            if (_testResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? const Color(0xFF4ade80).withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isSuccess
                        ? const Color(0xFF4ade80).withValues(alpha: 0.4)
                        : Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: _isSuccess ? const Color(0xFF4ade80) : Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _isSuccess ? const Color(0xFF4ade80) : Colors.orangeAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4ade80),
                      side: const BorderSide(color: Color(0xFF4ade80)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4ade80),
                            ),
                          )
                        : const Icon(Icons.network_check_rounded, size: 18),
                    label: Text(_isTesting ? 'Testing...' : 'Test Ping'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ade80),
                      foregroundColor: const Color(0xFF0d1f1a),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Save & Use',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final isSelected = _controller.text == url;
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF0d1f1a) : Colors.white70)),
      backgroundColor: isSelected ? const Color(0xFF4ade80) : const Color(0xFF0d1f1a),
      side: const BorderSide(color: Color(0xFF1e4030)),
      onPressed: () {
        setState(() {
          _controller.text = url;
          _testResult = null;
        });
      },
    );
  }
}
