import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hrms_app/core/services/analytics_service.dart';

class OwnerRegistrationScreen extends ConsumerStatefulWidget {
  final String? initialMobile;
  final String? initialEmail;
  final String? initialName;

  const OwnerRegistrationScreen({
    super.key,
    this.initialMobile,
    this.initialEmail,
    this.initialName,
  });

  @override
  _OwnerRegistrationScreenState createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState
    extends ConsumerState<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedDistrict;
  List<String> _districtOptions = [];
  bool _isLoadingDistricts = false;
  String? _districtLoadError;
  String? _selectedCountry = 'Bangladesh';
  static const List<String> _countries = [
    'Bangladesh',
    'India',
    'Pakistan',
    'Nepal',
    'Sri Lanka',
  ];

  // Bangladesh Districts (64)
  static const List<String> _bdDistricts = [
    'Bagerhat',
    'Bandarban',
    'Barguna',
    'Barishal',
    'Bhola',
    'Bogura',
    'Brahmanbaria',
    'Chandpur',
    'Chattogram',
    "Chapai Nawabganj",
    'Chuadanga',
    "Cox's Bazar",
    'Cumilla',
    'Dhaka',
    'Dinajpur',
    'Faridpur',
    'Feni',
    'Gaibandha',
    'Gazipur',
    'Gopalganj',
    'Habiganj',
    'Jamalpur',
    'Jashore',
    'Jhalokathi',
    'Jhenaidah',
    'Joypurhat',
    'Khagrachhari',
    'Khulna',
    'Kishoreganj',
    'Kurigram',
    'Kushtia',
    'Lakshmipur',
    'Lalmonirhat',
    'Madaripur',
    'Magura',
    'Manikganj',
    'Meherpur',
    'Moulvibazar',
    'Munshiganj',
    'Mymensingh',
    'Naogaon',
    'Narail',
    'Narayanganj',
    'Narsingdi',
    'Natore',
    'Netrokona',
    'Nilphamari',
    'Noakhali',
    'Pabna',
    'Panchagarh',
    'Patuakhali',
    'Pirojpur',
    'Rajbari',
    'Rajshahi',
    'Rangamati',
    'Rangpur',
    'Satkhira',
    'Shariatpur',
    'Sherpur',
    'Sirajganj',
    'Sunamganj',
    'Sylhet',
    'Tangail',
    'Thakurgaon',
  ];

  @override
  void initState() {
    super.initState();
    // Set initial values if provided
    if (widget.initialMobile != null && widget.initialMobile!.isNotEmpty) {
      _mobileController.text = widget.initialMobile!;
    }
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }

