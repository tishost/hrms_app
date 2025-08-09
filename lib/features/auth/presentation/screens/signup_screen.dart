import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:hrms_app/core/providers/language_provider.dart';

import 'dart:async'; // Added for Timer

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final TextEditingController _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mobileController.dispose();
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

  bool _isValidBdMobile(String input) {
    return _normalizeBdMobile(input) != null;
  }

  void _showSmartRegistrationDialog() {
    final mobileController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final languageNotifier = ref.read(languageProvider.notifier);
            return AlertDialog(
              title: Text(
                languageNotifier.getString('smart_registration'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    languageNotifier.getString('enter_mobile_detect_role'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: languageNotifier.getString(
                        'enter_mobile_number',
                      ),
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (isLoading)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Checking database...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (mobileController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter mobile number'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            // Call API to check mobile number
                            final response = await _checkMobileRole(
                              mobileController.text.trim(),
                            );

                            Navigator.of(context).pop();

                            if (response['success']) {
                              final role = response['role'];
                              final userData = response['user_data'];

                              if (role != null) {
                                // Auto role detected
                                _showAutoRoleDialog(role, userData);
                              } else {
                                // Not found in database, show role selection
                                _showRoleSelectionDialog();
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
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text('Check', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAutoRoleDialog(String role, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final languageNotifier = ref.read(languageProvider.notifier);
        return AlertDialog(
          title: Text(
            languageNotifier.getString('role_detected'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                role == 'owner' ? Icons.business_center : Icons.person,
                color: role == 'owner' ? AppColors.primary : Colors.blue,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                languageNotifier.getString('found_account_database'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                role == 'owner'
                    ? languageNotifier.getString('role_property_owner')
                    : languageNotifier.getString('role_tenant'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userData != null) ...[
                SizedBox(height: 8),
                Text(
                  'Name: ${userData['name'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Mobile: ${userData['mobile'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showRoleSelectionDialog();
              },
              child: Text(
                languageNotifier.getString('choose_different_role'),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Pass mobile number from the text field
                _navigateToRegistration(
                  role,
                  mobile: _mobileController.text.trim(),
                );
              },
              child: Text(
                languageNotifier.getString('continue'),
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _checkMobileRole(String mobile) async {
    try {
      print('DEBUG: _checkMobileRole called with mobile: $mobile');
      // TODO: Replace with actual API endpoint
      // For now, simulate API call
      await Future.delayed(Duration(seconds: 1)); // Simulate API call

      // Mock API response - replace with actual API call
      // This should call: POST /api/check-mobile-role
      // with body: {"mobile": mobile}

      // Simulate checking in database
      // For demo: if mobile contains "owner", return owner role
      // if mobile contains "tenant", return tenant role
      // otherwise return null (not found)

      // Check if mobile number exists in database
      if (mobile == '01718262530') {
        // This mobile number is already registered as owner
        print('DEBUG: Mobile 01718262530 found as owner');
        return {
          'success': true,
          'role': 'owner',
          'message': 'Mobile number found in owner records',
          'user_data': {
            'name': 'Demo Owner',
            'mobile': mobile,
            'email': 'owner@demo.com',
          },
        };
      } else if (mobile.contains('tenant')) {
        print('DEBUG: Mobile $mobile found as tenant');
        return {
          'success': true,
          'role': 'tenant',
          'message': 'Mobile number found in tenant records',
          'user_data': {
            'name': 'Demo Tenant',
            'mobile': mobile,
            'email': 'tenant@demo.com',
          },
        };
      } else {
        // Not found in database
        print('DEBUG: Mobile $mobile not found in database (new user)');
        return {
          'success': true,
          'role': null,
          'message': 'Mobile number not found in database',
          'user_data': null,
        };
      }
    } catch (e) {
      print('DEBUG: Error in _checkMobileRole: $e');
      return {
        'success': false,
        'message': 'Error checking mobile number: $e',
        'role': null,
        'user_data': null,
      };
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      print('Starting Google Sign-In...');
      // Try with default configuration (no clientId needed for Android)
      final GoogleSignIn googleSignIn = GoogleSignIn();
      print('GoogleSignIn instance created');

      // Force account chooser every time: sign out/disconnect previous session
      try {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      print(
        'Google Sign-In result: ${googleUser != null ? 'Success' : 'Cancelled'}',
      );

      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        // Proceed without idToken for now; backend verification can be added later
        debugPrint(
          'WARNING: Google idToken is null; proceeding with profile info only',
        );
      }

      // Now you have the user's name and email
      final String name = googleUser.displayName ?? 'Google User';
      final String email = googleUser.email;
      final String? photoUrl = googleUser.photoUrl != null
          ? (googleUser.photoUrl!.contains('googleusercontent')
                ? '${googleUser.photoUrl!}?sz=200'
                : googleUser.photoUrl)
          : null;

      print('Google Sign-In Success:');
      print('Name: $name');
      print('Email: $email');

      // TODO: Here you would typically send the idToken to your backend
      // for verification and to create a session/JWT for your app.
      // For now, we will navigate to the registration screen with the data.

      await _checkGoogleAndNavigate(email, name, profilePic: photoUrl);
    } catch (e) {
      print('Google Sign-In Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');

      // Show more specific error message
      String errorMessage = 'Google Sign-In failed. Please try again.';
      if (e.toString().contains('ApiException: 10')) {
        errorMessage =
            'Google Sign-In configuration error. Please check Firebase setup.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
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

  Future<void> _checkGoogleAndNavigate(
    String email,
    String name, {
    String? profilePic,
  }) async {
    try {
      // Call API to check email in database
      final response = await _checkGoogleRole(email);

      if (response['success']) {
        final role = response['role'];
        final userData = response['user_data'];

        if (role != null) {
          // Existing user -> auto-login and go to role dashboard
          final token =
              (response['token'] ??
                      userData?['token'] ??
                      userData?['api_token'] ??
                      'GOOGLE_TEMP_TOKEN')
                  .toString();
          final Map<String, dynamic> normalizedUser = {
            'name': userData?['name'] ?? name,
            'email': userData?['email'] ?? email,
            'role': role,
          };

          await ref
              .read(authStateProvider.notifier)
              .login(token, role, userData: normalizedUser);

          // Ensure ApiService picks up the token for Authorization header
          await AuthService.saveToken(token);

          // Router redirect will send to proper dashboard by role
          context.go('/dashboard');
        } else {
          // Not found → ask mobile then continue smart registration flow
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'New user detected! Please enter your mobile number to continue',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          final picParam = profilePic != null && profilePic.isNotEmpty
              ? '&profile_pic=${Uri.encodeComponent(profilePic)}'
              : '';
          context.push(
            '/mobile-entry?email=${Uri.encodeComponent(email)}&name=${Uri.encodeComponent(name)}$picParam',
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
    try {
      final api = ref.read(apiServiceProvider);
      print('DEBUG: Checking google email in backend: $email');
      final response = await api.post(
        '/check-google-role',
        data: {'email': email},
      );
      final data = response.data as Map<String, dynamic>;
      print('DEBUG: Google role API response: $data');
      return {
        'success': data['success'] == true,
        'role': data['role'],
        'message': data['message'] ?? 'OK',
        'user_data': data['user_data'],
        'token': data['token'],
      };
    } catch (e) {
      print('DEBUG: Error in _checkGoogleRole: $e');
      return {
        'success': false,
        'role': null,
        'message': 'Failed to check email: $e',
        'user_data': null,
      };
    }
  }

  void _showRoleSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Your Role',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Owner Option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.business_center_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'Property Owner',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                subtitle: Text(
                  'Manage properties and tenants',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToRegistration(
                    'owner',
                    mobile: _mobileController.text.trim(),
                  );
                },
              ),
              Divider(),
              // Tenant Option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(Icons.person_search_outlined, color: Colors.blue),
                ),
                title: Text(
                  'Tenant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                subtitle: Text(
                  'Rent properties and pay bills',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToRegistration(
                    'tenant',
                    mobile: _mobileController.text.trim(),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleNextButton() {
    // Get mobile number from the text field
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
            'Please enter a valid Bangladeshi number (11 digits starting with 01). +88 will be removed automatically',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _mobileController.text = normalized;
    // Check mobile number in database first with normalized value
    _checkMobileAndNavigate(normalized);
  }

  Future<void> _checkMobileAndNavigate(String mobile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure normalized inside as well (safety)
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

      print('DEBUG: Checking mobile number: $normalized');
      // Call API to check mobile number in database
      final response = await _checkMobileRole(normalized);
      print('DEBUG: API response: $response');

      if (response['success']) {
        final role = response['role'];
        final userData = response['user_data'];
        print('DEBUG: Role detected: $role');

        if (role == 'owner') {
          // User found as Owner - redirect to login
          print('DEBUG: Owner found, redirecting to login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Owner found! Redirecting to login...'),
              backgroundColor: Colors.green,
            ),
          );
          // Use context.pushReplacement instead of Navigator
          context.pushReplacement('/login');
        } else if (role == 'tenant') {
          // User found as Tenant - redirect to tenant registration
          print('DEBUG: Tenant found, redirecting to tenant registration');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tenant found! Redirecting to tenant registration...',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pushNamed('/tenant-registration');
        } else {
          // User not found - go to owner registration (no OTP)
          print('DEBUG: New user, redirecting to owner registration');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New user! Redirecting to owner registration...'),
              backgroundColor: AppColors.primary,
            ),
          );
          // Use context.push with mobile number parameter
          print(
            'DEBUG: About to push to /owner-registration with mobile: $normalized',
          );
          context.push(
            '/owner-registration?mobile=${Uri.encodeComponent(normalized)}',
          );
          print('DEBUG: Pushed to /owner-registration with mobile parameter');
        }
      } else {
        print('DEBUG: API call failed: ${response['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error in _checkMobileAndNavigate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRegistration(String role, {String? mobile, String? email}) {
    // Go directly to registration without OTP
    if (role == 'owner') {
      // Use context.push with parameters
      String url = '/owner-registration';
      List<String> params = [];
      if (mobile != null && mobile.isNotEmpty) {
        params.add('mobile=${Uri.encodeComponent(mobile)}');
      }
      if (email != null && email.isNotEmpty) {
        params.add('email=${Uri.encodeComponent(email)}');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      context.push(url);
    } else {
      Navigator.of(context).pushNamed('/tenant-registration');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageNotifier = ref.watch(languageProvider.notifier);
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(languageNotifier.getString('welcome')),
        actions: [
          // Language Button - Upper Right Corner
          Container(
            margin: EdgeInsets.only(right: 16),
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
                  _toggleLanguage(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Text(
                    currentLanguage.code == 'en' ? 'English' : 'বাংলা',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                  languageNotifier.getString('welcome_to_hrms'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  languageNotifier.getString('property_management_system'),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40),

                // Mobile Number Field
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: languageNotifier.getString('mobile_hint'),
                    prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                ),

                SizedBox(height: 24),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleNextButton,
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
                            languageNotifier.getString('next'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      languageNotifier.getString('already_have_account'),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
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

                SizedBox(height: 40),

                // Why Choose Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        languageNotifier.getString('why_choose_hrms'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.home,
                        title: languageNotifier.getString(
                          'property_management',
                        ),
                        description: languageNotifier.getString(
                          'manage_properties_efficiently',
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        icon: Icons.people,
                        title: languageNotifier.getString('tenant_management'),
                        description: languageNotifier.getString(
                          'track_tenants_details',
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        icon: Icons.payment,
                        title: languageNotifier.getString('rent_collection'),
                        description: languageNotifier.getString(
                          'automated_rent_collection',
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildFeatureItem(
                        icon: Icons.security,
                        title: languageNotifier.getString('secure_reliable'),
                        description: languageNotifier.getString(
                          'data_safe_with_us',
                        ),
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

  void _toggleLanguage(BuildContext context) async {
    await ref.read(languageProvider.notifier).toggleLanguage();

    final languageNotifier = ref.read(languageProvider.notifier);
    if (languageNotifier.isEnglish) {
      _changeLanguage(context, 'en');
    } else {
      _changeLanguage(context, 'bn');
    }
  }

  void _changeLanguage(BuildContext context, String languageCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          languageCode == 'en'
              ? 'Language changed to English'
              : 'ভাষা বাংলায় পরিবর্তন করা হয়েছে',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
