import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/widgets/app_logo.dart';
import 'package:hrms_app/core/providers/language_provider.dart';
import 'dart:async';

class MobileEntryScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? initialName;
  const MobileEntryScreen({super.key, this.initialEmail, this.initialName});

  @override
  ConsumerState<MobileEntryScreen> createState() => _MobileEntryScreenState();
}

class _MobileEntryScreenState extends ConsumerState<MobileEntryScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;
  String? _mobileError;

  // New state variables for enhanced features
  String? _selectedUserType; // 'owner' or 'tenant'
  bool _showQuestionSection = false; // Hide question section by default
  Map<String, dynamic>? _tenantData; // Store tenant data if found
  bool _isNextButtonEnabled = false; // Disable next button by default
  Timer? _debounceTimer;

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

      return hasPassword;
    } catch (e) {
      print('DEBUG: Error checking tenant password status: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      // If API fails, assume no password (safer for new tenants)
      return false;
    }
  }

  // Handle mobile number change with debouncing
  void _handleMobileNumberChange(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear previous state
    setState(() {
      _tenantData = null;
      _showQuestionSection = false;
      _isNextButtonEnabled = false;
      _selectedUserType = null;
      _mobileError = null;
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
        context.go(
          '/tenant-registration?mobile=${Uri.encodeComponent(_mobileController.text.trim())}',
        );
      } else {
        // Tenant already registered (has password) - redirect to login
        print('DEBUG: Tenant already registered - going to login');
        context.go('/login');
      }
    } else if (_selectedUserType != null) {
      // New user with selection - proceed based on choice
      final mobile = _mobileController.text.trim();
      if (_selectedUserType == 'owner') {
        final params = <String>[];
        params.add('mobile=${Uri.encodeComponent(mobile)}');
        if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
          params.add('email=${Uri.encodeComponent(widget.initialEmail!)}');
        }
        if (widget.initialName != null && widget.initialName!.isNotEmpty) {
          params.add('name=${Uri.encodeComponent(widget.initialName!)}');
        }
        final url = '/owner-registration?${params.join('&')}';
        context.go(url);
      } else if (_selectedUserType == 'tenant') {
        context.go(
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
        setState(() {
          _mobileError =
              'Please enter a valid Bangladeshi number (11 digits starting with 01).';
        });
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
            // Back Button - Scrolls with content
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(bottom: 20),
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
            ),
            // App Logo
            AppLogo(size: 100, showText: true, showSubtitle: false),
            SizedBox(height: 40),
            // Header
            Text(
              languageNotifier.getString('enter_mobile_number'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              languageNotifier.getString('mobile_number_description'),
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            // Mobile Number Field
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: languageNotifier.getString('mobile_number'),
                hintText: '01XXXXXXXXX',
                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.inputBorder,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.inputBorder,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.inputBorder,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                errorText: _mobileError,
              ),
              onChanged: (value) => _handleMobileNumberChange(value),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
            ),
            // Loading indicator
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
            // Continue Button
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
                    : () => _handleNextButtonClick(),
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
                  onTap: () => context.go('/login'),
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
