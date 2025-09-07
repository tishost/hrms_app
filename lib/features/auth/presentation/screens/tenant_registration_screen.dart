import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/services/analytics_service.dart';

class TenantRegistrationScreen extends ConsumerStatefulWidget {
  final String? mobile;
  final String? email;

  const TenantRegistrationScreen({super.key, this.mobile, this.email});

  @override
  _TenantRegistrationScreenState createState() =>
      _TenantRegistrationScreenState();
}

class _TenantRegistrationScreenState
    extends ConsumerState<TenantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _unitNameController = TextEditingController();
  final _propertyNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingTenantInfo = false;
  Map<String, dynamic>? _tenantInfo;

  @override
  void initState() {
    super.initState();
    print('DEBUG: TenantRegistrationScreen initState called');
    print('DEBUG: Widget mobile: ${widget.mobile}');
    print('DEBUG: Widget email: ${widget.email}');

    // Pre-fill mobile number if provided
    if (widget.mobile != null && widget.mobile!.isNotEmpty) {
      print('DEBUG: Setting mobile controller to: ${widget.mobile}');
      _mobileController.text = widget.mobile!;
      // Fetch tenant information from database
      print('DEBUG: Calling _fetchTenantInfo with mobile: ${widget.mobile}');
      _fetchTenantInfo(widget.mobile!);
    } else {
      print('DEBUG: No mobile number provided');
    }

    // Pre-fill email if provided
    if (widget.email != null && widget.email!.isNotEmpty) {
      print('DEBUG: Setting email controller to: ${widget.email}');
      _emailController.text = widget.email!;
    } else {
      print('DEBUG: No email provided');
    }

    print('DEBUG: initState completed');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _unitNameController.dispose();
    _propertyNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchTenantInfo(String mobile) async {
    print('DEBUG: _fetchTenantInfo called with mobile: $mobile');
    setState(() {
      _isLoadingTenantInfo = true;
    });

    try {
      // Call backend API to get tenant information
      final api = ref.read(apiServiceProvider);
      print('DEBUG: API service provider read successfully');
      print('DEBUG: Calling backend API: /check-mobile-role');

      final response = await api.post(
        '/check-mobile-role',
        data: {'mobile': mobile},
      );

      print('DEBUG: API response received: ${response.statusCode}');
      final data = response.data as Map<String, dynamic>;
      print('DEBUG: Tenant info API response: $data');
      print('DEBUG: Response success: ${data['success']}');
      print('DEBUG: Response role: ${data['role']}');

      if (data['success'] == true && data['role'] == 'tenant') {
        print('DEBUG: Tenant role confirmed, setting tenant info');
        setState(() {
          _tenantInfo = data['user_data'];
        });

        // Auto-fill form fields with tenant information
        if (_tenantInfo != null) {
          print('DEBUG: Auto-filling form fields');
          _nameController.text = _tenantInfo!['name'] ?? '';
          _emailController.text = _tenantInfo!['email'] ?? '';
          _unitNameController.text = _tenantInfo!['unit_name'] ?? '';
          _propertyNameController.text = _tenantInfo!['property_name'] ?? '';
          print('DEBUG: Name controller set to: ${_nameController.text}');
          print('DEBUG: Email controller set to: ${_emailController.text}');
          print('DEBUG: Unit controller set to: ${_unitNameController.text}');
          print(
            'DEBUG: Property controller set to: ${_propertyNameController.text}',
          );
        }

        print('DEBUG: Tenant info loaded: $_tenantInfo');
      } else {
        print('DEBUG: API response indicates not tenant or failed');
      }
    } catch (e) {
      print('DEBUG: Error fetching tenant info: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      print('DEBUG: Falling back to mock data for testing');

      // Fallback to mock data for testing
      if (mobile == '01718262531' || mobile == '01718262540') {
        print('DEBUG: Using mock data for mobile: $mobile');
        setState(() {
          _tenantInfo = {
            'name': 'Demo Tenant',
            'email': 'tenant@demo.com',
            'mobile': mobile,
            'unit_name': 'Demo Unit',
            'property_name': 'Demo Property',
          };
        });

        // Auto-fill form fields
        print('DEBUG: Auto-filling form fields with mock data');
        _nameController.text = _tenantInfo!['name'] ?? '';
        _emailController.text = _tenantInfo!['email'] ?? '';
        _unitNameController.text = _tenantInfo!['unit_name'] ?? '';
        _propertyNameController.text = _tenantInfo!['property_name'] ?? '';
        print('DEBUG: Mock data - Name: ${_nameController.text}');
        print('DEBUG: Mock data - Unit: ${_unitNameController.text}');
        print('DEBUG: Mock data - Property: ${_propertyNameController.text}');
      }
    } finally {
      setState(() {
        _isLoadingTenantInfo = false;
      });
      print('DEBUG: _fetchTenantInfo completed');
    }
  }

  Future<void> _handleRegistration() async {
    // OTP verification is now optional based on backend settings
    // The backend will handle OTP requirement check

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('DEBUG: Starting tenant registration process');
        print('DEBUG: Mobile: ${_mobileController.text}');
        print('DEBUG: Password: ${_passwordController.text}');

        // Call backend API to register tenant
        final api = ref.read(apiServiceProvider);
        final response = await api.post(
          '/tenant/register',
          data: {
            'mobile': _mobileController.text,
            'password': _passwordController.text,
            'password_confirmation': _passwordController.text,
          },
        );

        print('DEBUG: Registration API response: ${response.statusCode}');
        final data = response.data as Map<String, dynamic>;
        print('DEBUG: Registration response data: $data');

        if (data['success'] == true) {
          print('DEBUG: Registration successful, navigating to dashboard');

          // Track tenant registration analytics
          try {
            final userId =
                data['user']?['id']?.toString() ??
                'tenant_${_mobileController.text.hashCode}';
            final email = widget.email;
            await AnalyticsService.trackUserRegistration(
              userId: userId,
              email: email,
              registrationMethod: 'mobile_signup',
              userProfile: {
                'mobile': _mobileController.text,
                'role': 'tenant',
                'tenant_info': _tenantInfo,
              },
            );
            print('DEBUG: Tenant registration analytics tracked successfully');
          } catch (analyticsError) {
            print(
              'DEBUG: Failed to track tenant registration analytics: $analyticsError',
            );
            // Don't block registration flow if analytics fails
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to tenant dashboard
          context.go('/tenant-dashboard');
        } else {
          print('DEBUG: Registration failed: ${data['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('DEBUG: Registration error: $e');
        print('DEBUG: Error type: ${e.runtimeType}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Tenant Registration'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),

              // Header
              Text(
                'Create Tenant Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Loading indicator for tenant info
              if (_isLoadingTenantInfo)
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
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
                        'Loading tenant information...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 8),
              Text(
                'Fill in your details to create your account',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Name Field (Read-only)
              TextFormField(
                controller: _nameController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              SizedBox(height: 16),

              // Property Name Field (Read-only)
              TextFormField(
                controller: _propertyNameController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Property Name',
                  prefixIcon: Icon(Icons.business, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              SizedBox(height: 16),

              // Unit Name Field (Read-only)
              TextFormField(
                controller: _unitNameController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Unit Name',
                  prefixIcon: Icon(Icons.home, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              SizedBox(height: 16),

              // Email Field (Read-only)
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              SizedBox(height: 16),

              // Mobile Field (Read-only)
              TextFormField(
                controller: _mobileController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              SizedBox(height: 16),

              // OTP Section removed - Tenant registration now works without OTP verification

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              SizedBox(height: 32),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
              ),

              SizedBox(height: 16),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text(
                      'Login',
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
      ),
    );
  }
}
