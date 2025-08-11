import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:hrms_app/core/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hrms_app/core/services/api_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // FIXED: Pre-fill credentials for easier development
    _mobileController.text = 'owner@hrms.com';
    _passwordController.text = '123456';
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    final mobileOrEmail = _mobileController.text.trim();
    final password = _passwordController.text;
    if (mobileOrEmail.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref
                .read(languageProvider.notifier)
                .getString('please_fill_all_fields'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Attempting login...');
      final authRepository = ref.read(authRepositoryProvider);
      final data = await authRepository.login(mobileOrEmail, password);

      print('DEBUG: Login successful!');

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
        await AuthService.storeCredentials(mobileOrEmail, password);
        print('DEBUG: Credentials stored for auto-login');
      } else {
        await AuthService.clearStoredCredentials();
        print('DEBUG: Credentials cleared');
      }

      // Extract user data from response
      final userData = data['user'] ?? {};

      await ref
          .read(authStateProvider.notifier)
          .login(data['token'], data['role'], userData: userData);

      final authState = ref.read(authStateProvider);
      print(
        'DEBUG: Auth state after login - isAuthenticated: ${authState.isAuthenticated}, role: ${authState.user?.role}',
      );

      // Let router handle the navigation automatically based on auth state
      // No need to manually navigate - router will redirect based on role
      print('DEBUG: Login complete, letting router handle navigation...');

      // Let router handle the navigation automatically based on auth state
      // No need for delay, router will react to authState change
      print('DEBUG: Login complete, letting router handle navigation...');
    } catch (e) {
      print('DEBUG: Exception in login: $e');

      String errorMessage = ref
          .read(languageProvider.notifier)
          .getString('login_failed');

      // Parse error message based on exception type
      if (e.toString().contains('HTTP 403')) {
        errorMessage = ref
            .read(languageProvider.notifier)
            .getString('invalid_credentials');
      } else if (e.toString().contains('HTTP 401')) {
        errorMessage = ref
            .read(languageProvider.notifier)
            .getString('invalid_credentials');
      } else if (e.toString().contains('HTTP 422')) {
        errorMessage = ref
            .read(languageProvider.notifier)
            .getString('invalid_input_format');
      } else if (e.toString().contains('HTTP 500')) {
        errorMessage = ref
            .read(languageProvider.notifier)
            .getString('server_error');
      } else if (e.toString().contains('No internet connection')) {
        errorMessage = ref
            .read(languageProvider.notifier)
            .getString('no_internet_connection');
      } else if (e.toString().contains('Connection timeout')) {
        errorMessage = ref
            .read(languageProvider.notifier)
            .getString('connection_timeout');
      } else if (e.toString().contains('Server error')) {
        errorMessage = ref
            .read(languageProvider.notifier)
            .getString('server_error');
      } else {
        errorMessage = ref
            .read(languageProvider.notifier)
            .getString('login_failed_try_again');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageNotifier = ref.watch(languageProvider.notifier);
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Gradient Header with Wave
                Stack(
                  children: [
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    ClipPath(
                      clipper: WaveClipper(),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(color: AppColors.background),
                      ),
                    ),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 40),
                          Icon(
                            Icons.apartment,
                            size: 60,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "HRMS",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  languageNotifier.getString('welcome_back'),
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                // Email Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: languageNotifier.getString('email_phone'),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.inputBorder),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Password Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: languageNotifier.getString('password'),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.inputBorder),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Remember me & Forgot password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _rememberMe = val!;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          languageNotifier.getString('remember_me'),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/forgot-password');
                        },
                        child: Text(
                          languageNotifier.getString('forgot_password'),
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Login Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              languageNotifier.getString('login'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
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
                ),
                SizedBox(height: 16),
                // Google Login Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isGoogleLoading)
                            SizedBox(
                              width: 22,
                              height: 22,
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
                              height: 22,
                              width: 22,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                languageNotifier.getString(
                                  'continue_with_google',
                                ),
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
                ),
                SizedBox(height: 16),
                // --- CREATE ACCOUNT SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    languageNotifier.getString('dont_have_account'),
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Create Account Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/signup');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      icon: Icon(
                        Icons.person_add_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      label: Text(
                        languageNotifier.getString('create_account'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          // Language Button - Upper Right Corner
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Container(
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
          ),
        ],
      ),
    );
  }

  // Social Login Methods
  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      print('Starting Google Sign-In from LoginScreen...');
      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return; // cancelled
      }

      final auth = await googleUser.authentication;
      if (auth.idToken == null) {
        debugPrint(
          'WARNING: Google idToken is null; proceeding with profile info only',
        );
      }

      final String name = googleUser.displayName ?? 'Google User';
      final String email = googleUser.email;
      final String? photoUrl = googleUser.photoUrl != null
          ? (googleUser.photoUrl!.contains('googleusercontent')
                ? '${googleUser.photoUrl!}?sz=200'
                : googleUser.photoUrl)
          : null;
      print('Google Sign-In Success (LoginScreen): name=$name email=$email');

      await _checkGoogleAndNavigate(email, name, profilePic: photoUrl);
    } catch (e) {
      print('Google Sign-In Error (LoginScreen): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
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
      final response = await _checkGoogleRole(email);
      if (response['success'] == true) {
        final role = response['role'];
        final userData = response['user_data'];
        if (role != null) {
          final token =
              (response['token'] ??
                      userData?['token'] ??
                      userData?['api_token'] ??
                      'GOOGLE_TEMP_TOKEN')
                  .toString();
          final normalizedUser = {
            'name': userData?['name'] ?? name,
            'email': userData?['email'] ?? email,
            'role': role,
          };
          await ref
              .read(authStateProvider.notifier)
              .login(token, role, userData: normalizedUser);
          await AuthService.saveToken(token);
          if (mounted) {
            context.go('/dashboard');
          }
        } else {
          // Not found → go to mobile entry for smart registration
          if (mounted) {
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
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to check account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _checkGoogleRole(String email) async {
    try {
      final api = ref.read(apiServiceProvider);
      print('DEBUG(Login): Checking google email in backend: $email');
      final response = await api.post(
        '/check-google-role',
        data: {'email': email},
      );
      final data = response.data as Map<String, dynamic>;
      print('DEBUG(Login): Google role API response: $data');
      return {
        'success': data['success'] == true,
        'role': data['role'],
        'message': data['message'] ?? 'OK',
        'user_data': data['user_data'],
        'token': data['token'],
      };
    } catch (e) {
      print('DEBUG(Login): Error in _checkGoogleRole: $e');
      return {'success': false, 'message': 'Failed to check email: $e'};
    }
  }

  Widget _socialIcon(IconData icon, Color color) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
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

// Custom Wave Clipper
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