    // Try to load districts from backend; fallback to static list on failure
    _fetchDistricts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _fetchDistricts() async {
    setState(() {
      _isLoadingDistricts = true;
      _districtLoadError = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/districts');
      final data = response.data;
      List<String> names = [];
      if (data is List) {
        // Expecting array of strings or objects with name
        for (final item in data) {
          if (item is String) {
            names.add(item);
          } else if (item is Map && item['name'] is String) {
            names.add(item['name'] as String);
          }
        }
      } else if (data is Map && data['data'] is List) {
        for (final item in (data['data'] as List)) {
          if (item is String) {
            names.add(item);
          } else if (item is Map && item['name'] is String) {
            names.add(item['name'] as String);
          }
        }
      }
      names = names.toSet().toList()..sort();
      setState(() {
        _districtOptions = names.isNotEmpty ? names : _bdDistricts;
      });
    } catch (e) {
      setState(() {
        _districtLoadError = 'Failed to load districts from server';
        _districtOptions = _bdDistricts; // fallback
      });
    } finally {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Prepare registration data
      // Normalize BD Mobile
      String digitsOnly(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');
      String mobile = _mobileController.text.trim();
      String msisdn = digitsOnly(mobile);
      if (msisdn.startsWith('0088')) {
        msisdn = msisdn.substring(4);
      } else if (msisdn.startsWith('88')) {
        msisdn = msisdn.substring(2);
      }
      if (msisdn.length == 10 && msisdn.startsWith('1')) {
        msisdn = '0$msisdn';
      }

      final registrationData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'phone': msisdn,
        'district': _selectedDistrict,
        'country': _selectedCountry ?? 'Bangladesh',
        'password': _passwordController.text,
        'password_confirmation': _passwordConfirmController.text,
      };

      try {
        // Get API service and auth repository
        final apiService = ref.read(apiServiceProvider);
        final authRepository = AuthRepository(apiService);

        print('🔥 Starting owner registration...');
        print('🔥 Registration data: $registrationData');

        // Call actual API
        final response = await authRepository.registerOwner(registrationData);

        print('✅ Registration API response: $response');

        // Extract token and user data from response
        final token = response['token'];
        final userData = response['user'] ?? response['owner'];

        // Determine user role from response or default to owner
        String userRole = 'owner'; // Default for owner registration
        if (userData != null && userData['role'] != null) {
          userRole = userData['role'];
        }

        print('🔑 Token received: $token');
        print('👤 User data: $userData');
        print('🎭 User role: $userRole');

        if (token != null) {
          // Update the auth state with actual token, role, and user data
          await ref
              .read(authStateProvider.notifier)
              .login(token, userRole, userData: userData);

          // Track owner registration analytics
          try {
            final userId =
                userData?['id']?.toString() ?? 'owner_${msisdn.hashCode}';
            final email = _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim();
            await AnalyticsService.trackUserRegistration(
              userId: userId,
              email: email,
              registrationMethod: 'email_signup',
              userProfile: {
                'name': _nameController.text.trim(),
                'phone': msisdn,
                'district': _selectedDistrict,
                'country': _selectedCountry ?? 'Bangladesh',
                'role': userRole,
              },
            );
            print('DEBUG: Owner registration analytics tracked successfully');
          } catch (analyticsError) {
            print(
              'DEBUG: Failed to track owner registration analytics: $analyticsError',
            );
            // Don't block registration flow if analytics fails
          }

          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! Welcome!'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate based on role - let the router handle role-based redirect
            // The router will automatically redirect to the appropriate dashboard
            print('🚀 Navigating to role-based dashboard...');
            context.go('/dashboard'); // Router will redirect based on role
          }
        } else {
          throw Exception('No token received from server');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        print('❌ Registration failed: $e');

        if (mounted) {
          String errorMessage = 'Registration failed';

          // Parse specific error messages
          String errorString = e.toString();
          if (errorString.contains('HTTP 422:')) {
            // Validation error
            errorMessage = errorString.split('HTTP 422:')[1].trim();
          } else if (errorString.contains('HTTP 409:')) {
            // Conflict error (duplicate)
            errorMessage = 'Email or phone number already exists';
          } else if (errorString.contains('No internet connection')) {
            errorMessage = 'No internet connection. Please check your network.';
          } else if (errorString.contains('Connection timeout')) {
            errorMessage = 'Connection timeout. Please try again.';
          } else if (errorString.contains('Registration error:')) {
            errorMessage = errorString.split('Registration error:')[1].trim();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
        title: Text('Owner Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Header
              Text(
                'Create Owner Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),
              Text(
                'Provide minimal details to create your account',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length > 255) {
                    return 'Name cannot exceed 255 characters';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email Field (Optional)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address (Optional)',
                  prefixIcon: Icon(Icons.email, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  // Email is now optional
                  if (value == null || value.isEmpty) {
                    return null; // Allow empty email
                  }
                  // Basic email validation only if provided
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  if (value.length > 255) {
                    return 'Email cannot exceed 255 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Mobile Field (BD Validation)
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '01XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
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
                    return 'Enter a valid BD number (11 digits starting with 01)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // District (Bangladesh) with search
              DropdownSearch<String>(
                items: _districtOptions.isNotEmpty
                    ? _districtOptions
                    : _bdDistricts,
                selectedItem: _selectedDistrict,
                onChanged: (value) {
                  setState(() => _selectedDistrict = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your district';
                  }
                  return null;
                },
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'District (Bangladesh)',
                    prefixIcon: Icon(
                      Icons.location_city,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search district',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  containerBuilder: (ctx, popupWidget) {
                    if (_isLoadingDistricts) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return popupWidget;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Country Dropdown (Bangladesh auto selected)
              DropdownButtonFormField<String>(
                initialValue: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'Country',
                  prefixIcon: Icon(Icons.public, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCountry = value);
                },
              ),

              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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

              const SizedBox(height: 16),

              // Password Confirmation Field
              TextFormField(
                controller: _passwordConfirmController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
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

              const SizedBox(height: 32),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

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
                      context.pushReplacement('/login');
                    },
                    child: const Text(
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
