import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  Map<String, dynamic> _userData = {};
  final _formKey = GlobalKey<FormState>();
  String? _otp;
  bool _shouldRefresh = false;
  late FocusNode _focusNode;

  double _computeProfileCompletion() {
    // 100% only if all required and verification/photo done
    final name = (_userData['name'] ?? '').toString().trim();
    final firstName = (_userData['first_name'] ?? '').toString().trim();
    final lastName = (_userData['last_name'] ?? '').toString().trim();
    final email = (_userData['email'] ?? '').toString().trim();
    final phone = (_userData['mobile'] ?? _userData['phone'] ?? '')
        .toString()
        .trim();
    final country = (_userData['country'] ?? '').toString().trim();
    final district = (_userData['district'] ?? '').toString().trim();
    final address = (_userData['address'] ?? '').toString().trim();
    final gender = (_userData['gender'] ?? '').toString().trim();
    final profilePic = (_userData['profile_pic'] ?? '').toString().trim();
    final emailVerified = _isEmailVerified();
    final phoneVerified = (_userData['phone_verified'] == true);

    int filled = 0;
    int total =
        10; // name, phone, district, email, country, address, gender, profile_pic, emailVerified, phoneVerified

    final hasName =
        (name.isNotEmpty) || (firstName.isNotEmpty || lastName.isNotEmpty);
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

  bool _isEmailVerified() {
    // Try to infer from common fields if backend provides them
    final ev = _userData['email_verified'] == true;
    final eva = (_userData['email_verified_at'] ?? '')
        .toString()
        .trim()
        .isNotEmpty;
    return ev || eva;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should refresh (e.g., coming back from edit screen)
    if (_shouldRefresh) {
      _shouldRefresh = false;
      _loadUserData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app becomes visible (e.g., returning from background)
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
    }
  }

  // Method to trigger refresh from external sources
  void refreshProfile() {
    setState(() {
      _shouldRefresh = true;
    });
  }

  // Method to handle when screen becomes visible
  void _onScreenVisible() {
    // Refresh data when screen becomes visible
    _loadUserData();
  }

  // Method to handle when navigating back to this screen
  void _onScreenResume() {
    // Refresh data when screen resumes
    _loadUserData();
  }

  // Method to handle focus changes
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Screen gained focus, refresh data
      _loadUserData();
    }
  }

  String _normalizePic(String raw) {
    final pic = raw.trim();
    if (pic.isEmpty) return '';

    String origin() {
      final base = ApiConfig.getBaseUrl();
      return base.replaceFirst(RegExp(r'/api/?$'), '');
    }

    if (pic.startsWith('http://') || pic.startsWith('https://')) {
      try {
        final uri = Uri.parse(pic);
        final p = uri.path;
        if (p.startsWith('/storage/')) {
          final withoutStorage = p.replaceFirst('/storage/', '/');
          if (withoutStorage.startsWith('/profiles/')) {
            return '${origin()}/api/media$withoutStorage';
          }
          return '${origin()}$withoutStorage';
        }
        if (p.startsWith('/profiles/')) {
          return '${origin()}/api/media$p';
        }
        return pic;
      } catch (_) {
        return pic;
      }
    }

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

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('DEBUG: Loading user data...');

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/user')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userData = data['user'] ?? data;
          _isLoading = false;
        });

        // Clear image cache to ensure new profile pictures are displayed
        _clearImageCache();
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print('DEBUG: Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Clear image cache to ensure new profile pictures are displayed
  void _clearImageCache() {
    try {
      // Clear the specific profile picture from cache
      final raw = (_userData['profile_pic'] ?? '').toString().trim();
      if (raw.isNotEmpty) {
        final url = _normalizePic(raw);
        if (url.isNotEmpty) {
          // Add cache-busting query parameter
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final hasQuery = url.contains('?');
          final cacheBustedUrl = hasQuery
              ? '$url&v=$timestamp'
              : '$url?v=$timestamp';

          // Update the user data with cache-busted URL
          setState(() {
            _userData['profile_pic'] = cacheBustedUrl;
          });
        }
      }
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              // Navigate to edit profile using GoRouter
              final result = await context.push('/profile/edit');
              if (result == true) {
                // Profile was updated, refresh the data
                _loadUserData();
              }
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: Focus(
                focusNode: _focusNode,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Builder(
                                builder: (context) {
                                  final raw = (_userData['profile_pic'] ?? '')
                                      .toString()
                                      .trim();
                                  final url = _normalizePic(raw);
                                  if (url.isNotEmpty) {
                                    return ClipOval(
                                      child: Image.network(
                                        url,
                                        headers: const {
                                          'Cache-Control': 'no-cache',
                                        },
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => CircleAvatar(
                                          radius: 50,
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.2),
                                          child: Icon(
                                            Icons.person,
                                            size: 50,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.2),
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 16),
                              Text(
                                (() {
                                  final first = (_userData['first_name'] ?? '')
                                      .toString();
                                  final last = (_userData['last_name'] ?? '')
                                      .toString();
                                  final full = ('$first $last').trim();
                                  if (full.isNotEmpty) return full;
                                  return (_userData['name'] ?? 'Your Name')
                                      .toString();
                                })(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _userData['email'] ?? 'No email',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 16),
                              // Profile completion bar
                              Builder(
                                builder: (context) {
                                  final p = _computeProfileCompletion();
                                  final percentText =
                                      '${(p * 100).round()}% Complete';
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Profile Completion',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            percentText,
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: p,
                                          minHeight: 8,
                                          backgroundColor: Colors.grey
                                              .withOpacity(0.2),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              SizedBox(height: 12),
                              // Verification chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildVerificationChip(
                                    label: 'Mobile',
                                    isVerified:
                                        (_userData['phone_verified'] == true),
                                  ),
                                  _buildVerificationChip(
                                    label: 'Email',
                                    isVerified: _isEmailVerified(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Profile Details
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildInfoRow(
                                'Full Name',
                                '${_userData['first_name'] ?? ''} ${_userData['last_name'] ?? ''}',
                              ),
                              _buildInfoRow(
                                'Email',
                                _userData['email'] ?? 'Not provided',
                              ),
                              _buildInfoRow(
                                'Phone',
                                (() {
                                  final m = (_userData['mobile'] ?? '')
                                      .toString();
                                  final p = (_userData['phone'] ?? '')
                                      .toString();
                                  final v = m.isNotEmpty ? m : p;
                                  return v.isEmpty ? 'Not provided' : v;
                                })(),
                              ),
                              _buildInfoRow(
                                'Country',
                                _userData['country'] ?? 'Not provided',
                              ),
                              _buildInfoRow(
                                'Address',
                                _userData['address'] ?? 'Not provided',
                              ),
                              _buildInfoRow(
                                'District',
                                (() {
                                  final d = (_userData['district'] ?? '')
                                      .toString();
                                  return d.isEmpty ? 'Not provided' : d;
                                })(),
                              ),
                              _buildInfoRow(
                                'Gender',
                                _userData['gender'] ?? 'Not provided',
                              ),
                              _buildInfoRow(
                                'Role',
                                _userData['role'] ?? 'Owner',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Account Actions
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Actions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 16),
                              ListTile(
                                leading: Icon(
                                  Icons.edit,
                                  color: AppColors.primary,
                                ),
                                title: Text('Edit Profile'),
                                subtitle: Text(
                                  'Update your personal information',
                                ),
                                onTap: () async {
                                  // Navigate to edit profile using GoRouter
                                  final result = await context.push(
                                    '/profile/edit',
                                  );
                                  if (result == true) {
                                    // Profile was updated, refresh the data
                                    _loadUserData();
                                  }
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.lock,
                                  color: AppColors.warning,
                                ),
                                title: Text('Change Password'),
                                subtitle: Text('Update your password'),
                                onTap: () {
                                  _showChangePasswordDialog();
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.logout,
                                  color: AppColors.error,
                                ),
                                title: Text('Logout'),
                                subtitle: Text('Sign out of your account'),
                                onTap: () async {
                                  await AuthService.clearToken();
                                  context.go('/login');
                                },
                              ),
                            ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement password change
              Navigator.pop(context);
            },
            child: Text('Change Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChip({
    required String label,
    required bool isVerified,
  }) {
    return Chip(
      avatar: Icon(
        isVerified ? Icons.verified : Icons.error_outline,
        color: isVerified ? Colors.white : Colors.white,
        size: 16,
      ),
      label: Text(
        isVerified ? '$label Verified' : '$label Unverified',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isVerified ? Colors.green : Colors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
