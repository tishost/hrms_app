import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/global_otp_settings.dart';

import 'dart:async'; // Added for Timer

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isLoading = false;
  bool _isOtpEnabled = true; // Add OTP status

  @override
  void initState() {
    super.initState();
    _checkOtpStatus();

    // Listen for OTP settings changes
    _setupOtpSettingsListener();
  }

  void _setupOtpSettingsListener() {
    // Refresh OTP status every 30 seconds
    Timer.periodic(Duration(seconds: 30), (timer) async {
      if (mounted) {
        await _checkOtpStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkOtpStatus() async {
    try {
      bool isOtpRequired = GlobalOtpSettings.isOtpRequiredFor('registration');
      setState(() {
        _isOtpEnabled = isOtpRequired;
      });
    } catch (e) {
      print('Error checking OTP status: $e');
      setState(() {
        _isOtpEnabled = true; // Default to enabled
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add a small delay to show loading state
      await Future.delayed(Duration(milliseconds: 500));

      // Use global OTP settings (already loaded in splash screen)
      bool isOtpRequired = GlobalOtpSettings.isOtpRequiredFor('registration');

      print(
        'OTP required for registration (from global settings): $isOtpRequired',
      );

      if (isOtpRequired) {
        // Navigate to phone entry for OTP verification
        Navigator.of(context).pushNamed('/phone-entry');
      } else {
        // Skip OTP and go directly to registration
        Navigator.of(context).pushNamed(
          '/owner-registration',
          arguments: {
            'verifiedPhone': '',
          }, // Empty phone since OTP is not required
        );
      }
    } catch (e) {
      print('Error in signup: $e');
      // If error occurs, default to OTP flow
      Navigator.of(context).pushNamed('/phone-entry');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            // Simple back navigation
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Welcome',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.apartment,
                    color: AppColors.white,
                    size: 50,
                  ),
                ),
                SizedBox(height: 32),
                // Welcome Text
                Text(
                  'Welcome to HRMS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Property Management System',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                // OTP Status Indicator
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isOtpEnabled
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isOtpEnabled
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOtpEnabled ? Icons.security : Icons.check_circle,
                        color: _isOtpEnabled ? AppColors.primary : Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _isOtpEnabled
                            ? 'OTP Verification Required'
                            : 'Quick Registration (No OTP)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _isOtpEnabled
                              ? AppColors.primary
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Information Section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isOtpEnabled
                        ? AppColors.primary.withOpacity(0.05)
                        : Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isOtpEnabled
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isOtpEnabled ? Icons.info : Icons.speed,
                            color: _isOtpEnabled
                                ? AppColors.primary
                                : Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _isOtpEnabled
                                ? 'Secure Registration'
                                : 'Fast Registration',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isOtpEnabled
                                  ? AppColors.primary
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _isOtpEnabled
                            ? 'Your phone number will be verified with OTP for security'
                            : 'Registration is simplified for faster access',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isOtpEnabled
                          ? AppColors.primary
                          : Colors.green,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isOtpEnabled
                                    ? Icons.security
                                    : Icons.rocket_launch,
                                color: AppColors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _isOtpEnabled
                                    ? 'Sign Up with OTP'
                                    : 'Quick Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 24),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                // Features
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Why Choose HRMS?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.home,
                        title: 'Property Management',
                        description: 'Manage multiple properties efficiently',
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        icon: Icons.people,
                        title: 'Tenant Management',
                        description: 'Track tenants and their details',
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        icon: Icons.payment,
                        title: 'Rent Collection',
                        description: 'Automated rent collection and tracking',
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        icon: _isOtpEnabled ? Icons.security : Icons.speed,
                        title: _isOtpEnabled
                            ? 'Secure Verification'
                            : 'Fast Access',
                        description: _isOtpEnabled
                            ? 'Phone verification for account security'
                            : 'Quick registration without verification delays',
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        icon: Icons.security,
                        title: 'Secure & Reliable',
                        description: 'Your data is safe with us',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
