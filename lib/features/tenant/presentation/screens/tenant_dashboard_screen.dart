import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'dart:async';
import 'dart:convert';
import 'package:hrms_app/features/tenant/presentation/screens/invoice_pdf_screen.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/services/security_service.dart';
import 'package:hrms_app/core/widgets/ads_banner.dart';
import 'package:hrms_app/core/providers/ads_provider.dart';
import 'package:hrms_app/core/services/api_service.dart';
// import 'package:hrms_app/features/tenant/presentation/screens/debug_screen.dart';

class TenantDashboardScreen extends ConsumerStatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  _TenantDashboardScreenState createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends ConsumerState<TenantDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic>? _tenantInfo;

  // Profile completion
  double _profileCompletion = 0.0;
  bool _userLoaded = false;

  // Mobile verification state
  bool _otpBusy = false;
  String _userMobile = '';

  // OTP Settings
  int _otpExpireTime = 600; // Default: 10 minutes
  int _otpResendTime = 60; // Default: 1 minute
  int _otpLength = 6; // Default: 6 digits
  int _maxAttempts = 3; // Default: 3 attempts
  bool _isOtpEnabled = true; // Default: enabled
  bool _requireOtpForTenantRegistration = false; // Default: disabled

  // Ads Settings
  bool _isAdsEnabled = true; // Default: enabled
  List<Map<String, dynamic>> _adsData = []; // Store actual ads content

  // Ads Banner Controller
  late PageController _adsPageController;
  int _currentAdsPage = 0;
  Timer? _adsAutoScrollTimer;

  // Flag to track if widget is being disposed
  bool _isDisposed = false;

  void _showDailyLimitNotice() {
    // Close any existing popup (like OTP dialog), then show the notice on next frame
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Limit Reached',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (_) {
        // Fallback: bottom sheet
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          builder: (b) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Daily Limit Reached',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '📱 You have reached the daily OTP limit for this phone number.',
                  softWrap: true,
                ),
                SizedBox(height: 8),
                Text('⏰ Please try again tomorrow.'),
                SizedBox(height: 8),
                Text('📞 Contact admin if you need immediate assistance.'),
              ],
            ),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _adsPageController = PageController();
    _loadDashboardData();
    _loadOtpSettings();
    _loadAdsSettings();
    _startAdsAutoScroll();
    _restoreStatusBar();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _adsAutoScrollTimer?.cancel();
    _adsPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restore status bar when returning to this screen
    _restoreStatusBar();
  }

  // Load ads settings and content from system
  Future<void> _loadAdsSettings() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/ads/dashboard?type=tenant');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔍 [Dashboard] Ads API response: $data');

        if (data['success'] == true) {
          final adsEnabled = data['data']['ads_enabled'] ?? true;
          final adsList = data['data']['ads'] ?? [];

          print(
            '🔍 [Dashboard] Parsed - ads_enabled: $adsEnabled, ads count: ${adsList.length}',
          );

          if (mounted && !_isDisposed) {
            setState(() {
              _isAdsEnabled = adsEnabled;
              _adsData = List<Map<String, dynamic>>.from(adsList);
            });

            // Restart auto-scroll with new ads data
            if (mounted && !_isDisposed) {
              _adsAutoScrollTimer?.cancel();
              _startAdsAutoScroll();
            }
          }
          print(
            '🔍 [Dashboard] Ads enabled: $_isAdsEnabled, Count: ${_adsData.length}',
          );
        }
      }
    } catch (e) {
      print('❌ [Dashboard] Failed to load ads settings: $e');
      // Keep default values on error
    }
  }

  // Start auto-scrolling for ads banner
  void _startAdsAutoScroll() {
    if (_adsData.isEmpty || !mounted || _isDisposed) return;

    _adsAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isDisposed && _adsData.length > 1) {
        final nextPage = (_currentAdsPage + 1) % _adsData.length;

        // Check if controller is still valid
        if (_adsPageController.hasClients) {
          _adsPageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );

          // Double-check before setState
          if (mounted && !_isDisposed) {
            setState(() {
              _currentAdsPage = nextPage;
            });
          }
        }
      }
    });
  }

  // Restore status bar visibility
  void _restoreStatusBar() {
    try {
      // Set status bar to be visible with transparent background
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );

      // Ensure status bar is visible
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],
      );

      print('🔍 [Dashboard] Status bar restored');
    } catch (e) {
      print('⚠️ [Dashboard] Failed to restore status bar: $e');
    }
  }

  // Load OTP settings from system
  Future<void> _loadOtpSettings() async {
    try {
      final apiService = ref.read(apiServiceProvider);

      // Try to load from OTP settings API first
      try {
        final response = await apiService.get('/otp-settings');
        final data = response.data;

        print('DEBUG: OTP Settings API Response: $data');

        if (data['success'] == true) {
          final dynamic rawSettings = data['settings'] ?? data['data'];
          if (rawSettings is Map) {
            final settings = rawSettings as Map;
            print('DEBUG: OTP Settings parsed: $settings');

            if (mounted && !_isDisposed) {
              setState(() {
                _otpExpireTime =
                    (settings['otp_expiry_minutes'] ?? 10) * 60; // seconds
                _otpResendTime = settings['resend_cooldown_seconds'] ?? 60;
                _otpLength = settings['otp_length'] ?? 6;
                _maxAttempts = settings['max_attempts'] ?? 3;
                _isOtpEnabled = settings['is_enabled'] ?? true;
                _requireOtpForTenantRegistration =
                    (settings['profile_update_required'] == true) ||
                    (settings['require_otp_for_tenant_registration'] == true);
              });
            }
            print(
              'OTP Settings loaded - Expire: ${_otpExpireTime}s, Resend: ${_otpResendTime}s, Length: ${_otpLength}, Max Attempts: ${_maxAttempts}, Enabled: ${_isOtpEnabled}, Tenant Registration OTP: ${_requireOtpForTenantRegistration}',
            );

            return;
          }
        }
      } catch (e) {
        print('OTP Settings API failed: $e');
      }

      // Fallback removed: rely solely on /otp-settings

      // Final fallback: Use default values
      print(
        'Using default OTP settings - Expire: ${_otpExpireTime}s, Resend: ${_otpResendTime}s, Tenant Registration OTP: $_requireOtpForTenantRegistration',
      );
    } catch (e) {
      print('Failed to load OTP settings: $e');
      // Keep default values
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadOtpSettings(),
      _loadDashboardData(),
      _loadAdsSettings(),
    ]);
  }

  Future<void> _loadDashboardData() async {
    try {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = true;
        });
      }

      final apiService = ref.read(apiServiceProvider);

      final response = await apiService.get('/tenant/dashboard');

      if (response.statusCode == 200) {
        final data = response.data;
        print('API Response: $data'); // Debug: Print full API response
        print(
          'Tenant Info: ${data['data']?['tenant']}',
        ); // Debug: Print tenant info
        if (mounted && !_isDisposed) {
          setState(() {
            final dynamic dataRoot = data['data'] ?? data;
            _dashboardData = (dataRoot is Map<String, dynamic>) ? dataRoot : {};
            final dynamic t = (dataRoot is Map<String, dynamic>)
                ? dataRoot['tenant']
                : null;
            _tenantInfo = (t is Map<String, dynamic>)
                ? t
                : (data['tenant'] is Map<String, dynamic>
                      ? data['tenant']
                      : null);
            _isLoading = false;
          });
        }

        // Debug tenant info after setState
        print('DEBUG: Tenant info loaded:');
        if (_tenantInfo != null) {
          print('  - _tenantInfo keys: ${_tenantInfo!.keys.toList()}');
          print('  - phone_verified: ${_tenantInfo!['phone_verified']}');
          print('  - mobile_verified: ${_tenantInfo!['mobile_verified']}');
          print('  - _isPhoneVerified(): ${_isPhoneVerified()}');
        } else {
          print('  - _tenantInfo is null');
        }

        _debugCurrencySettings();
        _calculateProfileCompletion();

        // Load ads settings to get latest status
        _loadAdsSettings();

        // Debug OTP settings
        print(
          'Current OTP Settings - Expire: ${_otpExpireTime}s, Resend: ${_otpResendTime}s',
        );
      } else {
        throw Exception('Failed to load dashboard');
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Calculate profile completion percentage
  void _calculateProfileCompletion() {
    double completion = 0.0;
    int totalFields = 0;
    int completedFields = 0;

    final info = _tenantInfo;
    if (info != null) {
      // Check tenant name (use raw fields, avoid placeholder)
      totalFields++;
      final rawFirst = (info['first_name'] ?? '').toString().trim();
      final rawName = (info['name'] ?? '').toString().trim();
      final hasRealName =
          rawFirst.isNotEmpty ||
          (rawName.isNotEmpty && rawName.toLowerCase() != 'tenant');
      if (hasRealName) completedFields++;

      // Check tenant email
      totalFields++;
      final email = (info['email'] ?? '').toString().trim();
      if (email.isNotEmpty) completedFields++;

      // Check tenant mobile
      totalFields++;
      final mobile = (info['mobile'] ?? info['phone'] ?? '').toString().trim();
      if (mobile.isNotEmpty) completedFields++;

      // Check phone verification
      totalFields++;
      if (_isPhoneVerified()) completedFields++;

      // Check profile picture
      totalFields++;
      final profilePic = (info['profile_pic'] ?? '').toString().trim();
      if (profilePic.isNotEmpty) completedFields++;

      // Calculate percentage
      if (totalFields > 0) {
        completion = completedFields / totalFields;
      }
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _profileCompletion = completion.clamp(0.0, 1.0);
        _userLoaded = true;
      });
    }

    print(
      'DEBUG: Profile completion calculated: $_profileCompletion ($completedFields/$totalFields)',
    );
  }

  bool _isPhoneVerified() {
    final info = _tenantInfo;
    if (info == null) {
      print('DEBUG: _tenantInfo is null');
      return false;
    }

    dynamic phoneVerified = info['phone_verified'];
    dynamic mobileVerified = info['mobile_verified'];

    bool isTruthy(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v == 1;
      if (v is String) {
        final s = v.trim().toLowerCase();
        return s == '1' || s == 'true' || s == 'yes';
      }
      return false;
    }

    final result = isTruthy(phoneVerified) || isTruthy(mobileVerified);
    print('DEBUG: Phone verification result (bool-only): $result');
    return result;
  }

  void _debugCurrencySettings() {
    try {
      final s1 = _dashboardData['settings'];
      final s2 = _dashboardData['system_settings'];
      final s3 = _dashboardData['app_settings'];
      final s4 = _dashboardData['config'];
      print(
        '[Settings] settings keys: ' +
            ((s1 is Map) ? (s1.keys.toList()).toString() : s1.toString()),
      );
      print(
        '[Settings] system_settings keys: ' +
            ((s2 is Map) ? (s2.keys.toList()).toString() : s2.toString()),
      );
      print(
        '[Settings] app_settings keys: ' +
            ((s3 is Map) ? (s3.keys.toList()).toString() : s3.toString()),
      );
      print(
        '[Settings] config keys: ' +
            ((s4 is Map) ? (s4.keys.toList()).toString() : s4.toString()),
      );
      print('[Currency] symbol: ' + _getCurrencySymbol());
      print(
        '[Currency] position: ' + (_isCurrencyPrefix() ? 'prefix' : 'suffix'),
      );
      print('[Currency] decimals: ' + _getCurrencyDecimals().toString());
      print('[Currency] computed monthly rent: ' + _getTenantMonthlyRent());
    } catch (e) {
      print('[Currency Debug] error: ' + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              _buildModernProfileHeader(),

              if (_userLoaded &&
                  _isOtpEnabled &&
                  !_isPhoneVerified() &&
                  _requireOtpForTenantRegistration)
                RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: AppColors.primary,
                  child: _buildAttentionBanner(
                    title: Text('Profile Update Requires Mobile Verification'),
                    buttonLabel: Text('Verify Now'),
                    onPressed: () {
                      _startMobileVerificationFlow();
                    },
                  ),
                ),
              if (_userLoaded && _profileCompletion < 0.9)
                RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: AppColors.primary,
                  child: _buildProgressBanner(
                    percent: _profileCompletion,
                    onPressed: () => context.go('/tenant/profile'),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: 4),
                        if (_isLoading)
                          _buildLoadingSection()
                        else
                          _buildDashboardContent(),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader() {
    return Container(
      margin: EdgeInsets.all(8),
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
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Row: Avatar, Info, Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Compact Avatar - Clickable
                  GestureDetector(
                    onTap: () {
                      context.go('/tenant/profile');
                    },
                    child: Stack(
                      children: [
                        _DashboardAvatar(picUrl: _getTenantProfilePic()),
                        // Status indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
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
                        context.go('/tenant/profile');
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
                                  _getTenantFullName(),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
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
                            width: 36,
                            height: 36,
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Notifications coming soon!'),
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
                                size: 18,
                              ),
                            ),
                          ),
                          // Notification badge
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Menu button removed as per request
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Full Width Tenant Info Section
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(10),
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
                        // Tenant Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  _subMiniStat(
                                    icon: Icons.apartment_rounded,
                                    label: 'Property',
                                    value: _getTenantPropertyName(),
                                  ),
                                  SizedBox(width: 10),
                                  _subMiniStat(
                                    icon: Icons.home_rounded,
                                    label: 'Unit',
                                    value: _getTenantUnitName(),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              _subMiniStat(
                                icon: Icons.storefront,
                                label: 'Monthly Total',
                                value: _getTenantMonthlyTotal(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getTenantProfilePic() {
    if (_tenantInfo != null) {
      final raw = (_tenantInfo!['profile_pic'] ?? '').toString().trim();
      if (raw.isEmpty) return '';
      // cache-busting to avoid stale cache
      final sep = raw.contains('?') ? '&' : '?';
      return '$raw${sep}t=${DateTime.now().millisecondsSinceEpoch}';
    }
    return '';
  }

  String _getTenantUnitName() {
    final info = _tenantInfo;
    if (info == null) return 'N/A';
    // common variants
    final byFlat =
        info['unit_name'] ??
        info['flat'] ??
        info['unit'] ??
        info['unit_number'];
    if (byFlat is String && byFlat.trim().isNotEmpty) return byFlat;
    // nested
    final unitObj = info['unit'] is Map ? info['unit'] as Map : null;
    final unitName =
        unitObj?['name'] ?? unitObj?['unit_name'] ?? unitObj?['number'];
    if (unitName is String && unitName.trim().isNotEmpty) return unitName;
    return 'N/A';
  }

  String _getTenantPropertyName() {
    final info = _tenantInfo;
    if (info == null) return 'N/A';
    final direct =
        info['property_name'] ?? info['property'] ?? info['building'];
    if (direct is String && direct.trim().isNotEmpty) return direct;
    final propObj = info['property'] is Map ? info['property'] as Map : null;
    final name = propObj?['name'] ?? propObj?['title'];
    if (name is String && name.trim().isNotEmpty) return name;
    return 'N/A';
  }

  String _getTenantMonthlyRent() {
    final info = _tenantInfo;
    if (info == null) return 'N/A';
    dynamic rentRaw =
        info['monthly_rent'] ?? info['rent'] ?? info['monthly_amount'];
    // nested under unit or tenancy/lease
    final unitObj = info['unit'] is Map ? info['unit'] as Map : null;
    rentRaw ??= unitObj?['rent'];
    final leaseObj = info['lease'] is Map
        ? info['lease'] as Map
        : (info['tenancy'] is Map ? info['tenancy'] as Map : null);
    rentRaw ??= leaseObj?['rent'] ?? leaseObj?['monthly_rent'];
    if (rentRaw == null) return 'N/A';
    try {
      final num rent = rentRaw is num ? rentRaw : num.parse(rentRaw.toString());
      return _formatCurrency(rent);
    } catch (_) {
      return _formatCurrencyFallback(rentRaw.toString());
    }
  }

  String _getTenantMonthlyTotal() {
    final info = _tenantInfo;
    if (info == null) return 'N/A';

    // Get base rent
    dynamic rentRaw =
        info['monthly_rent'] ?? info['rent'] ?? info['monthly_amount'];
    final unitObj = info['unit'] is Map ? info['unit'] as Map : null;
    rentRaw ??= unitObj?['rent'];
    final leaseObj = info['lease'] is Map
        ? info['lease'] as Map
        : (info['tenancy'] is Map ? info['tenancy'] as Map : null);
    rentRaw ??= leaseObj?['rent'] ?? leaseObj?['monthly_rent'];

    // Get additional fees from unit charges
    num totalFees = 0;
    print('DEBUG: Unit object: $unitObj');
    if (unitObj != null) {
      print('DEBUG: Unit charges: ${unitObj['charges']}');
      if (unitObj['charges'] != null) {
        final charges = unitObj['charges'] as List;
        print('DEBUG: Charges list length: ${charges.length}');
        for (final charge in charges) {
          if (charge is Map) {
            try {
              final amount = charge['amount'] is num
                  ? charge['amount'] as num
                  : num.parse(charge['amount'].toString());
              totalFees += amount;
              print('DEBUG: Unit charge - ${charge['label']}: $amount');
            } catch (_) {
              // Skip invalid charges
            }
          }
        }
      } else {
        print('DEBUG: No charges found in unit object');
      }
    } else {
      print('DEBUG: No unit object found');
    }

    print('DEBUG: Unit charges total: $totalFees');

    // Calculate total (rent + fees)
    if (rentRaw == null) return 'N/A';
    try {
      final num rent = rentRaw is num ? rentRaw : num.parse(rentRaw.toString());
      final num total = rent + totalFees;
      print(
        'DEBUG: Final calculation - Base Rent: $rent, Total Fees: $totalFees, Total: $total',
      );
      return _formatCurrency(total);
    } catch (_) {
      return _formatCurrencyFallback(rentRaw.toString());
    }
  }

  String _formatCurrency(num amount) {
    final String symbol = _getCurrencySymbol();
    final int decimals = _getCurrencyDecimals();
    final String amountStr = amount.toStringAsFixed(decimals);
    final bool prefix = _isCurrencyPrefix();
    if (symbol.isEmpty) return amountStr;
    return prefix ? '$symbol$amountStr' : '$amountStr $symbol';
  }

  String _formatCurrencyFallback(String amountStr) {
    final String symbol = _getCurrencySymbol();
    final bool prefix = _isCurrencyPrefix();
    if (symbol.isEmpty) return amountStr;
    return prefix ? '$symbol$amountStr' : '$amountStr $symbol';
  }

  String _getCurrencySymbol() {
    Map? candidateSettings;
    final dynamic s1 = _dashboardData['settings'];
    final dynamic s2 = _dashboardData['system_settings'];
    final dynamic s3 = _dashboardData['app_settings'];
    final dynamic s4 = _dashboardData['config'];
    if (s1 is Map) candidateSettings ??= s1;
    if (s2 is Map) candidateSettings ??= s2;
    if (s3 is Map) candidateSettings ??= s3;
    if (s4 is Map) candidateSettings ??= s4;

    String normalizeCodeToSymbol(String raw) {
      final code = raw.trim().toUpperCase();
      switch (code) {
        case 'BDT':
        case 'TAKA':
        case 'TK':
        case '৳':
          return '৳';
        case 'USD':
        case '\$':
          return '\$';
        case 'EUR':
        case '€':
          return '€';
        case 'GBP':
        case '£':
          return '£';
        case 'INR':
        case '₹':
          return '₹';
        default:
          return raw;
      }
    }

    String? fromSettings(Map settings) {
      final dynamic sym =
          settings['system_currency_symbol'] ??
          settings['currency_symbol'] ??
          settings['currencySign'] ??
          settings['symbol'];
      if (sym is String && sym.trim().isNotEmpty) return sym;
      final dynamic code =
          settings['system_currency'] ??
          settings['currency_code'] ??
          settings['currency'];
      if (code is String && code.trim().isNotEmpty)
        return normalizeCodeToSymbol(code);
      return null;
    }

    if (candidateSettings != null) {
      final val = fromSettings(candidateSettings);
      if (val != null) return val;
    }

    final dynamic symRoot =
        _dashboardData['currency_symbol'] ?? _dashboardData['currency'];
    if (symRoot is String && symRoot.trim().isNotEmpty)
      return normalizeCodeToSymbol(symRoot);

    final Map<String, dynamic>? info = _tenantInfo;
    if (info != null) {
      final dynamic sym =
          info['currency_symbol'] ?? info['currency'] ?? info['currency_code'];
      if (sym is String && sym.trim().isNotEmpty)
        return normalizeCodeToSymbol(sym);
    }

    return '';
  }

  bool _isCurrencyPrefix() {
    final settings = _dashboardData['system_settings'];
    if (settings is Map) {
      final pos =
          settings['system_currency_position'] ??
          settings['currency_position'] ??
          settings['currencyPosition'];
      if (pos is String) {
        final p = pos.toLowerCase();
        if (p == 'prefix' || p == 'left') return true;
        if (p == 'suffix' || p == 'right') return false;
      }
    }
    return true;
  }

  int _getCurrencyDecimals() {
    final settings = _dashboardData['system_settings'];
    if (settings is Map) {
      final d =
          settings['system_decimal_places'] ??
          settings['currency_decimals'] ??
          settings['decimals'];
      if (d is int) return d;
      if (d is String) {
        final parsed = int.tryParse(d);
        if (parsed != null) return parsed;
      }
    }
    return 2;
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

    // Refresh OTP settings before starting verification
    await _loadOtpSettings();

    // Get mobile number from tenant info
    final info = _tenantInfo;
    if (info == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No tenant information found')));
      return;
    }

    final mobile = (info['mobile'] ?? info['phone'] ?? '').toString().trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No mobile number found in your profile')),
      );
      return;
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _otpBusy = true;
        _userMobile = mobile;
      });
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/send-otp',
        data: {'phone': mobile, 'type': 'profile_update'},
      );

      final responseData = response.data;
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Show OTP verification dialog
        await _showOtpVerificationDialog(mobile);
      } else {
        final message = responseData['message'] ?? 'Failed to send OTP';
        final errorType = responseData['error_type']?.toString() ?? '';
        final isDailyLimit =
            response.statusCode == 429 ||
            errorType == 'daily_limit' ||
            (message is String &&
                (message.contains('daily_limit') ||
                    message.contains('Daily OTP limit reached')));

        if (isDailyLimit) {
          _showDailyLimitNotice();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      final msg = e.toString();
      final isDailyLimit =
          msg.contains('HTTP 429') ||
          msg.contains('429') ||
          msg.contains('daily_limit') ||
          msg.contains('Daily OTP limit reached');

      if (isDailyLimit) {
        _showDailyLimitNotice();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _otpBusy = false;
        });
      }
    }
  }

  Future<void> _showOtpVerificationDialog(String mobile) async {
    String code = '';
    int secondsLeft = _otpExpireTime; // From OTP settings
    int resendCooldown = _otpResendTime; // From OTP settings
    Timer? countdownTimer;
    Timer? cooldownTimer;

    await showDialog(
      context: context,
      builder: (ctx) {
        bool timersInitialized = false;
        bool verifying = false;

        return StatefulBuilder(
          builder: (context, setState) {
            if (!timersInitialized) {
              timersInitialized = true;
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
                          ? 'Expires in ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                          : 'OTP expired',
                      style: TextStyle(
                        color: secondsLeft > 0 ? Colors.blue : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      keyboardType: TextInputType.number,
                      maxLength: _otpLength,
                      decoration: InputDecoration(
                        labelText: 'Enter OTP (${_otpLength} digits)',
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
                                  final apiService = ref.read(
                                    apiServiceProvider,
                                  );
                                  final resendResponse = await apiService.post(
                                    '/resend-otp',
                                    data: {
                                      'phone': mobile,
                                      'type': 'profile_update',
                                    },
                                  );

                                  final resendData = resendResponse.data;
                                  print(
                                    '🔍 DEBUG: Resend response status: ${resendResponse.statusCode}',
                                  );
                                  print(
                                    '🔍 DEBUG: Resend response data: $resendData',
                                  );

                                  if (resendResponse.statusCode == 200 &&
                                      resendData['success'] == true) {
                                    setState(() {
                                      resendCooldown =
                                          _otpResendTime; // From OTP settings
                                    });
                                  } else {
                                    print('🔍 DEBUG: Error response detected');
                                    print(
                                      '🔍 DEBUG: Status code: ${resendResponse.statusCode}',
                                    );
                                    print('🔍 DEBUG: Error data: $resendData');

                                    // Check for daily limit in response
                                    final errorMsg =
                                        resendData['message'] ??
                                        'Failed to resend OTP';
                                    final isDailyLimit =
                                        resendData['error_type'] ==
                                            'daily_limit' ||
                                        errorMsg.contains('daily_limit') ||
                                        errorMsg.contains(
                                          'Daily OTP limit reached',
                                        );

                                    print('🔍 DEBUG: Error message: $errorMsg');
                                    print(
                                      '🔍 DEBUG: Error type: ${resendData['error_type']}',
                                    );
                                    print(
                                      '🔍 DEBUG: Is daily limit: $isDailyLimit',
                                    );

                                    if (isDailyLimit) {
                                      _showDailyLimitNotice();
                                      return; // Don't throw exception
                                    }

                                    throw Exception(errorMsg);
                                  }
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('OTP resent'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('🔍 DEBUG: Exception caught: $e');
                                  print(
                                    '🔍 DEBUG: Exception type: ${e.runtimeType}',
                                  );

                                  if (mounted) {
                                    final errorMsg = e.toString();
                                    print('🔍 DEBUG: Error message: $errorMsg');

                                    final isDailyLimit =
                                        errorMsg.contains('daily_limit') ||
                                        errorMsg.contains(
                                          'Daily OTP limit reached',
                                        ) ||
                                        errorMsg.contains('429') ||
                                        errorMsg.contains('HTTP 429') ||
                                        errorMsg.contains('Client error') ||
                                        errorMsg.contains('status code of 429');

                                    print(
                                      '🔍 DEBUG: Is daily limit: $isDailyLimit',
                                    );

                                    if (isDailyLimit) {
                                      _showDailyLimitNotice();
                                    } else {
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
                                }
                              },
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          resendCooldown > 0
                              ? 'Resend in ${resendCooldown}s (${(_otpResendTime / 60).round()} min)'
                              : 'Resend OTP (${(_otpResendTime / 60).round()} min)',
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
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (code.length == 6 && secondsLeft > 0 && !verifying)
                      ? () async {
                          setState(() => verifying = true);
                          try {
                            print('🔍 DEBUG: Starting OTP verification...');
                            print('📱 DEBUG: Phone: $mobile');
                            print('🔢 DEBUG: OTP: $code');

                            final apiService = ref.read(apiServiceProvider);
                            final requestData = {
                              'phone': mobile,
                              'otp': code,
                              'type': 'profile_update',
                              'user_id':
                                  (await SecurityService.getStoredUserData())?['id'],
                            };

                            print('📤 DEBUG: Request data: $requestData');

                            final response = await apiService.post(
                              '/verify-otp',
                              data: requestData,
                            );

                            print(
                              '📥 DEBUG: Response status: ${response.statusCode}',
                            );
                            print('📥 DEBUG: Response data: ${response.data}');

                            final responseData = response.data;
                            if (response.statusCode == 200 &&
                                responseData['success'] == true) {
                              countdownTimer?.cancel();
                              cooldownTimer?.cancel();
                              if (mounted) Navigator.pop(ctx);

                              // Refresh tenant info to update verification status
                              await _loadDashboardData();

                              if (mounted) {
                                // OTP verification successful - no additional dialog needed
                              }
                            } else {
                              final message =
                                  responseData['message'] ??
                                  'Verification failed';
                              throw Exception(message);
                            }
                          } catch (e) {
                            print('❌ DEBUG: Error in OTP verification: $e');
                            final msg = e.toString();
                            final isLimit =
                                msg.contains('HTTP 429') ||
                                msg.toLowerCase().contains('429') ||
                                msg.toLowerCase().contains('limit');
                            if (isLimit) {
                              print(
                                '⚠️ DEBUG: Rate limit detected, showing message',
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
                      : Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading dashboard...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we fetch your data',
              style: TextStyle(color: AppColors.gray, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        _buildSummaryCards(),
        SizedBox(height: 16),
        if (_isAdsEnabled) _buildAdsBanner(),
        if (_isAdsEnabled) SizedBox(height: 16),
        _buildQuickActions(),
        SizedBox(height: 16),
        _buildRecentInvoices(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final summary = _dashboardData['summary'] ?? {};

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Invoices',
                  '${summary['total_invoices'] ?? 0}',
                  Icons.receipt_rounded,
                  AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Paid',
                  '${summary['paid_invoices'] ?? 0}',
                  Icons.check_circle_rounded,
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Pending',
                  '${summary['pending_invoices'] ?? 0}',
                  Icons.pending_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdsBanner() {
    print(
      '🔍 [Dashboard] Building ads banner - Enabled: $_isAdsEnabled, Data count: ${_adsData.length}',
    );

    // If ads are disabled, don't show anything
    if (!_isAdsEnabled) {
      print('🔍 [Dashboard] Ads disabled, hiding banner');
      return const SizedBox.shrink();
    }

    // If no ads data, don't show anything
    if (_adsData.isEmpty) {
      print('🔍 [Dashboard] No ads data, hiding banner');
      return const SizedBox.shrink();
    }

    print('🔍 [Dashboard] Showing ads banner with ${_adsData.length} ads');

    // Show ads section with dashboard's ads data
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 8, 5, 8),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ads',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildCustomAdsBanner(),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  // Custom ads banner using dashboard's ads data
  Widget _buildCustomAdsBanner() {
    if (_adsData.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 160,
      child: Column(
        children: [
          // Ads PageView
          Expanded(
            child: PageView.builder(
              controller: _adsPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentAdsPage = index;
                });
              },
              itemCount: _adsData.length,
              itemBuilder: (context, index) {
                final ad = _adsData[index];
                return GestureDetector(
                  onTap: () => _onAdTap(ad),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          // Ad Image
                          Image.network(
                            ad['image_url'] ?? '',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                          // Gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Sliding dots below the image
          if (_adsData.length > 1)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_adsData.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentAdsPage
                          ? Colors.blue
                          : Colors.grey.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // Handle ad tap
  void _onAdTap(Map<String, dynamic> ad) async {
    final url = ad['url'];
    final title = ad['title'] ?? 'Ad';

    if (url != null && url.toString().isNotEmpty) {
      try {
        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening: $title'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Record click for analytics (non-blocking)
        try {
          final adId = ad['id'];
          if (adId != null) {
            await ref.read(adsProvider.notifier).recordAdClick(adId);
            print('✅ Ad click recorded successfully: $title');
          }
        } catch (e) {
          print('⚠️ Failed to record ad click (non-critical): $e');
        }

        print('Ad clicked: $title - URL: $url');
      } catch (e) {
        print('Failed to handle ad click: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open ad: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'View Bills',
                  Icons.receipt_long_rounded,
                  Colors.blue,
                  () => context.go('/tenant/billing'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'My Profile',
                  Icons.person_rounded,
                  Colors.green,
                  () => context.go('/tenant/profile'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Contact Owner',
                  Icons.message_rounded,
                  Colors.orange,
                  () {
                    // Handle contact owner
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contact feature coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices() {
    final recentInvoices = _dashboardData['recent_invoices'] ?? [];

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Invoices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/tenant/billing'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
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
            child: recentInvoices.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: AppColors.gray.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No invoices found',
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your recent invoices will appear here',
                          style: TextStyle(
                            color: AppColors.gray.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: recentInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = recentInvoices[index];
                      return ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: invoice['status'] == 'paid'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: invoice['status'] == 'paid'
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            invoice['status'] == 'paid'
                                ? Icons.check_rounded
                                : Icons.pending_rounded,
                            color: invoice['status'] == 'paid'
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Invoice #${invoice['id']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          'Amount: \$${invoice['amount']}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: invoice['status'] == 'paid'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: invoice['status'] == 'paid'
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.orange.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            (invoice['status'] ?? 'Unknown').toUpperCase(),
                            style: TextStyle(
                              color: invoice['status'] == 'paid'
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        onTap: () {
                          // Navigate to PDF viewer using the same function as owner
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InvoicePdfScreen(
                                invoiceId: invoice['id'],
                                invoiceNumber:
                                    invoice['invoice_number'] ??
                                    'Invoice #${invoice['id']}',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Deprecated: _getTenantName was replaced by _getTenantFullName usage directly

  String _getTenantFullName() {
    print('_tenantInfo: $_tenantInfo'); // Debug: Print tenant info
    if (_tenantInfo != null) {
      final firstName = _tenantInfo!['first_name'] ?? '';
      final lastName = _tenantInfo!['last_name'] ?? '';
      final fullName = _tenantInfo!['name'] ?? '';

      print('firstName: $firstName'); // Debug: Print first name
      print('lastName: $lastName'); // Debug: Print last name
      print('fullName: $fullName'); // Debug: Print full name

      // If firstName exists, use it (even if lastName is empty)
      if (firstName.isNotEmpty) {
        if (lastName.isNotEmpty) {
          return '$firstName $lastName';
        } else {
          return firstName; // Return just firstName if lastName is empty
        }
      } else if (fullName.isNotEmpty) {
        return fullName;
      } else {
        return 'Tenant';
      }
    }
    return 'Tenant';
  }

  String _getTenantUnitInfo() {
    if (_tenantInfo != null) {
      final unitName = _tenantInfo!['unit_name'] ?? 'N/A';
      final propertyName = _tenantInfo!['property_name'] ?? 'N/A';
      return '$unitName • $propertyName';
    }
    return 'Unit • Property';
  }

  Widget _buildAttentionBanner({
    required Widget title,
    required Widget buttonLabel,
    VoidCallback? onPressed,
  }) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
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
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: title,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
      ),
    );
  }

  Widget _buildProgressBanner({
    required double percent,
    required VoidCallback onPressed,
  }) {
    final pct = (percent * 100).round();
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
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
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
                    '$pct% · Update your profile',
                    style: TextStyle(
                      color: Colors.black54,
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
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
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
                    Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      width: 45,
      height: 45,
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
                  size: 24,
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
                      size: 24,
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
          if (withoutStorage.startsWith('/profiles/') ||
              withoutStorage.startsWith('/tenants/')) {
            return '${origin()}/api/media$withoutStorage';
          }
          return '${origin()}$withoutStorage';
        }
        // If points to profiles/tenants, prefer media proxy
        if (p.startsWith('/profiles/') || p.startsWith('/tenants/')) {
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
      return (without.startsWith('/profiles/') ||
              without.startsWith('/tenants/'))
          ? '${origin()}/api/media$without'
          : '${origin()}$without';
    }
    if (pic.startsWith('/profiles/') || pic.startsWith('/tenants/')) {
      return '${origin()}/api/media$pic';
    }
    if (pic.startsWith('profiles/') || pic.startsWith('tenants/')) {
      return '${origin()}/api/media/$pic';
    }

    return '${origin()}/$pic';
  }
}
