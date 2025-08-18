import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:hrms_app/core/services/security_service.dart';
import 'dart:convert';
import 'package:hrms_app/core/services/api_service.dart';

class TenantRegistrationScreen extends ConsumerStatefulWidget {
  const TenantRegistrationScreen({super.key});

  @override
  ConsumerState<TenantRegistrationScreen> createState() =>
      _TenantRegistrationScreenState();
}

class _TenantRegistrationScreenState
    extends ConsumerState<TenantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  Map<String, dynamic>? _tenantInfo;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tenant Registration'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Message
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_add, size: 48, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text(
                      'Welcome to Tenant Portal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please enter your mobile number to register',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Mobile Number Input
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid mobile number';
                  }
                  return null;
                },
                enabled: !_otpSent,
              ),
              SizedBox(height: 16),

              // Request OTP Button
              if (!_otpSent)
                ElevatedButton(
                  onPressed: _isLoading ? null : _requestOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Request OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

              // OTP Input (after OTP sent)
              if (_otpSent) ...[
                TextFormField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    hintText: '6 digit OTP',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter OTP';
                    }
                    if (value.length != 6) {
                      return 'OTP must be 6 digits';
                    }
                    return null;
                  },
                  enabled: !_otpVerified,
                ),
                SizedBox(height: 16),

                // Verify OTP Button
                if (!_otpVerified)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Verify OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                // Tenant Info Card (after OTP verified)
                if (_otpVerified && _tenantInfo != null) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'OTP Verified Successfully!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Name: ${_tenantInfo!['name']}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Property: ${_tenantInfo!['property_name'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Unit: ${_tenantInfo!['unit_name'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Password Fields
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Create Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),

                  // Complete Registration Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Complete Registration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Requesting OTP for mobile: ${_mobileController.text}');
      print('DEBUG: API URL: ${ApiConfig.getApiUrl('/tenant/request-otp')}');

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/send-otp',
        data: {
          'phone': _mobileController.text,
          'type': 'profile_update',
          'user_id': (await SecurityService.getStoredUserData())?['id'],
        },
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response data: ${response.data}');

      final data = response.data;

      print('🔍 DEBUG: Response status: ${response.statusCode}');
      print('🔍 DEBUG: Response data: $data');

      if (response.statusCode == 200) {
        setState(() {
          _otpSent = true;
          _tenantInfo = data['tenant'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully! Check your mobile.'),
            backgroundColor: Colors.green,
          ),
        );

        // Show OTP in debug mode
        print('DEBUG: OTP = ${data['otp']}');
        print('DEBUG: Tenant info = ${data['tenant']}');
      } else if (response.statusCode == 429) {
        print('🔍 DEBUG: 429 status detected - Daily limit reached');
        // Daily limit reached - show dialog
        final responseData = response.data;
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (_) {}

        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text('Daily Limit Reached'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📱 You have reached the daily OTP limit for this phone number.',
                ),
                SizedBox(height: 16),
                Text('⏰ Please try again tomorrow.'),
                SizedBox(height: 8),
                Text('📞 Contact admin if you need immediate assistance.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        print('🔍 DEBUG: Non-200, non-429 response detected');
        print('DEBUG: Error response: $data');
        final errorMsg = data['error'] ?? 'Failed to send OTP';
        print('🔍 DEBUG: Error message: $errorMsg');
        print('🔍 DEBUG: Error type: ${data['error_type']}');

        final isDailyLimit =
            data['error_type'] == 'daily_limit' ||
            errorMsg.contains('daily_limit') ||
            errorMsg.contains('Daily OTP limit reached') ||
            errorMsg.contains('429') ||
            errorMsg.contains('HTTP 429');

        print('🔍 DEBUG: Is daily limit: $isDailyLimit');

        if (isDailyLimit) {
          // Show user-friendly daily limit dialog
          try {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          } catch (_) {}

          showDialog(
            context: context,
            useRootNavigator: true,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text('Daily Limit Reached'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 You have reached the daily OTP limit for this phone number.',
                  ),
                  SizedBox(height: 16),
                  Text('⏰ Please try again tomorrow.'),
                  SizedBox(height: 8),
                  Text('📞 Contact admin if you need immediate assistance.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('🔍 DEBUG: Exception in _requestOtp: $e');
      print('🔍 DEBUG: Exception type: ${e.runtimeType}');
      final errorMsg = e.toString();
      print('🔍 DEBUG: Exception error message: $errorMsg');

      final isDailyLimit =
          errorMsg.contains('daily_limit') ||
          errorMsg.contains('Daily OTP limit reached') ||
          errorMsg.contains('429') ||
          errorMsg.contains('HTTP 429') ||
          errorMsg.contains('Client error') ||
          errorMsg.contains('status code of 429');

      print('🔍 DEBUG: Is daily limit: $isDailyLimit');

      if (isDailyLimit) {
        // Show user-friendly daily limit dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text('Daily Limit Reached'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📱 You have reached the daily OTP limit for this phone number.',
                ),
                SizedBox(height: 16),
                Text('⏰ Please try again tomorrow.'),
                SizedBox(height: 8),
                Text('📞 Contact admin if you need immediate assistance.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Verifying OTP for mobile: ${_mobileController.text}');
      print('DEBUG: OTP entered: ${_otpController.text}');

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/verify-otp',
        data: {
          'phone': _mobileController.text,
          'otp': _otpController.text,
          'type': 'profile_update',
          'user_id': (await SecurityService.getStoredUserData())?['id'],
        },
      );

      print('DEBUG: Verify response status: ${response.statusCode}');
      print('DEBUG: Verify response data: ${response.data}');

      final data = response.data;

      if (response.statusCode == 200) {
        setState(() {
          _otpVerified = true;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ OTP verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('DEBUG: Verify error: $data');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to verify OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Exception in _verifyOtp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print(
        'DEBUG: Completing registration for mobile: ${_mobileController.text}',
      );

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/tenant/register',
        data: {
          'phone': _mobileController.text,
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
          'user_id': (await SecurityService.getStoredUserData())?['id'],
        },
      );

      print('DEBUG: Registration response status: ${response.statusCode}');
      print('DEBUG: Registration response data: ${response.data}');

      final data = response.data;

      if (response.statusCode == 200) {
        // Save token
        await AuthService.saveToken(data['token']);

        // Update authentication state
        await ref
            .read(authStateProvider.notifier)
            .login(data['token'], 'tenant');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to tenant dashboard
        context.go('/tenant-dashboard');
      } else {
        print('DEBUG: Registration error: $data');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to complete registration'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Exception in _completeRegistration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
