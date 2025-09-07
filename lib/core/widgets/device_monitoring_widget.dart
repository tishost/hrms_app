import 'package:flutter/material.dart';
import '../utils/analytics_helper.dart';
import '../utils/app_colors.dart';

class DeviceMonitoringWidget extends StatefulWidget {
  const DeviceMonitoringWidget({super.key});

  @override
  State<DeviceMonitoringWidget> createState() => _DeviceMonitoringWidgetState();
}

class _DeviceMonitoringWidgetState extends State<DeviceMonitoringWidget> {
  Map<String, dynamic>? _deviceStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceStats();
  }

  Future<void> _loadDeviceStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await AnalyticsHelper.getDeviceStats();
      setState(() {
        _deviceStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _deviceStats = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.device_hub, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Device Monitoring',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadDeviceStats,
                  icon: Icon(Icons.refresh, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_deviceStats != null)
              _buildDeviceStats()
            else
              const Text('No device data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStats() {
    if (_deviceStats!.containsKey('error')) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error: ${_deviceStats!['error']}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        _buildStatRow('Device Type', _deviceStats!['device_type'] ?? 'Unknown'),
        _buildStatRow('Platform', _deviceStats!['platform'] ?? 'Unknown'),
        _buildStatRow(
          'OS Version',
          _deviceStats!['platform_version'] ?? 'Unknown',
        ),
        _buildStatRow('App Version', _deviceStats!['app_version'] ?? 'Unknown'),
        _buildStatRow(
          'Build Number',
          _deviceStats!['build_number'] ?? 'Unknown',
        ),
        _buildStatRow('Is Emulator', _deviceStats!['is_emulator'] ?? 'Unknown'),
        _buildStatRow('Timestamp', _deviceStats!['timestamp'] ?? 'Unknown'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: AppColors.text, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
