import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/services/api_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidMobile(String mobile) {
    // Remove any non-digit characters
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanMobile.length >= 10 && cleanMobile.length <= 15;
  }

  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final identifier = _identifierController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final data = {'identifier': identifier};

      final response = await apiService.post('/forgot-password', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to reset password screen
          context.push(
            '/reset-password',
            extra: {
              'identifier': identifier,
              'methods': responseData['methods'],
            },
          );
        } else {
          // Handle API errors with user-friendly messages
          String errorMessage =
              'Unable to send OTP at the moment. Please try again later.';

          if (responseData['message'] != null) {
            String apiMessage = responseData['message']
                .toString()
                .toLowerCase();

            // Convert technical error messages to user-friendly ones
            if (apiMessage.contains('user not found') ||
                apiMessage.contains('no user found') ||
                apiMessage.contains('not found')) {
              errorMessage =
                  'If this email or mobile number is registered, you will receive an OTP shortly.';
            } else if (apiMessage.contains('email') &&
                apiMessage.contains('mobile')) {
              errorMessage =
                  'Please enter a valid email address or mobile number.';
            } else if (apiMessage.contains('invalid')) {
              errorMessage =
                  'Please enter a valid email address or mobile number.';
            } else if (apiMessage.contains('failed to send')) {
              errorMessage =
                  'Unable to send OTP at the moment. Please try again later.';
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
      // Handle network errors and other exceptions with user-friendly messages
      String errorMessage =
          'Unable to connect to server. Please check your internet connection and try again.';

      String errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (errorString.contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorString.contains('404')) {
        errorMessage =
            'Service temporarily unavailable. Please try again later.';
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
        title: Text('Forgot Password'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
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
                  'Enter your email or mobile number to receive OTP',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 40),

                // Single input field for email or mobile
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email or mobile number';
                    }
                    if (!_isValidEmail(value.trim()) &&
                        !_isValidMobile(value.trim())) {
                      return 'Please enter a valid email address or mobile number';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Enter Your Email/Mobile No",
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),

                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestPasswordReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Send OTP',
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
                    onPressed: () => context.pop(),
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
      ),
    );
  }
}
