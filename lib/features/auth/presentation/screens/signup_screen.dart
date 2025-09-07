import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:hrms_app/core/providers/language_provider.dart';
import 'package:hrms_app/core/services/analytics_service.dart';
import 'package:hrms_app/core/widgets/app_logo.dart';

import 'dart:async';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final TextEditingController _mobileController = TextEditingController();
  String? _selectedUserType; // 'owner' or 'tenant'

  // New state variables for conditional UI
  bool _showQuestionSection = false; // Hide question section by default
  Map<String, dynamic>? _tenantData; // Store tenant data if found
  bool _isNextButtonEnabled = false; // Disable next button by default

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String? _normalizeBdMobile(String input) {
    String msisdn = _digitsOnly(input);
    if (msisdn.startsWith('0088')) {
      msisdn = msisdn.substring(4);
    } else if (msisdn.startsWith('88')) {
      msisdn = msisdn.substring(2);
    }
    if (msisdn.length == 10 && msisdn.startsWith('1')) {
      msisdn = '0$msisdn';
    }
    if (msisdn.length != 11 || !msisdn.startsWith('01')) {
      return null;
    }
    return msisdn;
  }

  Future<Map<String, dynamic>> _checkMobileRole(String mobile) async {
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.post(
        '/check-mobile-role',
        data: {'mobile': mobile},
      );

      final data = response.data as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'role': data['role'],
        'message': data['message'] ?? 'OK',
        'user_data': data['user_data'],
      };
    } catch (e) {
      return {
        'success': false,
        'role': null,
        'message': 'Failed to check mobile: $e',
        'user_data': null,
      };
    }
  }

  // Check if tenant has password set (exists in users table)
  Future<bool> _checkTenantPasswordStatus(String email, String mobile) async {
    try {
      print(
        'DEBUG: Checking tenant password status for email: $email, mobile: $mobile',
      );
      if (email.isEmpty && mobile.isEmpty) {
        print('DEBUG: Both email and mobile are empty, returning false');
        return false;
      }

      final api = ref.read(apiServiceProvider);
      print('DEBUG: Making API call to /check-tenant-password-status');

      final response = await api.post(
        '/check-tenant-password-status',
        data: {'email': email, 'mobile': mobile},
      );

      print(
        'DEBUG: Password status API response status: ${response.statusCode}',
      );
      print('DEBUG: Password status API response data: ${response.data}');

      final data = response.data as Map<String, dynamic>;
      final hasPassword = data['has_password'] == true;
      print('DEBUG: Tenant has password: $hasPassword');
      print('DEBUG: API success: ${data['success']}');
      print('DEBUG: API message: ${data['message']}');

      // Print debug info if available
      if (data['debug_info'] != null) {
        final debugInfo = data['debug_info'] as Map<String, dynamic>;
        print('DEBUG: User ID: ${debugInfo['user_id']}');
        print('DEBUG: User Email: ${debugInfo['user_email']}');
        print(
          'DEBUG: Password field exists: ${debugInfo['password_field_exists']}',
        );
        print(
          'DEBUG: Password field type: ${debugInfo['password_field_type']}',
        );
        print('DEBUG: Password is null: ${debugInfo['password_is_null']}');
        print('DEBUG: Password is empty: ${debugInfo['password_is_empty']}');
        print('DEBUG: Password length: ${debugInfo['password_length']}');
        print(
          'DEBUG: Password starts with hash: ${debugInfo['password_starts_with_hash']}',
        );
      }

      return hasPassword;
    } catch (e) {
      print('DEBUG: Error checking tenant password status: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      // If API fails, assume no password (safer for new tenants)
      return false;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    print('DEBUG: Google Sign-In started');

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      print('DEBUG: Creating GoogleSignIn instance');
      final GoogleSignIn googleSignIn = GoogleSignIn();

      print('DEBUG: Signing out from previous sessions');
      try {
        await googleSignIn.signOut();
        print('DEBUG: Sign out successful');
      } catch (e) {
        print('DEBUG: Sign out failed (non-critical): $e');
      }

      print('DEBUG: Disconnecting from previous sessions');
      try {
        await googleSignIn.disconnect();
        print('DEBUG: Disconnect successful');
      } catch (e) {
        print('DEBUG: Disconnect failed (non-critical): $e');
      }

      print('DEBUG: Starting Google Sign-In process');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('DEBUG: User cancelled Google Sign-In');
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      print('DEBUG: Google Sign-In successful');
      print('DEBUG: User email: ${googleUser.email}');
      print('DEBUG: User name: ${googleUser.displayName}');

      print('DEBUG: Getting Google authentication');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String name = googleUser.displayName ?? 'Google User';
      final String email = googleUser.email;

      print('DEBUG: Proceeding to check user role');
      await _checkGoogleAndNavigate(email, name);
    } catch (e) {
      print('DEBUG: Google Sign-In Error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');

      String errorMessage = 'Google Sign-In failed';

      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your internet connection.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Sign-in was cancelled.';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage =
            'Google Sign-In failed. Please check your Google account.';
      } else {
        errorMessage = 'Google Sign-In failed: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _checkGoogleAndNavigate(String email, String name) async {
    try {
      final response = await _checkGoogleRole(email);

      if (response['success']) {
        final role = response['role'];
        final userData = response['user_data'];

        if (role != null) {
          final token =
              (response['token'] ?? userData?['token'] ?? 'GOOGLE_TEMP_TOKEN')
                  .toString();
          final Map<String, dynamic> normalizedUser = {
            'name': userData?['name'] ?? name,
            'email': userData?['email'] ?? email,
            'role': role,
          };

          await ref
              .read(authStateProvider.notifier)
              .login(token, role, userData: normalizedUser);
          await AuthService.saveToken(token);

          // Track Google sign-in analytics
          try {
            final userId =
                userData?['id']?.toString() ?? 'google_user_${email.hashCode}';
            await AnalyticsService.trackUserLogin(
              userId: userId,
              email: email,
              loginMethod: 'google_signin',
            );
            print('DEBUG: Google sign-in analytics tracked successfully');
          } catch (analyticsError) {
            print(
              'DEBUG: Failed to track Google sign-in analytics: $analyticsError',
            );
            // Don't block login flow if analytics fails
          }

          context.go('/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'New user detected! Please enter your mobile number to continue',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          context.push(
            '/mobile-entry?email=${Uri.encodeComponent(email)}&name=${Uri.encodeComponent(name)}',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<Map<String, dynamic>> _checkGoogleRole(String email) async {
    print('DEBUG: Checking Google user role for email: $email');
    try {
      final api = ref.read(apiServiceProvider);
      print('DEBUG: Making API call to /check-google-role');

      final response = await api.post(
        '/check-google-role',
        data: {'email': email},
      );

      print('DEBUG: API response received');
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response data: ${response.data}');

      final data = response.data as Map<String, dynamic>;
      return {
        'success': data['success'] == true,
        'role': data['role'],
        'message': data['message'] ?? 'OK',
        'user_data': data['user_data'],
        'token': data['token'],
      };
    } catch (e) {
      print('DEBUG: API call failed with error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      return {
        'success': false,
        'role': null,
        'message': 'Failed to check email: $e',
        'user_data': null,
      };
    }
  }

  void _handleNextButton() {
    final mobileNumber = _mobileController.text.trim();

    if (mobileNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final normalized = _normalizeBdMobile(mobileNumber);
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid Bangladeshi number (11 digits starting with 01).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _mobileController.text = normalized;
    _checkMobileAndNavigate(normalized);
  }

  // Handle mobile number change with debouncing
  Timer? _debounceTimer;

  void _handleMobileNumberChange(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear previous state
    setState(() {
      _tenantData = null;
      _showQuestionSection = false;
      _isNextButtonEnabled = false;
      _selectedUserType = null;
    });

    // Set a new timer to check after user stops typing
    _debounceTimer = Timer(Duration(milliseconds: 800), () {
      if (value.length >= 11) {
        final normalized = _normalizeBdMobile(value);
        if (normalized != null) {
          _checkMobileAndNavigate(normalized);
        }
      }
    });
  }

  // Handle question selection and enable next button
  void _handleQuestionSelection(String userType) async {
    setState(() {
      _selectedUserType = userType;
      // Only enable next button if user selects 'owner' (Yes)
      // For 'tenant' (No), we'll show a message instead
      _isNextButtonEnabled = (userType == 'owner');
    });
  }

  // Share app functionality
  void _shareApp() async {
    // Share app information using native share sheet
    Share.share(
      'Check out this amazing property management app: HRMS\n\n'
      'Download it from: https://play.google.com/store/apps/details?id=com.barimanager.app\n\n'
      'Manage your properties efficiently with features like:\n'
      '• Property Management\n'
      '• Tenant Management\n'
      '• Rent Collection\n'
      '• Financial Reports\n\n'
      'Perfect for landlords and property owners!',
      subject: 'HRMS - Property Management App',
    );
  }

  // Handle next button click based on current state
  void _handleNextButtonClick() async {
    print('DEBUG: _handleNextButtonClick called');
    print('DEBUG: _tenantData: $_tenantData');
    print('DEBUG: _isNextButtonEnabled: $_isNextButtonEnabled');

    if (_tenantData != null) {
      // Tenant found - check if they need registration or login
      if (_isNextButtonEnabled) {
        // Tenant needs registration (no password)
        print(
          'DEBUG: Tenant needs registration - going to tenant registration',
        );
        context.push(
          '/tenant-registration?mobile=${Uri.encodeComponent(_mobileController.text.trim())}',
        );
      } else {
        // Tenant already registered (has password) - redirect to login
        print('DEBUG: Tenant already registered - going to login');
        context.pushReplacement('/login');
      }
    } else if (_selectedUserType != null) {
      // New user with selection - proceed based on choice
      final mobile = _mobileController.text.trim();
      if (_selectedUserType == 'owner') {
        context.push(
          '/owner-registration?mobile=${Uri.encodeComponent(mobile)}',
        );
      } else if (_selectedUserType == 'tenant') {
        context.push(
          '/tenant-registration?mobile=${Uri.encodeComponent(mobile)}',
        );
      }
    }
  }

  Future<void> _checkMobileAndNavigate(String mobile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final normalized = _normalizeBdMobile(mobile);
      if (normalized == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a valid Bangladeshi number (11 digits starting with 01).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await _checkMobileRole(normalized);
      print('DEBUG: API response: $response');

      if (response['success']) {
        final role = response['role'];
        final userData = response['user_data'];
        print('DEBUG: Role: $role, UserData: $userData');

        if (role == 'owner') {
          // Owner found - show dialog
          _showOwnerFoundDialog();
        } else if (role == 'tenant') {
          // Tenant found - check if they have password set
          print('DEBUG: Tenant found with data: $userData');
          print('DEBUG: Data type: ${userData.runtimeType}');
          print('DEBUG: Data keys: ${userData.keys.toList()}');
          print('DEBUG: Email from tenant data: ${userData['email']}');
          print('DEBUG: Name from tenant data: ${userData['name']}');
          print('DEBUG: Mobile from tenant data: ${userData['mobile']}');

          // Check if tenant has password (exists in users table with password)
          final hasPassword = await _checkTenantPasswordStatus(
            userData['email'] ?? '',
            userData['mobile'] ?? '',
          );
          print('DEBUG: Tenant has password: $hasPassword');

          setState(() {
            _tenantData = userData;
            _showQuestionSection = false; // Hide question section

            // Enable next button if no password (new tenant), disable if has password (already registered)
            _isNextButtonEnabled = !hasPassword;
          });
          print(
            'DEBUG: State updated - _tenantData: $_tenantData, _showQuestionSection: $_showQuestionSection, _isNextButtonEnabled: $_isNextButtonEnabled',
          );

          if (hasPassword) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tenant already registered! Please login.'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tenant found! Please complete registration.'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        } else {
          // New user - show question section
          setState(() {
            _tenantData = null;
            _showQuestionSection = true; // Show question section
            _isNextButtonEnabled =
                false; // Disable next button until choice made
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'New user detected! Please answer the question below.',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        // API error - show question section for new user
        setState(() {
          _tenantData = null;
          _showQuestionSection = true; // Show question section
          _isNextButtonEnabled = false; // Disable next button until choice made
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error occurred - show question section for new user
      setState(() {
        _tenantData = null;
        _showQuestionSection = true; // Show question section
        _isNextButtonEnabled = false; // Disable next button until choice made
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show dialog when owner is found
  void _showOwnerFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.person, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Owner Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          content: Text(
            'This mobile number is already registered as an owner. Please login to continue.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.go('/login'); // Navigate to login page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageNotifier = ref.watch(languageProvider.notifier);
    final currentLanguage = ref.watch(languageProvider);

    // Debug logging
    print(
      'DEBUG: Build method - _tenantData: $_tenantData, _showQuestionSection: $_showQuestionSection, _isNextButtonEnabled: $_isNextButtonEnabled',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top:
              MediaQuery.of(context).padding.top +
              20, // Add safe area for status bar
          left: 20,
          right: 20,
          bottom: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Back Button and Language Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button - Upper Left Corner
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.9),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/login');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // App Logo
            AppLogo(size: 100, showText: true, showSubtitle: false),
            SizedBox(height: 40),

            // Mobile Number Field
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: languageNotifier.getString('mobile_number'),
                hintText: '01XXXXXXXXX',
                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                floatingLabelBehavior:
                    FloatingLabelBehavior.always, // Always show label
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.inputBorder, // Normal border color
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.inputBorder, // Normal border color
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary, // Highlight color when focused
                    width: 2.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.inputBorder, // Normal border color
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors
                        .primary, // Highlight color when focused with error
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              onChanged: (value) {
                // Auto-check mobile number when user types
                _handleMobileNumberChange(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return languageNotifier.getString(
                    'please_enter_mobile_number',
                  );
                }
                // Normalize BD number and validate
                String only = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (only.startsWith('0088')) {
                  only = only.substring(4);
                } else if (only.startsWith('88')) {
                  only = only.substring(2);
                }
                if (only.length == 10 && only.startsWith('1')) {
                  only = '0$only';
                }
                if (only.length != 11 || !only.startsWith('01')) {
                  return languageNotifier.getString('valid_bd_number');
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
            ),

            // Loading indicator for mobile check
            if (_isLoading) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    languageNotifier.getString('checking_mobile'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 24),

            // Tenant Information Section (shown when tenant found)
            if (_tenantData != null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isNextButtonEnabled
                                ? languageNotifier.getString('tenant_found')
                                : languageNotifier.getString(
                                    'already_registered',
                                  ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.inputBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: AppColors.textSecondary,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${languageNotifier.getString('tenant_info_name')} ${_tenantData!['name'] ?? _tenantData!['first_name'] ?? _tenantData!['full_name'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                          if (_tenantData!['email'] != null) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: AppColors.textSecondary,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '${languageNotifier.getString('tenant_info_email')} ${_tenantData!['email']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],

            // Question Section (only shown for new users)
            if (_showQuestionSection) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question based on selected language
                  Text(
                    languageNotifier.getString('are_you_landlord'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleQuestionSelection('owner'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _selectedUserType == 'owner'
                                  ? AppColors.primary
                                  : AppColors.inputBorder,
                              width: _selectedUserType == 'owner' ? 2.0 : 1.5,
                            ),
                            backgroundColor: _selectedUserType == 'owner'
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            languageNotifier.getString('yes'),
                            style: TextStyle(
                              color: _selectedUserType == 'owner'
                                  ? AppColors.primary
                                  : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleQuestionSelection('tenant'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _selectedUserType == 'tenant'
                                  ? AppColors.primary
                                  : AppColors.inputBorder,
                              width: _selectedUserType == 'tenant' ? 2.0 : 1.5,
                            ),
                            backgroundColor: _selectedUserType == 'tenant'
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            languageNotifier.getString('no'),
                            style: TextStyle(
                              color: _selectedUserType == 'tenant'
                                  ? AppColors.primary
                                  : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],

            // Message for tenants (when "No" is selected)
            if (_selectedUserType == 'tenant') ...[
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            languageNotifier.getString(
                              'landlord_not_registered',
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      languageNotifier.getString('share_app_with_landlord'),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _shareApp,
                        icon: Icon(Icons.share, color: AppColors.white),
                        label: Text(
                          languageNotifier.getString('share_app'),
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],

            // Sign Up Button (Next/Login)
            // Button is enabled when:
            // 1. Loading is false AND
            // 2. Either tenant data exists (for login) OR next button is enabled (for new users)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isNextButtonEnabled || _tenantData != null)
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.5),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    (_isLoading ||
                        (_tenantData == null && !_isNextButtonEnabled))
                    ? null
                    : () {
                        print(
                          'DEBUG: Button pressed - _tenantData: $_tenantData, _isNextButtonEnabled: $_isNextButtonEnabled',
                        );
                        _handleNextButtonClick();
                      },
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
                    : Text(
                        _tenantData != null && !_isNextButtonEnabled
                            ? languageNotifier.getString('login')
                            : languageNotifier.getString('next'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 16),

            // OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "OR",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),

            SizedBox(height: 16),

            // Google Login Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isGoogleLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black87,
                          ),
                        ),
                      )
                    else ...[
                      SvgPicture.asset(
                        'assets/images/google_logo.svg',
                        width: 18,
                        height: 18,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          languageNotifier.getString('sign_up_with_google'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Login Link
            Column(
              children: [
                Text(
                  languageNotifier.getString('already_have_account'),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    context.go('/login');
                  },
                  child: Text(
                    languageNotifier.getString('login'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
}
