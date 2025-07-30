import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/auth/presentation/screens/owner_registration_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isLoading = true; // Add loading state
  int _otpTimer = 0;
  String? _verifiedPhone;
  int _otpLength = 6;
  int _resendCooldown = 60;

  @override
  void initState() {
    super.initState();
    _loadOtpSettings();
    _startOtpTimer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadOtpSettings() async {
    try {
      // Use global OTP settings (already loaded in splash screen)
      bool isOtpRequired = GlobalOtpSettings.isOtpRequiredFor('registration');

      print(
        'OTP required for registration (from global settings): $isOtpRequired',
      );

      if (!isOtpRequired) {
        // If OTP is not required, skip to registration
        print('OTP not required, skipping to registration');

        // Navigate without showing this screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/owner-registration',
            arguments: {'verifiedPhone': ''},
          );
        }
        return;
      }

      // Load OTP configuration from server
      _otpLength = await OtpSettingsService.getOtpLength();
      _resendCooldown = await OtpSettingsService.getResendCooldownSeconds();

      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading to false after settings loaded
        });
      }
    } catch (e) {
      print('Error loading OTP settings: $e');
      // If error, continue with OTP flow
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startOtpTimer() {
    if (_otpTimer > 0) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _otpTimer--;
          });
          _startOtpTimer();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen if still loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

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
          'Phone Verification',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 8),
                    Center(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.border,
                        child: Icon(
                          Icons.phone_android,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isOtpSent ? 'Enter OTP' : 'Enter Phone Number',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isOtpSent
                          ? 'We sent a 6-digit code to ${_phoneController.text}'
                          : 'We\'ll send you a verification code',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    if (!_isOtpSent) ...[
                      _buildPhoneField(),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _otpTimer > 0 || _isSendingOtp
                            ? null
                            : _sendOtp,
                        child: _isSendingOtp
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
                            : Text(
                                _otpTimer > 0
                                    ? 'Resend in ${_otpTimer}s'
                                    : 'Send OTP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ] else ...[
                      _buildOtpField(),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isVerifyingOtp ? null : _verifyOtp,
                        child: _isVerifyingOtp
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
                            : Text(
                                'Verify OTP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: _otpTimer > 0 ? null : _resendOtp,
                          child: Text(
                            _otpTimer > 0
                                ? 'Resend OTP in ${_otpTimer}s'
                                : 'Resend OTP',
                            style: TextStyle(
                              color: _otpTimer > 0
                                  ? AppColors.gray
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isOtpSent = false;
                              _otpController.clear();
                            });
                          },
                          child: Text(
                            'Change Phone Number',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.phone, color: AppColors.hint, size: 22),
        hintText: 'Enter phone number',
        hintStyle: TextStyle(
          color: AppColors.hint,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
      onChanged: (_) {
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        if (value.length < 8) {
          return 'Enter a valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildOtpField() {
    return TextFormField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: _otpLength,
      style: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.security, color: AppColors.hint, size: 22),
        hintText: 'Enter $_otpLength-digit OTP',
        hintStyle: TextStyle(
          color: AppColors.hint,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
        ),
        counterText: '',
      ),
      onChanged: (_) {
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter OTP';
        }
        if (value.length != _otpLength) {
          return 'OTP must be $_otpLength digits';
        }
        return null;
      },
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final response = await AuthService.sendOtp(
        _phoneController.text.trim(),
        'registration',
      );

      setState(() {
        _isOtpSent = true;
        _otpTimer = _resendCooldown; // Use dynamic cooldown
      });

      _startOtpTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent successfully! Check your phone.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final response = await AuthService.verifyOtp(
        _phoneController.text.trim(),
        _otpController.text.trim(),
        'registration',
      );

      setState(() {
        _verifiedPhone = _phoneController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone verified successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to registration form with verified phone
      Navigator.of(context).pushNamed(
        '/owner-registration',
        arguments: {'verifiedPhone': _verifiedPhone!},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isVerifyingOtp = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isSendingOtp = true;
    });

    try {
      final response = await AuthService.resendOtp(
        _phoneController.text.trim(),
        'registration',
      );

      setState(() {
        _otpTimer = _resendCooldown; // Use dynamic cooldown
      });

      _startOtpTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP resent successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }
}
