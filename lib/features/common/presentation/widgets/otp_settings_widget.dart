import 'package:flutter/material.dart';
import 'package:hrms_app/core/utils/app_colors.dart';

class OtpSettingsWidget extends StatefulWidget {
  @override
  _OtpSettingsWidgetState createState() => _OtpSettingsWidgetState();
}

class _OtpSettingsWidgetState extends State<OtpSettingsWidget> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // TODO: Implement OTP settings service
      // final settings = await OtpSettingsService.getOtpSettings();
      setState(() {
        _settings = {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Update local state
      setState(() {
        _settings[key] = value;
      });

      // Clear cache to force refresh
      // OtpSettingsService.clearCache();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setting updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update setting'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OTP Verification Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Master Toggle
            SwitchListTile(
              title: Text('Enable OTP System'),
              subtitle: Text('Master switch for OTP verification'),
              value: _settings['is_enabled'] ?? true,
              onChanged: _isUpdating
                  ? null
                  : (value) {
                      _updateSetting('is_enabled', value);
                    },
            ),

            Divider(),

            // Feature Toggles
            Text(
              'Feature Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),

            SwitchListTile(
              title: Text('Registration OTP'),
              subtitle: Text('Require OTP for user registration'),
              value: _settings['require_otp_for_registration'] ?? true,
              onChanged: _isUpdating
                  ? null
                  : (value) {
                      _updateSetting('require_otp_for_registration', value);
                    },
            ),

            SwitchListTile(
              title: Text('Login OTP'),
              subtitle: Text('Require OTP for user login'),
              value: _settings['require_otp_for_login'] ?? false,
              onChanged: _isUpdating
                  ? null
                  : (value) {
                      _updateSetting('require_otp_for_login', value);
                    },
            ),

            SwitchListTile(
              title: Text('Password Reset OTP'),
              subtitle: Text('Require OTP for password reset'),
              value: _settings['require_otp_for_password_reset'] ?? true,
              onChanged: _isUpdating
                  ? null
                  : (value) {
                      _updateSetting('require_otp_for_password_reset', value);
                    },
            ),

            Divider(),

            // Configuration
            Text(
              'Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),

            ListTile(
              title: Text('OTP Length'),
              subtitle: Text('${_settings['otp_length'] ?? 6} digits'),
              trailing: Text('${_settings['otp_length'] ?? 6}'),
            ),

            ListTile(
              title: Text('Expiry Time'),
              subtitle: Text('OTP validity period'),
              trailing: Text('${_settings['otp_expiry_minutes'] ?? 10} min'),
            ),

            ListTile(
              title: Text('Max Attempts'),
              subtitle: Text('Maximum failed attempts'),
              trailing: Text('${_settings['max_attempts'] ?? 3}'),
            ),

            ListTile(
              title: Text('Resend Cooldown'),
              subtitle: Text('Wait time before resend'),
              trailing: Text('${_settings['resend_cooldown_seconds'] ?? 60}s'),
            ),

            SizedBox(height: 16),

            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating
                    ? null
                    : () {
                        // OtpSettingsService.clearCache();
                        _loadSettings();
                      },
                child: Text('Refresh Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
