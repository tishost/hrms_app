import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/services/api_service.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;

  const ResetPasswordScreen({super.key, this.extra});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpVerified = false;
  bool _isVerifyingOtp = false;
  bool _isResendingOtp = false;
  bool _canResend = false;
  int _resendCountdown = 300; // 5 minutes = 300 seconds
  Timer? _resendTimer;
  String? _identifier;
  List<String>? _methods;

  @override
  void initState() {
    super.initState();
    if (widget.extra != null) {
      _identifier = widget.extra!['identifier'];
      _methods = widget.extra!['methods']?.cast<String>();
    }

    // Listen to OTP input changes
    _otpController.addListener(_onOtpChanged);

    // Start countdown timer for resend button
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onOtpChanged() {
    final otp = _otpController.text.trim();
    if (otp.length == 6 && !_otpVerified && !_isVerifyingOtp) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final data = {
        'otp': _otpController.text.trim(),
        'identifier': _identifier,
      };

      final response = await apiService.post(
        '/verify-password-otp',
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success']) {
          setState(() {
            _otpVerified = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP verified successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Invalid OTP'),
              backgroundColor: Colors.red,
            ),
          );
          // Clear OTP field for retry
          _otpController.clear();
        }
      } else if (response.statusCode == 422) {
        final responseData = response.data;
        String errorMessage = 'Validation failed';

        if (responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          if (errors['otp'] != null) {
            errorMessage = errors['otp'][0];
          } else if (errors['email'] != null) {
            errorMessage = errors['email'][0];
          } else if (errors['mobile'] != null) {
            errorMessage = errors['mobile'][0];
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
        // Clear OTP field for retry
        _otpController.clear();
      }
    } catch (e) {
      // Handle network errors with user-friendly messages
      String errorMessage =
          'Unable to verify OTP. Please check your connection and try again.';

      String errorString = e.toString().toLowerCase();
      if (errorString.contains('422')) {
        errorMessage = 'Invalid OTP format. Please enter a valid 6-digit OTP.';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (errorString.contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      // Clear OTP field for retry
      _otpController.clear();
    } finally {
      setState(() {
        _isVerifyingOtp = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your new password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final data = {
        'otp': otp,
        'password': password,
        'password_confirmation': confirmPassword,
        'identifier': _identifier,
      };

      final response = await apiService.post('/reset-password', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Password reset successful',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to login
          context.go('/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Failed to reset password',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle network errors with user-friendly messages
      String errorMessage = 'Unable to reset password. Please try again.';

      String errorString = e.toString().toLowerCase();
      if (errorString.contains('422')) {
        errorMessage =
            'Invalid information provided. Please check your inputs.';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (errorString.contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 300; // Reset to 5 minutes
    });

    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isResendingOtp) return;

    setState(() {
      _isResendingOtp = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final data = {'identifier': _identifier};

      final response = await apiService.post('/forgot-password', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP resent successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Restart the timer
          _startResendTimer();

          // Clear current OTP
          _otpController.clear();
          setState(() {
            _otpVerified = false;
          });
        } else {
          // Handle API errors with user-friendly messages
          String errorMessage = 'Unable to resend OTP. Please try again later.';

          if (responseData['message'] != null) {
            String apiMessage = responseData['message']
                .toString()
                .toLowerCase();

            if (apiMessage.contains('user not found') ||
                apiMessage.contains('no user found') ||
                apiMessage.contains('not found')) {
              errorMessage =
                  'Unable to resend OTP. Please check your information.';
            } else if (apiMessage.contains('failed to send')) {
              errorMessage = 'Unable to resend OTP. Please try again later.';
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Handle network errors with user-friendly messages
      String errorMessage =
          'Unable to resend OTP. Please check your connection and try again.';

      String errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (errorString.contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isResendingOtp = false;
      });
    }
  }

  String _getFormattedTime() {
    int minutes = _resendCountdown ~/ 60;
    int seconds = _resendCountdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Text(
                'Reset Your Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _methods != null && _methods!.isNotEmpty
                    ? 'Enter the OTP sent via ${_methods!.join(' and ')} and your new password'
                    : 'Enter the OTP sent to your registered contact and your new password',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              SizedBox(height: 40),

              // OTP Field
              TextField(
                controller: _otpController,
                enabled: !_otpVerified,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: _otpVerified
                      ? "OTP Verified ✓"
                      : "Enter 6-digit OTP",
                  filled: true,
                  fillColor: _otpVerified
                      ? Colors.green.withOpacity(0.1)
                      : AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: _otpVerified
                          ? Colors.green
                          : AppColors.inputBorder,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  suffixIcon: _isVerifyingOtp
                      ? Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _otpVerified
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              ),
              SizedBox(height: 16),

              // Resend OTP Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive OTP? ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (!_canResend) ...[
                    Text(
                      "Resend in ${_getFormattedTime()}",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: _isResendingOtp ? null : _resendOtp,
                      child: Text(
                        _isResendingOtp ? "Sending..." : "Resend OTP",
                        style: TextStyle(
                          color: _isResendingOtp
                              ? Colors.grey
                              : AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 24),

              // New Password Field
              TextField(
                controller: _passwordController,
                enabled: _otpVerified,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: _otpVerified ? "New Password" : "Verify OTP first",
                  filled: true,
                  fillColor: _otpVerified
                      ? AppColors.inputBackground
                      : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  suffixIcon: _otpVerified
                      ? IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        )
                      : null,
                ),
              ),
              SizedBox(height: 24),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                enabled: _otpVerified,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: _otpVerified
                      ? "Confirm New Password"
                      : "Verify OTP first",
                  filled: true,
                  fillColor: _otpVerified
                      ? AppColors.inputBackground
                      : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  suffixIcon: _otpVerified
                      ? IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        )
                      : null,
                ),
              ),
              SizedBox(height: 32),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_otpVerified)
                      ? null
                      : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _otpVerified
                        ? AppColors.primary
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _otpVerified ? 'Reset Password' : 'Verify OTP First',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24),

              // Back to login
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
