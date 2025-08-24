import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_drawer.dart';
import 'package:hrms_app/core/services/api_service.dart';
// import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:hrms_app/core/providers/language_provider.dart';
import 'package:hrms_app/core/widgets/app_text.dart';
import 'package:hrms_app/core/constants/app_strings.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  // int _selectedIndex = 0; // unused
  bool _isLoading = true;
  late FocusNode _focusNode;
  bool _otpBusy = false;
  // DateTime? _lastBackTime; // unused

  // User data
  String userName = '';
  String userEmail = '';
  String userMobile = '';
  bool userPhoneVerified = false;

  // Subscription data
  String subscriptionPlan = 'Free';
  bool isSubscriptionLoading = true;
  Map<String, dynamic>? _subscriptionData; // holds plan and sms_credits

  // Profile completion
  double _profileCompletion = 0.0;
  String userProfilePic = '';

  // Dashboard data
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _recentTransactions = [];
  List<Map<String, dynamic>> _unpaidSubInvoices = [];
  // OTP flow state/cache
  bool _otpSent = false;
  DateTime? _lastOtpSentAt;
  bool _otpSettingsLoaded = false;
  int _otpExpirySeconds = 600; // default 10 min
  int _resendCooldownSeconds = 300; // default 5 min
  int _otpLength = 6;
  bool _userLoaded = false; // prevent banner flash before user loads

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    // Force refresh all data on init to avoid showing old cached data
    print('DEBUG: Dashboard initState - Force refreshing all data');
    _forceRefreshAllData();
  }

  Widget _subMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Refresh user info when screen gains focus
      _refreshUserInfo();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshUserInfo(); // Refresh user data when app resumes
    }
  }

  Widget _buildAttentionBanner({
    required Widget title,
    required Widget message,
    required Widget buttonLabel,
    VoidCallback? onPressed,
  }) {
    print('DEBUG: _buildAttentionBanner called');
    return Container(
      margin: EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(maxWidth: double.infinity),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    // Allow long localized titles (e.g., Bangla) to wrap instead of overflow
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: title,
                      ),
                    ),
                  ],
                ),
                // Subtitle removed as requested
              ],
            ),
          ),
          SizedBox(width: 12),
          // Make action compact and shrink to avoid overflow on long localized labels
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.zero,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14),
                      SizedBox(width: 4),
                      buttonLabel,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBanner({
    required double percent,
    required VoidCallback onPressed,
  }) {
    print('DEBUG: _buildProgressBanner called with percent: $percent');
    final pct = (percent * 100).round();
    return Container(
      margin: EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(maxWidth: double.infinity),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    AppText(
                      'complete_your_profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '$pct% · ${AppStrings.getString('update_your_profile', ref.read(languageProvider).code)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 14),
                  SizedBox(width: 4),
                  AppText(
                    'update',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');

      if (userStr != null) {
        final userData = json.decode(userStr);
        print('DEBUG: Raw SharedPreferences data: $userData');
        setState(() {
          userName = userData['name'] ?? userData['first_name'] ?? 'Owner';
          userEmail = userData['email'] ?? '';
          userMobile = userData['phone'] ?? '';
          final dynamic phoneVerifiedRaw = userData['phone_verified'];
          final String phoneVerifiedAtRaw =
              (userData['phone_verified_at'] ?? '').toString().trim();
          final bool phoneVerifiedFlag = (phoneVerifiedRaw is bool)
              ? phoneVerifiedRaw
              : phoneVerifiedRaw == 1 ||
                    phoneVerifiedRaw == '1' ||
                    (phoneVerifiedRaw?.toString().toLowerCase().trim() ==
                        'true');
          userPhoneVerified =
              phoneVerifiedFlag || phoneVerifiedAtRaw.isNotEmpty;
          // Add cache busting to profile picture URL
          final profilePic = (userData['profile_pic'] ?? '').toString();
          userProfilePic = profilePic.isNotEmpty
              ? '$profilePic?t=${DateTime.now().millisecondsSinceEpoch}'
              : '';
          _profileCompletion = _computeProfileCompletion(userData);
          _userLoaded = true;
        });
        print(
          'DEBUG: SharedPreferences user data - phone_verified: ${userData['phone_verified']}, phone_verified_at: ${userData['phone_verified_at']}, userPhoneVerified: $userPhoneVerified',
        );
        print(
          'DEBUG: User data loaded - Name: $userName, Mobile: $userMobile, Verified: $userPhoneVerified',
        );
      } else {
        // Try API call if no cached data
        print('DEBUG: No cached user data found, loading from API');
        await _loadUserFromAPI();
        if (mounted) setState(() => _userLoaded = true);
      }
    } catch (e) {
      print('Error loading user info: $e');
      print('DEBUG: Falling back to API call due to error');
      await _loadUserFromAPI();
      if (mounted) setState(() => _userLoaded = true);
    }
  }

  Future<void> _loadUserFromAPI() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/user');

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data;
        print('DEBUG: Raw API data: $userData');
        setState(() {
          userName = userData['name'] ?? userData['first_name'] ?? 'Owner';
          userEmail = userData['email'] ?? '';
          userMobile = userData['phone'] ?? '';
          final dynamic phoneVerifiedRaw = userData['phone_verified'];
          final String phoneVerifiedAtRaw =
              (userData['phone_verified_at'] ?? '').toString().trim();
          final bool phoneVerifiedFlag = (phoneVerifiedRaw is bool)
              ? phoneVerifiedRaw
              : phoneVerifiedRaw == 1 ||
                    phoneVerifiedRaw == '1' ||
                    (phoneVerifiedRaw?.toString().toLowerCase().trim() ==
                        'true');
          userPhoneVerified =
              phoneVerifiedFlag || phoneVerifiedAtRaw.isNotEmpty;
          // Add cache busting to profile picture URL
          final profilePic = (userData['profile_pic'] ?? '').toString();
          userProfilePic = profilePic.isNotEmpty
              ? '$profilePic?t=${DateTime.now().millisecondsSinceEpoch}'
              : '';
          _profileCompletion = _computeProfileCompletion(userData);
        });

        // Cache the user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(userData));
        print('DEBUG: User data cached to SharedPreferences');
        print(
          'DEBUG: API user data - phone_verified: ${userData['phone_verified']}, phone_verified_at: ${userData['phone_verified_at']}, userPhoneVerified: $userPhoneVerified',
        );
        print(
          'DEBUG: User data loaded from API - Name: $userName, Mobile: $userMobile',
        );
        if (mounted) setState(() => _userLoaded = true);
      }
    } catch (e) {
      print('Error loading user from API: $e');
      setState(() {
        userName = 'Owner';
        userEmail = '';
        userMobile = '';
        userPhoneVerified = false;
        _profileCompletion = 0.0;
        _userLoaded = true;
      });
    }
  }

  // Method to refresh user info with cache busting
  Future<void> _refreshUserInfo() async {
    // Clear any cached profile picture data
    setState(() {
      userProfilePic = '';
    });

    // Reload user info with fresh data
    await _loadUserInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    print('DEBUG: _loadSubscriptionInfo called');
    try {
      setState(() => isSubscriptionLoading = true);

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/owner/subscription');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData['success'] == true &&
            responseData['subscription'] != null) {
          final subscription = responseData['subscription'];

          // Check if subscription is active (paid and active)
          final status = subscription['status']?.toString().toLowerCase();
          final isActive = status == 'active' || status == 'paid';

          if (isActive) {
            setState(() {
              subscriptionPlan = subscription['plan_name'] ?? 'Free';
              _subscriptionData =
                  subscription; // store full subscription for limits
              isSubscriptionLoading = false;
            });
            print('DEBUG: Active subscription plan loaded: $subscriptionPlan');
          } else {
            // Subscription exists but not active (pending/unpaid)
            setState(() {
              subscriptionPlan = 'Free';
              _subscriptionData =
                  subscription; // still store for possible display
              isSubscriptionLoading = false;
            });
            print(
              'DEBUG: Subscription found but not active. Status: $status, defaulting to Free',
            );
            print('DEBUG: Subscription response data: $responseData');
          }
        } else {
          setState(() {
            subscriptionPlan = 'Free';
            _subscriptionData = null;
            isSubscriptionLoading = false;
          });
          print('DEBUG: No active subscription found, defaulting to Free');
          print('DEBUG: Subscription response data: $responseData');
        }
      } else {
        setState(() {
          subscriptionPlan = 'Free';
          _subscriptionData = null;
          isSubscriptionLoading = false;
        });
        print('DEBUG: Failed to load subscription, defaulting to Free');
        print('DEBUG: Subscription response status: ${response.statusCode}');
      }
    } catch (e) {
      print('API subscription load error: $e');
      print('DEBUG: Subscription load error details: $e');
      setState(() {
        subscriptionPlan = 'Free';
        _subscriptionData = null;
        isSubscriptionLoading = false;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    print('DEBUG: _loadDashboardData called');
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/dashboard/stats');

      // Update stats from /dashboard/stats
      setState(() {
        _dashboardStats = response.data['stats'] ?? {};
        _isLoading = false;
      });
      print('DEBUG: Dashboard stats loaded: $_dashboardStats');

      // Load recent transactions from dedicated endpoint
      try {
        final txRes = await apiService.get('/dashboard/recent-transactions');
        final txList = (txRes.data is Map)
            ? (txRes.data['transactions'] as List?) ?? []
            : [];
        setState(() => _recentTransactions = List<dynamic>.from(txList));
        print(
          'DEBUG: Recent transactions loaded: ${_recentTransactions.length}',
        );
      } catch (e) {
        setState(() => _recentTransactions = []);
        print('DEBUG: Failed to load recent transactions: $e');
      }
    } catch (e) {
      print('DEBUG: Dashboard data load error: $e');
      setState(() {
        _dashboardStats = {
          'total_properties': 0,
          'total_units': 0,
          'total_tenants': 0,
          'total_collections': 0,
          'total_due': 0,
        };
        _recentTransactions = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load dashboard: $e')));
      print('DEBUG: Dashboard data load error snackbar shown');
      print('DEBUG: Dashboard data load error details: $e');
      print(
        'DEBUG: Dashboard data load error stack trace: ${StackTrace.current}',
      );
      print('DEBUG: Dashboard data load error context: ${context.toString()}');
      print('DEBUG: Dashboard data load error mounted: $mounted');
      print(
        'DEBUG: Dashboard data load error widget tree: ${WidgetsBinding.instance.lifecycleState}',
      );
      print('DEBUG: Dashboard data load error time: ${DateTime.now()}');
      print(
        'DEBUG: Dashboard data load error user agent: ${WidgetsBinding.instance.defaultBinaryMessenger.toString()}',
      );
    }
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _loadUserInfo(),
      _loadDashboardData(),
      _loadSubscriptionInfo(),
      _loadUnpaidSubscriptionInvoices(),
    ]);
  }

  // Force refresh all data by clearing cache first
  Future<void> _forceRefreshAllData() async {
    print('DEBUG: _forceRefreshAllData called - Clearing cache first');

    // Clear cached data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('dashboard_stats');
    await prefs.remove('subscription_data');

    print('DEBUG: Cache cleared, now loading fresh data');

    // Load fresh data
    await Future.wait([
      _loadUserInfo(),
      _loadDashboardData(),
      _loadSubscriptionInfo(),
      _loadUnpaidSubscriptionInvoices(),
    ]);

    print('DEBUG: Fresh data loaded');
  }

  Future<void> _loadUnpaidSubscriptionInvoices() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get('/subscription/invoices');
      final data = res.data as Map<String, dynamic>;
      final list = (data['invoices'] as List?)?.cast<dynamic>() ?? [];
      final mapped = list
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .where((inv) {
            // Backend invoices() returns: id, invoice_number, amount, status, due_date, paid_date, plan
            // Filter only by status
            final status = (inv['status'] ?? '').toString().toLowerCase();
            return status == 'unpaid' ||
                status == 'partial' ||
                status == 'pending';
          })
          .toList();
      setState(() => _unpaidSubInvoices = mapped);
    } catch (_) {
      setState(() => _unpaidSubInvoices = []);
    }
  }

  double _computeProfileCompletion(Map<String, dynamic> user) {
    String _s(dynamic v) => (v ?? '').toString().trim();
    final name = _s(user['name']);
    final first = _s(user['first_name']);
    final last = _s(user['last_name']);
    final email = _s(user['email']);
    final phone = _s(
      ((user['mobile'] ?? '').toString().isNotEmpty)
          ? user['mobile']
          : user['phone'],
    );
    final country = _s(user['country']);
    final district = _s(user['district']);
    final address = _s(user['address']);
    final gender = _s(user['gender']);
    final profilePic = _s(user['profile_pic']);
    final emailVerified =
        _s(user['email_verified_at']).isNotEmpty ||
        (user['email_verified'] == true);
    final phoneVerified =
        (user['phone_verified'] == true) || user['phone_verified_at'] != null;

    int filled = 0;
    int total = 10;
    final hasName = name.isNotEmpty || first.isNotEmpty || last.isNotEmpty;
    if (hasName) filled++;
    if (phone.isNotEmpty) filled++;
    if (district.isNotEmpty) filled++;
    if (email.isNotEmpty) filled++;
    if (country.isNotEmpty) filled++;
    if (address.isNotEmpty) filled++;
    if (gender.isNotEmpty) filled++;
    if (profilePic.isNotEmpty) filled++;
    if (emailVerified) filled++;
    if (phoneVerified) filled++;
    return (filled / total).clamp(0.0, 1.0);
  }

  Future<void> _startMobileVerificationFlow() async {
    // Debounce to prevent rapid multiple taps creating multiple OTP sends
    DateTime? _lastOtpTapTime;
    final now = DateTime.now();
    if (_lastOtpTapTime != null &&
        now.difference(_lastOtpTapTime!).inSeconds < 2) {
      return;
    }
    _lastOtpTapTime = now;
    if (userMobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No mobile number found in your profile')),
      );
      return;
    }
    final api = ref.read(apiServiceProvider);
    try {
      // Load OTP settings first
      final otpSettingsRes = await api.get('/otp-settings');
      final settings = (otpSettingsRes.data is Map)
          ? (otpSettingsRes.data['settings'] as Map<String, dynamic>?)
          : null;
      final otpExpiryMinutes =
          (settings != null && settings['otp_expiry_minutes'] != null)
          ? (settings['otp_expiry_minutes'] as num).toInt()
          : 10;
      final resendCooldownSeconds =
          (settings != null && settings['resend_cooldown_seconds'] != null)
          ? (settings['resend_cooldown_seconds'] as num).toInt()
          : 300;

      final otpLength = (settings != null && settings['otp_length'] != null)
          ? (settings['otp_length'] as num).toInt()
          : 6;

      await api.post(
        '/send-otp',
        data: {'phone': userMobile, 'type': 'profile_update'},
      );
      String code = '';
      int secondsLeft = otpExpiryMinutes * 60;
      int resendCooldown = resendCooldownSeconds;
      Timer? countdownTimer;
      Timer? cooldownTimer;
      Timer? verifyTimer;

      await showDialog(
        context: context,
        builder: (ctx) {
          bool timersInitialized = false;
          int verifyCooldown = 0;
          bool verifying = false;
          String twoDigits(int n) => n.toString().padLeft(2, '0');
          return StatefulBuilder(
            builder: (context, setState) {
              if (!timersInitialized) {
                timersInitialized = true;
                countdownTimer = Timer.periodic(const Duration(seconds: 1), (
                  _,
                ) {
                  if (secondsLeft > 0) {
                    setState(() => secondsLeft--);
                  } else {
                    countdownTimer?.cancel();
                  }
                });
                cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                  if (resendCooldown > 0) {
                    setState(() => resendCooldown--);
                  } else {
                    cooldownTimer?.cancel();
                  }
                });
              }

              final m = secondsLeft ~/ 60;
              final s = secondsLeft % 60;

              return AlertDialog(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Verify Mobile'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: secondsLeft > 0
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        secondsLeft > 0
                            ? 'Expires in ${twoDigits(m)}:${twoDigits(s)}'
                            : 'OTP expired',
                        style: TextStyle(
                          color: secondsLeft > 0 ? Colors.blue : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        keyboardType: TextInputType.number,
                        maxLength: otpLength,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          counterText: '',
                        ),
                        onChanged: (v) => code = v.trim(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: (resendCooldown > 0)
                              ? null
                              : () async {
                                  try {
                                    await api.post(
                                      '/resend-otp',
                                      data: {
                                        'phone': userMobile,
                                        'type': 'profile_update',
                                      },
                                    );
                                    setState(() {
                                      resendCooldown = 60;
                                    });
                                    cooldownTimer?.cancel();
                                    cooldownTimer = Timer.periodic(
                                      const Duration(seconds: 1),
                                      (_) {
                                        if (resendCooldown > 0) {
                                          setState(() => resendCooldown--);
                                        } else {
                                          cooldownTimer?.cancel();
                                        }
                                      },
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('OTP resent'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to resend OTP: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            resendCooldown > 0
                                ? 'Resend (${resendCooldown}s)'
                                : 'Resend OTP',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      countdownTimer?.cancel();
                      cooldownTimer?.cancel();
                      verifyTimer?.cancel();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        (code.length == otpLength &&
                            secondsLeft > 0 &&
                            verifyCooldown == 0 &&
                            !verifying)
                        ? () async {
                            setState(() => verifying = true);
                            try {
                              await api.post(
                                '/verify-otp',
                                data: {
                                  'phone': userMobile,
                                  'otp': code,
                                  'type': 'profile_update',
                                },
                              );
                              countdownTimer?.cancel();
                              cooldownTimer?.cancel();
                              verifyTimer?.cancel();
                              if (mounted) Navigator.pop(ctx);
                              setState(() => userPhoneVerified = true);
                              await _loadUserFromAPI();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Mobile verified successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              final msg = e.toString();
                              final isLimit =
                                  msg.contains('HTTP 429') ||
                                  msg.toLowerCase().contains('429') ||
                                  msg.toLowerCase().contains('limit');
                              if (isLimit) {
                                setState(() => verifyCooldown = 60);
                                verifyTimer?.cancel();
                                verifyTimer = Timer.periodic(
                                  const Duration(seconds: 1),
                                  (_) {
                                    if (verifyCooldown > 0) {
                                      setState(() => verifyCooldown--);
                                    } else {
                                      verifyTimer?.cancel();
                                    }
                                  },
                                );
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isLimit
                                          ? 'OTP attempt limit exceeded. Please wait and try again.'
                                          : 'Verification failed: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              setState(() => verifying = false);
                            }
                          }
                        : null,
                    child: verifying
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            verifyCooldown > 0
                                ? 'Wait (${twoDigits(verifyCooldown)})'
                                : 'Verify',
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return AppStrings.getString(
        'good_morning',
        ref.read(languageProvider).code,
      );
    } else if (hour < 17) {
      return AppStrings.getString(
        'good_afternoon',
        ref.read(languageProvider).code,
      );
    } else {
      return AppStrings.getString(
        'good_evening',
        ref.read(languageProvider).code,
      );
    }
  }

  // Calculate profile completion percentage
  void _calculateProfileCompletion() {
    double completion = 0.0;
    int totalFields = 0;
    int completedFields = 0;

    // Check user name
    totalFields++;
    if (userName.isNotEmpty) completedFields++;

    // Check user email
    totalFields++;
    if (userEmail.isNotEmpty) completedFields++;

    // Check user mobile
    totalFields++;
    if (userMobile.isNotEmpty) completedFields++;

    // Check phone verification
    totalFields++;
    if (userPhoneVerified) completedFields++;

    // Check profile picture
    totalFields++;
    if (userProfilePic.isNotEmpty) completedFields++;

    // Calculate percentage
    if (totalFields > 0) {
      completion = completedFields / totalFields;
    }

    setState(() {
      _profileCompletion = completion;
    });

    print(
      'DEBUG: Profile completion calculated: $_profileCompletion ($completedFields/$totalFields)',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);

    // Debug logs for banner visibility
    print(
      'DEBUG: Build method - userPhoneVerified: $userPhoneVerified, _profileCompletion: $_profileCompletion',
    );
    print('DEBUG: Build method - userMobile: "$userMobile"');
    print(
      'DEBUG: Build method - Banner conditions: !userPhoneVerified = ${!userPhoneVerified}, _profileCompletion < 0.8 = ${_profileCompletion < 0.8}',
    );

    return Focus(
      focusNode: _focusNode,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          endDrawer: CustomDrawer(),
          drawerScrimColor: Colors.black54,

          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                Positioned(
                  top: -MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: _buildFullWidthColorSection(),
                ),
                Column(
                  children: [
                    _buildModernProfileHeader(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshAllData,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              if (_unpaidSubInvoices.isNotEmpty)
                                _buildUnpaidSubscriptionInvoices(),
                              SizedBox(height: 4),
                              if (_userLoaded && !userPhoneVerified)
                                _buildAttentionBanner(
                                  title: AppText('mobile_verification_title'),
                                  message: AppText(
                                    'mobile_verification_message',
                                  ),
                                  buttonLabel: AppText(
                                    'mobile_verification_button',
                                  ),
                                  onPressed: _otpBusy
                                      ? null
                                      : _startMobileVerificationFlow,
                                ),
                              if (_userLoaded && _profileCompletion < 0.8)
                                _buildProgressBanner(
                                  percent: _profileCompletion,
                                  onPressed: () => context.go('/profile/edit'),
                                ),
                              SizedBox(height: 4),
                              _buildSmsBalanceCard(),
                              SizedBox(height: 4),
                              _buildSummaryCards(),
                              SizedBox(height: 16),

                              // Statistics Overview
                              _buildStatisticsOverviewSection(),

                              SizedBox(height: 16),

                              _buildRecentActivity(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader() {
    // final languageNotifier = ref.read(languageProvider.notifier);

    return Container(
      margin: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        8,
        8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            Color(0xFF6C63FF), // Purple accent
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Row: Avatar, Info, Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Compact Avatar - Clickable
                    GestureDetector(
                      onTap: () {
                        context.push('/profile');
                      },
                      child: Stack(
                        children: [
                          _DashboardAvatar(picUrl: userProfilePic),
                          // Status indicator
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),

                    // User Info with better typography - Clickable
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/profile');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    userName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                if (userPhoneVerified) ...[
                                  SizedBox(width: 6),
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      color: Colors.greenAccent,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action buttons row
                    Row(
                      children: [
                        // Notification button with badge
                        Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  // final languageNotifier = ref.read(languageProvider.notifier);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: AppText(
                                        'notifications_coming_soon',
                                      ),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            // Notification badge
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: 8),

                        // Menu button
                        Builder(
                          builder: (context) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Scaffold.of(context).openEndDrawer();
                              },
                              icon: Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Full Width Subscription Section
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Subscription Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isSubscriptionLoading) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  GestureDetector(
                                    onTap: () =>
                                        context.go('/subscription-center'),
                                    child:
                                        subscriptionPlan.toLowerCase() == 'free'
                                        ? AppText(
                                            'free_plan',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : Text(
                                            '$subscriptionPlan Plan',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                  SizedBox(height: 2),
                                  GestureDetector(
                                    onTap: () =>
                                        context.go('/subscription-center'),
                                    child: Row(
                                      children: [
                                        _subMiniStat(
                                          icon: Icons.apartment_rounded,
                                          label: 'Property',
                                          value:
                                              (_subscriptionData?['plan']?['properties_limit']
                                                          ?.toString() ??
                                                      _dashboardStats['plan']?['properties_limit']
                                                          ?.toString() ??
                                                      _dashboardStats['properties_limit_text'] ??
                                                      '—')
                                                  .toString(),
                                        ),
                                        SizedBox(width: 8),
                                        _subMiniStat(
                                          icon: Icons.meeting_room_rounded,
                                          label: 'Unit',
                                          value:
                                              (_subscriptionData?['plan']?['units_limit']
                                                          ?.toString() ??
                                                      _dashboardStats['plan']?['units_limit']
                                                          ?.toString() ??
                                                      _dashboardStats['units_limit_text'] ??
                                                      '—')
                                                  .toString(),
                                        ),
                                        SizedBox(width: 8),
                                        _subMiniStat(
                                          icon: Icons.sms_rounded,
                                          label: 'SMS',
                                          value:
                                              (_subscriptionData?['sms_credits']
                                                          ?.toString() ??
                                                      _dashboardStats['sms_credit']
                                                          ?.toString() ??
                                                      '—')
                                                  .toString(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Upgrade/Manage Button
                          if (!isSubscriptionLoading) ...[
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  context.go('/subscription-plans');
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        subscriptionPlan.toLowerCase() == 'free'
                                            ? Icons.rocket_launch_rounded
                                            : Icons.settings_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Upgrade',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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

  Widget _buildSummaryCards() {
    print('DEBUG: _buildSummaryCards called');
    // final languageNotifier = ref.read(languageProvider.notifier);

    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              AppText(
                'loading_dashboard',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Prepare property/unit limit display values (count/limit)
    String _fmtLimit(dynamic raw) {
      if (raw == null) return '—';
      if (raw is num) return raw.toInt() == -1 ? '∞' : raw.toInt().toString();
      final p = int.tryParse(raw.toString());
      if (p == null) return raw.toString();
      return p == -1 ? '∞' : p.toString();
    }

    final int propCount = (_dashboardStats['total_properties'] ?? 0) is num
        ? (_dashboardStats['total_properties'] as num).toInt()
        : int.tryParse(
                (_dashboardStats['total_properties'] ?? '0').toString(),
              ) ??
              0;
    final dynamic propLimitRaw =
        _subscriptionData?['plan']?['properties_limit'] ??
        _subscriptionData?['properties_limit'] ??
        _dashboardStats['plan']?['properties_limit'] ??
        _dashboardStats['properties_limit_text'];
    final String propValue = '$propCount/${_fmtLimit(propLimitRaw)}';

    final int unitCount = (_dashboardStats['total_units'] ?? 0) is num
        ? (_dashboardStats['total_units'] as num).toInt()
        : int.tryParse((_dashboardStats['total_units'] ?? '0').toString()) ?? 0;
    final dynamic unitLimitRaw =
        _subscriptionData?['plan']?['units_limit'] ??
        _subscriptionData?['units_limit'] ??
        _dashboardStats['plan']?['units_limit'] ??
        _dashboardStats['units_limit_text'];
    final String unitValue = '$unitCount/${_fmtLimit(unitLimitRaw)}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Single Row - All 5 Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SummaryCard(
                  title: AppStrings.getString(
                    'properties',
                    ref.read(languageProvider).code,
                  ),
                  value: propValue,
                  icon: Icons.apartment_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    context.go('/properties');
                  },
                ),
                SizedBox(width: 8),
                _SummaryCard(
                  title: AppStrings.getString(
                    'units',
                    ref.read(languageProvider).code,
                  ),
                  value: unitValue,
                  icon: Icons.home_rounded,
                  color: Colors.orange,
                  onTap: () {
                    context.go('/units');
                  },
                ),
                SizedBox(width: 8),
                _SummaryCard(
                  title: AppStrings.getString(
                    'tenants',
                    ref.read(languageProvider).code,
                  ),
                  value: '${_dashboardStats['total_tenants'] ?? 0}',
                  icon: Icons.people_rounded,
                  color: Colors.green,
                  onTap: () {
                    context.go('/tenants');
                  },
                ),
                SizedBox(width: 8),
                _SummaryCard(
                  title: AppStrings.getString(
                    'collections',
                    ref.read(languageProvider).code,
                  ),
                  value: '৳${_dashboardStats['total_collections'] ?? 0}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.blue,
                  subtitle: AppStrings.getString(
                    'this_month',
                    ref.read(languageProvider).code,
                  ),
                ),
                SizedBox(width: 8),
                _SummaryCard(
                  title: AppStrings.getString(
                    'due_amount',
                    ref.read(languageProvider).code,
                  ),
                  value: '৳${_dashboardStats['total_due'] ?? 0}',
                  icon: Icons.schedule_rounded,
                  color: Colors.red,
                  subtitle: AppStrings.getString(
                    'pending',
                    ref.read(languageProvider).code,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    print('DEBUG: _buildRecentActivity called');
    // final languageNotifier = ref.read(languageProvider.notifier);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'recent_transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/billing');
                },
                child: AppText(
                  'view_all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          if (_recentTransactions.isEmpty)
            Container(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 48,
                      color: AppColors.gray.withOpacity(0.6),
                    ),
                    SizedBox(height: 12),
                    AppText(
                      'no_recent_transactions',
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length > 3
                  ? 3
                  : _recentTransactions.length,
              separatorBuilder: (context, index) => Divider(height: 24),
              itemBuilder: (context, index) {
                final transaction = _recentTransactions[index];
                return _buildTransactionItem(transaction);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUnpaidSubscriptionInvoices() {
    // White card style similar to mobile verification banner
    return Column(
      children: _unpaidSubInvoices.take(3).map((inv) {
        final invoiceNo = (inv['invoice_number'] ?? inv['number'] ?? '—')
            .toString();
        final amount = (inv['net_amount'] ?? inv['amount'] ?? 0).toString();
        final isPaid = (inv['status'] ?? '').toString().toLowerCase() == 'paid';
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoiceNo,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '৳$amount',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              TextButton(
                onPressed: isPaid
                    ? null
                    : () {
                        context.go(
                          '/subscription-checkout',
                          extra: {'invoice': inv},
                        );
                      },
                style: TextButton.styleFrom(
                  foregroundColor: isPaid ? Colors.green : Colors.white,
                  backgroundColor: isPaid
                      ? Colors.green.withOpacity(0.12)
                      : AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(isPaid ? 'Paid' : 'Pay Now'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    // final languageNotifier = ref.read(languageProvider.notifier);

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction['description'] ??
                    AppStrings.getString(
                      'transaction',
                      ref.read(languageProvider).code,
                    ),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 4),
              Text(
                transaction['date'] ?? '',
                style: TextStyle(color: AppColors.gray, fontSize: 13),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '৳${transaction['amount'] ?? 0}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppStrings.getString('paid', ref.read(languageProvider).code),
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullWidthColorSection() {
    return Container(
      width: double.infinity,
      height:
          180 + MediaQuery.of(context).padding.top, // Include status bar height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.6), // Primary color to match header
            AppColors.primary.withOpacity(0.4), // Medium primary
            Color(0xFF6C63FF).withOpacity(0.3), // Purple accent like header
            AppColors.primary.withOpacity(0.2), // Light primary
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // Quick Actions removed as per request
  // Note: _buildQuickActionButton method was also removed

  // Statistics Overview Section
  Widget _buildStatisticsOverviewSection() {
    print('DEBUG: _buildStatisticsOverviewSection called');
    final double monthlyCollections = _getMonthlyCollections();
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Statistics Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up_rounded,
                  label: 'Monthly Revenue',
                  value: '৳${monthlyCollections.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people_rounded,
                  label: 'Active Tenants',
                  value: '0', // Use static value for now
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.home_rounded,
                  label: 'Occupancy Rate',
                  value: '0%', // Use static value for now
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getMonthlyCollections() {
    try {
      // Prefer backend-provided monthly collections if available
      final dynamic backendMonthly =
          _dashboardStats['collections_this_month'] ??
          _dashboardStats['monthly_collections'] ??
          _dashboardStats['total_collections_this_month'];
      if (backendMonthly != null) {
        if (backendMonthly is num) return backendMonthly.toDouble();
        final parsed = double.tryParse(backendMonthly.toString());
        if (parsed != null) return parsed;
      }

      // Fallback: sum recent transactions in current month
      final now = DateTime.now();
      double sum = 0.0;
      for (final tx in _recentTransactions) {
        try {
          final amtRaw = tx['amount'];
          final dateRaw = tx['date'];
          if (amtRaw == null || dateRaw == null) continue;
          final amount = (amtRaw is num)
              ? amtRaw.toDouble()
              : (double.tryParse(amtRaw.toString()) ?? 0.0);
          if (amount <= 0) continue;
          final dt = DateTime.tryParse(dateRaw.toString());
          if (dt == null) continue;
          if (dt.year == now.year && dt.month == now.month) {
            sum += amount;
          }
        } catch (_) {}
      }
      return sum;
    } catch (_) {
      return 0.0;
    }
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    print('DEBUG: _buildStatItem called with label: $label, value: $value');
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.gray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // _showProfileSummaryMenu removed - profile navigates directly

  Widget _buildSmsBalanceCard() {
    final String smsBalance =
        (_subscriptionData?['sms_credits'] ??
                _dashboardStats['sms_credit'] ??
                0)
            .toString();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sms_rounded, color: AppColors.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMS Balance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  smsBalance,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Recharge SMS coming soon')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Recharge SMS'),
          ),
        ],
      ),
    );
  }
}

class _DashboardAvatar extends StatelessWidget {
  final String picUrl;
  const _DashboardAvatar({required this.picUrl});

  @override
  Widget build(BuildContext context) {
    final String normalized = _normalize(picUrl);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD700), // Golden color
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: normalized.isEmpty
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              )
            : Image.network(
                normalized,
                headers: const {'Cache-Control': 'no-cache'},
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  );
                },
              ),
      ),
    );
  }

  static String _normalize(String raw) {
    final pic = (raw).trim();
    if (pic.isEmpty) return '';

    String origin() {
      final base = ApiConfig.getBaseUrl();
      return base.replaceFirst(RegExp(r'/api/?$'), '');
    }

    // Absolute URL handling
    if (pic.startsWith('http://') || pic.startsWith('https://')) {
      try {
        final uri = Uri.parse(pic);
        final p = uri.path;
        // If points to storage, map to media proxy
        if (p.startsWith('/storage/')) {
          final withoutStorage = p.replaceFirst('/storage/', '/');
          if (withoutStorage.startsWith('/profiles/')) {
            return '${origin()}/api/media$withoutStorage';
          }
          return '${origin()}$withoutStorage';
        }
        // If points to profiles, prefer media proxy to avoid web restrictions
        if (p.startsWith('/profiles/')) {
          return '${origin()}/api/media$p';
        }
        return pic;
      } catch (_) {
        return pic;
      }
    }

    // Relative path handling
    if (pic.startsWith('/storage/')) {
      final without = pic.replaceFirst('/storage/', '/');
      return without.startsWith('/profiles/')
          ? '${origin()}/api/media$without'
          : '${origin()}$without';
    }
    if (pic.startsWith('/profiles/')) {
      return '${origin()}/api/media$pic';
    }
    if (pic.startsWith('profiles/')) {
      return '${origin()}/api/media/$pic';
    }

    return '${origin()}/$pic';
  }
}

// Enhanced Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.6),
                    size: 16,
                  ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.gray,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gray.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
