import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/auth/data/services/global_otp_settings.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
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
          content: Text('Please fill in all fields'),
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

      await ref
          .read(authStateProvider.notifier)
          .login(data['token'], data['role']);

      final authState = ref.read(authStateProvider);
      print(
        'DEBUG: Auth state after login - isAuthenticated: ${authState.isAuthenticated}, role: ${authState.user?.role}',
      );

      final role = data['role'];
      if (role == 'owner') {
        print('DEBUG: Navigating to owner dashboard');
        context.go('/dashboard');
      } else if (role == 'tenant') {
        print('DEBUG: Navigating to tenant dashboard');
        context.go('/tenant-dashboard');
      } else {
        print('DEBUG: Unknown role: $role');
        throw Exception('Unknown role: $role');
      }
    } catch (e) {
      print('DEBUG: Exception in login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
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
    // FIXED: Removed AppBar and extra Padding to eliminate white space at the top.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
                // This Positioned widget now correctly sits at the top of the screen.
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Icon(Icons.apartment, size: 60, color: AppColors.primary),
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
            SizedBox(height: 30),
            Text(
              "Welcome back !",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            // Email Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                controller: _mobileController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email/Phone",
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
            SizedBox(height: 16),
            // Password Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password",
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
            SizedBox(height: 10),
            // Remember me & Forgot password
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  Text(
                    "Remember me",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Login Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 24),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
            SizedBox(height: 24),

            // --- REDESIGNED REGISTRATION SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "Don't have an account?",
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                children: [
                  // Tenant Registration Card
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/tenant-registration');
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        height: 140,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              color: Colors.blue,
                              size: 36,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "I'm a Tenant",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Owner Registration Card
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/owner-registration');
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        height: 140,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_center_outlined,
                              color: AppColors.primary,
                              size: 36,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "I'm an Owner",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
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
