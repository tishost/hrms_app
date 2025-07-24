import 'package:flutter/material.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/auth/data/services/global_otp_settings.dart';
import 'package:hrms_app/features/auth/presentation/screens/login_screen.dart';
import 'package:hrms_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:hrms_app/core/utils/country_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class OwnerRegistrationScreen extends StatefulWidget {
  final String verifiedPhone;

  const OwnerRegistrationScreen({super.key, required this.verifiedPhone});

  @override
  State<OwnerRegistrationScreen> createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isOtpEnabled = true; // Add OTP status

  String? _selectedCountry;
  List<String> _countries = [];
  String _selectedGender = ''; // Add gender field

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _checkOtpStatus();

    // Set phone from verified phone if available
    if (widget.verifiedPhone.isNotEmpty) {
      _phoneController.text = widget.verifiedPhone;
    }

    // Listen for OTP settings changes
    _setupOtpSettingsListener();
  }

  void _setupOtpSettingsListener() {
    // Refresh OTP status every 30 seconds
    Timer.periodic(Duration(seconds: 30), (timer) async {
      if (mounted) {
        await _checkOtpStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkOtpStatus() async {
    try {
      bool isOtpRequired = GlobalOtpSettings.isOtpRequiredFor('registration');
      setState(() {
        _isOtpEnabled = isOtpRequired;
      });
    } catch (e) {
      print('Error checking OTP status: $e');
      setState(() {
        _isOtpEnabled = true; // Default to enabled
      });
    }
  }

  Future<void> _loadCountries() async {
    try {
      _countries = CountryHelper.getCountries();
      setState(() {});
    } catch (e) {
      print('Error loading countries: $e');
      // Fallback to default countries
      _countries = [
        'Bangladesh',
        'India',
        'Pakistan',
        'Nepal',
        'Sri Lanka',
        'Other',
      ];
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Remove status bar restoration
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            // Simple back navigation
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          _isOtpEnabled ? 'Complete Registration' : 'Registration',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 4),
                    Center(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.border,
                        child: Icon(
                          Icons.apartment,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isOtpEnabled
                          ? 'Complete Your Profile'
                          : 'Create Your Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isOtpEnabled
                          ? 'Phone ${widget.verifiedPhone} verified successfully'
                          : 'Quick registration without phone verification',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isOtpEnabled
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    _buildTextField(
                      _nameController,
                      'Full Name *',
                      Icons.person,
                      false,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      _emailController,
                      'Email Address *',
                      Icons.email,
                      false,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    _buildPhoneField(),
                    SizedBox(height: 16),
                    _buildTextField(
                      _addressController,
                      'Address (optional)',
                      Icons.location_on,
                      false,
                    ),
                    SizedBox(height: 16),
                    _buildCountryDropdown(),
                    SizedBox(height: 16),
                    _buildGenderField(),
                    SizedBox(height: 16),
                    _buildTextField(
                      _passwordController,
                      'Password *',
                      Icons.lock,
                      _obscurePassword,
                      isPassword: true,
                      onToggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      _confirmPasswordController,
                      'Confirm Password *',
                      Icons.lock_outline,
                      _obscureConfirmPassword,
                      isPassword: true,
                      onToggle: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleRegistration,
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
                              _isOtpEnabled
                                  ? 'Complete Registration'
                                  : 'Create Account',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      enabled:
          !_isOtpEnabled ||
          widget
              .verifiedPhone
              .isEmpty, // Enable if OTP not required or no verified phone
      style: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: _isOtpEnabled ? 'Phone Number *' : 'Phone Number *',
        border: OutlineInputBorder(),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        prefixIcon: Icon(Icons.phone, color: AppColors.hint, size: 22),
        suffixIcon: widget.verifiedPhone.isNotEmpty
            ? Icon(Icons.verified, color: AppColors.success, size: 20)
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        if (value.length < 8) {
          return 'Enter a valid phone number';
        }
        return null;
      },
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String phone = widget.verifiedPhone;
      String otp = '';

      // If phone is empty (OTP not required), use the phone from form
      if (phone.isEmpty) {
        phone = _phoneController.text.trim();
        otp = '000000'; // Default OTP when verification is not required
        print('OTP not required, using default OTP: $otp');
      } else {
        // OTP is required, send OTP and get it
        print('OTP required, sending OTP for phone: $phone');

        // Check if OTP is still required (in case settings changed)
        bool isOtpRequired = GlobalOtpSettings.isOtpRequiredFor('registration');
        if (!isOtpRequired) {
          otp = '000000'; // Use default OTP if settings changed
          print('OTP settings changed, using default OTP: $otp');
        } else {
          final otpResponse = await AuthService.sendOtp(phone, 'registration');
          otp = otpResponse['otp'] as String;
        }
      }

      await AuthService.registerOwner(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: phone,
        address: _addressController.text.trim().isEmpty
            ? 'N/A'
            : _addressController.text.trim(),
        country: _selectedCountry ?? 'N/A',
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        otp: otp,
        gender: _selectedGender.isEmpty ? 'N/A' : _selectedGender,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Redirecting to login...'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Set first time flag to false (app is no longer first time)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_time', false);
      print('First time flag set to false');

      // Wait for 2 seconds to show the success message
      await Future.delayed(Duration(seconds: 2));

      // Navigate to login screen and clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false, // This removes all previous routes
      );
    } catch (e) {
      print('Registration error: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool obscure, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: Icon(icon, color: AppColors.hint, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.hint,
                  size: 22,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
      onChanged: (_) {
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      },
      validator: (value) {
        if (hint == 'Full Name *' && (value == null || value.isEmpty)) {
          return 'Please enter full name';
        }
        if (hint == 'Email Address *' && (value == null || value.isEmpty)) {
          return 'Please enter email address';
        }
        if (hint == 'Email Address *' &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!)) {
          return 'Enter a valid email';
        }
        if (hint == 'Confirm Password *' && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildCountryDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Country (optional)',
        border: OutlineInputBorder(),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      child: InkWell(
        onTap: () {
          _showCountrySearchDialog();
        },
        child: Row(
          children: [
            Icon(Icons.flag, color: AppColors.hint, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedCountry ?? 'Select Country',
                style: TextStyle(
                  color: _selectedCountry != null
                      ? AppColors.text
                      : AppColors.hint,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.hint),
          ],
        ),
      ),
    );
  }

  void _showCountrySearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CountrySearchDialog(
          countries: _countries,
          selectedCountry: _selectedCountry,
          onCountrySelected: (String country) {
            setState(() {
              _selectedCountry = country;
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildGenderField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Gender (optional)',
        border: OutlineInputBorder(),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Radio<String>(
                value: 'Male',
                groupValue: _selectedGender,
                onChanged: (val) => setState(() => _selectedGender = val ?? ''),
              ),
              Text('Male'),
            ],
          ),
          Row(
            children: [
              Radio<String>(
                value: 'Female',
                groupValue: _selectedGender,
                onChanged: (val) => setState(() => _selectedGender = val ?? ''),
              ),
              Text('Female'),
            ],
          ),
          Row(
            children: [
              Radio<String>(
                value: 'Other',
                groupValue: _selectedGender,
                onChanged: (val) => setState(() => _selectedGender = val ?? ''),
              ),
              Text('Other'),
            ],
          ),
        ],
      ),
    );
  }
}

class CountrySearchDialog extends StatefulWidget {
  final List<String> countries;
  final String? selectedCountry;
  final Function(String) onCountrySelected;

  const CountrySearchDialog({
    Key? key,
    required this.countries,
    this.selectedCountry,
    required this.onCountrySelected,
  }) : super(key: key);

  @override
  State<CountrySearchDialog> createState() => _CountrySearchDialogState();
}

class _CountrySearchDialogState extends State<CountrySearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = widget.countries;
    if (widget.selectedCountry != null) {
      _searchController.text = widget.selectedCountry!;
    }
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = widget.countries;
      } else {
        _filteredCountries = widget.countries
            .where(
              (country) => country.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.flag, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppColors.hint),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Search Field
            TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              decoration: InputDecoration(
                hintText: 'Search countries...',
                prefixIcon: Icon(Icons.search, color: AppColors.hint),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Countries List
            Expanded(
              child: _filteredCountries.isEmpty
                  ? Center(
                      child: Text(
                        'No countries found',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected = country == widget.selectedCountry;

                        return ListTile(
                          leading: Icon(
                            Icons.flag,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.hint,
                          ),
                          title: Text(
                            country,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.text,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            widget.onCountrySelected(country);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
