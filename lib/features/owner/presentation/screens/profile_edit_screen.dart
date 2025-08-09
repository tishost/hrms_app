import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedDistrict;
  List<String> _districtOptions = [];
  bool _isLoadingDistricts = false;
  bool _isSubmitting = false;
  String? _selectedCountry = 'Bangladesh';
  static const List<String> _countries = [
    'Bangladesh',
    'India',
    'Pakistan',
    'Nepal',
    'Sri Lanka',
  ];
  String? _selectedGender;
  XFile? _pickedImage;
  bool _isUploadingImage = false;
  Map<String, dynamic> _userData = {};

  // Image size limits (in MB)
  static const double _maxImageSizeMB = 5.0;
  static const int _maxImageWidth = 1024;
  static const int _maxImageHeight = 1024;
  static const int _imageQuality = 80;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchDistricts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/user');
      if (response.statusCode == 200 && response.data != null) {
        final u = response.data as Map<String, dynamic>;
        setState(() {
          _userData = u; // Store the full user data
          _nameController.text = (u['name'] ?? '').toString();
          _emailController.text = (u['email'] ?? '').toString();
          _phoneController.text = (u['phone'] ?? '').toString();
          _addressController.text = (u['address'] ?? '').toString();
          _selectedCountry = (u['country'] ?? 'Bangladesh').toString().isEmpty
              ? 'Bangladesh'
              : (u['country'] as String?);
          _selectedDistrict = (u['district'] ?? '') as String?;
          final g = (u['gender'] ?? '').toString().trim().toLowerCase();
          _selectedGender = (['male', 'female', 'other'].contains(g))
              ? g
              : null;
        });
      }

      // Cache also (store as JSON)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(response.data ?? {}));
    } catch (_) {}
  }

  Future<void> _fetchDistricts() async {
    setState(() => _isLoadingDistricts = true);
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/districts');
      final data = response.data;
      List<String> items = [];
      if (data is List) {
        for (final d in data) {
          if (d is String) items.add(d);
          if (d is Map && d['name'] is String) items.add(d['name']);
        }
      } else if (data is Map && data['data'] is List) {
        for (final d in (data['data'] as List)) {
          if (d is String) items.add(d);
          if (d is Map && d['name'] is String) items.add(d['name']);
        }
      }
      items = items.toSet().toList()..sort();
      setState(() => _districtOptions = items);
    } catch (_) {
      // Fallback minimal list if API fails
      setState(
        () => _districtOptions = ['Dhaka', 'Chattogram', 'Rajshahi', 'Khulna'],
      );
    } finally {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(apiServiceProvider);
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'district': _selectedDistrict,
        'country': _selectedCountry,
      };
      if (_selectedGender != null && _selectedGender!.isNotEmpty) {
        payload['gender'] = _selectedGender;
      }
      payload.removeWhere((key, value) => value == null);
      // If profile image picked, upload first
      if (_pickedImage != null) {
        setState(() => _isUploadingImage = true);
        try {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
              _pickedImage!.path,
              filename: _pickedImage!.name,
            ),
            'folder': 'profiles',
          });
          final dio = ref.read(dioProvider);
          final uploadRes = await dio.post(
            '/common/upload',
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          );
          if (uploadRes.statusCode == 200 && uploadRes.data != null) {
            final url = (uploadRes.data['url'] ?? uploadRes.data['path'] ?? '')
                .toString();
            if (url.isNotEmpty) {
              // Delete old profile picture if exists
              if (_userData['profile_pic'] != null &&
                  _userData['profile_pic'].toString().isNotEmpty) {
                try {
                  await dio.post(
                    '/common/delete-profile-pic',
                    data: {'old_path': _userData['profile_pic']},
                  );
                } catch (e) {
                  // Log but don't fail the update
                  print('Failed to delete old profile pic: $e');
                }
              }
              payload['profile_pic'] = url;

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile picture uploaded successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          setState(() => _isUploadingImage = false);
        }
      }

      final res = await api.post('/owner/profile/update', data: payload);
      if (res.statusCode == 200 ||
          (res.data is Map && (res.data['success'] == true))) {
        // Fetch fresh user and update cache immediately
        try {
          final fresh = await api.get('/user');
          if ((fresh.statusCode == 200) && fresh.data != null) {
            final Map<String, dynamic> userData = Map<String, dynamic>.from(
              fresh.data as Map,
            );

            // Add cache-busting query so updated image shows immediately
            final rawPic = (userData['profile_pic'] ?? '').toString();
            if (rawPic.isNotEmpty) {
              final ts = DateTime.now().millisecondsSinceEpoch;
              final hasQuery = rawPic.contains('?');
              userData['profile_pic'] = hasQuery
                  ? '${rawPic}&v=$ts'
                  : '${rawPic}?v=$ts';
            }

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_data', json.encode(userData));
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // After save, go back and trigger refresh
          if (context.canPop()) {
            // Pop with result to indicate successful update
            context.pop(true);
          } else {
            context.go('/profile');
          }
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Compress and validate image
  Future<File?> _compressAndValidateImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      // Check file size limit
      if (fileSizeMB > _maxImageSizeMB) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image size must be less than ${_maxImageSizeMB}MB. Current size: ${fileSizeMB.toStringAsFixed(2)}MB',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        '${imageFile.path}_compressed.jpg',
        quality: _imageQuality,
        minWidth: _maxImageWidth,
        minHeight: _maxImageHeight,
      );

      if (compressedFile != null) {
        final compressedSize = await compressedFile.length();
        final compressedSizeMB = compressedSize / (1024 * 1024);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image compressed: ${fileSizeMB.toStringAsFixed(2)}MB → ${compressedSizeMB.toStringAsFixed(2)}MB',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        return File(compressedFile.path);
      }

      return file; // Return original if compression fails
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/properties');
            }
          },
        ),
        title: const Text('Edit Profile'),
        actions: [
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile picture picker
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                          : null,
                      child: _pickedImage == null
                          ? Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 40,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(6),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (img != null) {
                            // Compress and validate image
                            final compressedFile =
                                await _compressAndValidateImage(img);
                            if (compressedFile != null) {
                              setState(
                                () => _pickedImage = XFile(compressedFile.path),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Image size limit info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Image Requirements: Max ${_maxImageSizeMB}MB, will be compressed to ${_maxImageWidth}x${_maxImageHeight}px for optimal performance',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 12),
              // Gender dropdown (optional) moved just after Full Name
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Gender (optional)',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value:
                        (const [
                          'male',
                          'female',
                          'other',
                        ]).contains(_selectedGender)
                        ? _selectedGender
                        : null,
                    hint: const Text('Select gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final ok = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v.trim());
                  if (!ok) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Mobile (verified from dashboard)',
                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // District dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: Icon(
                    Icons.location_city,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value:
                        (_districtOptions.isNotEmpty &&
                            _selectedDistrict != null &&
                            _districtOptions.contains(_selectedDistrict))
                        ? _selectedDistrict
                        : null,
                    hint: const Text('Select district'),
                    items:
                        (_districtOptions.isEmpty
                                ? <String>[
                                    'Dhaka',
                                    'Chattogram',
                                    'Rajshahi',
                                    'Khulna',
                                  ]
                                : _districtOptions)
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _selectedDistrict = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Country dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Country',
                  prefixIcon: Icon(Icons.public, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value:
                        (_selectedCountry != null &&
                            _countries.contains(_selectedCountry))
                        ? _selectedCountry
                        : 'Bangladesh',
                    items: _countries
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCountry = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Address (optional)',
                  prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
