import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/widgets/search_picker.dart';
import 'package:hrms_app/core/utils/country_helper.dart';

class TenantProfileUpdateScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const TenantProfileUpdateScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<TenantProfileUpdateScreen> createState() =>
      _TenantProfileUpdateScreenState();
}

class _TenantProfileUpdateScreenState
    extends ConsumerState<TenantProfileUpdateScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _profile = {};

  // Controllers - Basic
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _spouseNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _sisterNameController = TextEditingController();
  final _brotherNameController = TextEditingController();

  String _gender = '';
  String _occupationType = '';

  // Controllers - Contact
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();

  // Controllers - Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  String? _selectedCountry = 'Bangladesh';
  String? _selectedDistrict;
  String? _selectedThana;
  List<String> _districtOptions = const [];
  List<String> _thanaOptions = const [];
  final _zipController = TextEditingController();

  // Controllers - Family
  final _familyMemberController = TextEditingController();
  List<String> _familyTypeSelections = <String>[];
  final List<String> _familyTypeChoices = const [
    'Child',
    'Parents',
    'Spouse',
    'Siblings',
    'Sister',
    'Brother',
    'Others',
  ];
  final _childQtyController = TextEditingController(text: '0');

  // Controllers - Documents
  final _nidNumberController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _nidFrontImageFile;
  File? _nidBackImageFile;

  // Controllers - Security
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Preferences
  bool _prefPush = true;
  bool _prefEmail = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadGeoOptions();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _orgNameController.dispose();
    _spouseNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _sisterNameController.dispose();
    _brotherNameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _zipController.dispose();
    _nidNumberController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _familyMemberController.dispose();
    _childQtyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.get('/tenant/profile');
      if (resp.statusCode == 200) {
        final data = resp.data;
        final dynamic root = data['data'] ?? data['tenant'] ?? data;
        if (root is Map<String, dynamic>) {
          setState(() {
            _profile = root;
            _firstNameController.text = (root['first_name'] ?? '').toString();
            _lastNameController.text = (root['last_name'] ?? '').toString();
            String pick(dynamic v) => (v ?? '').toString().trim();
            final dynamic userObj =
                (data['user'] ?? (data['data']?['user'] ?? null));
            final List<String> emailCandidates = [
              pick(root['email']),
              pick(root['contact_email']),
              pick(root['primary_email']),
              pick(root['tenant_email']),
              pick(root['work_email']),
              pick(root['official_email']),
              pick(userObj?['email']),
              pick(userObj?['email_address']),
            ];
            final String resolvedEmail = emailCandidates.firstWhere(
              (e) =>
                  e.isNotEmpty &&
                  e.toLowerCase() != 'n/a' &&
                  e != '—' &&
                  e != '-',
              orElse: () => '',
            );
            _emailController.text = resolvedEmail;
            _phoneController.text = (root['mobile'] ?? root['phone'] ?? '')
                .toString();
            _altPhoneController.text = (root['alt_phone'] ?? '').toString();
            _addressController.text = (root['address'] ?? '').toString();
            _cityController.text = (root['upazila'] ?? root['city'] ?? '')
                .toString();
            _districtController.text = (root['district'] ?? '').toString();
            _selectedCountry =
                (root['country'] ?? 'Bangladesh').toString().isEmpty
                ? 'Bangladesh'
                : (root['country'] as String?);
            _selectedDistrict = _districtController.text.isNotEmpty
                ? _districtController.text
                : null;
            _selectedThana = _cityController.text.isNotEmpty
                ? _cityController.text
                : null;
            _zipController.text = (root['zip'] ?? '').toString();
            _nidNumberController.text = (root['nid_number'] ?? '').toString();
            _gender = (root['gender'] ?? '').toString().toLowerCase();
            _spouseNameController.text =
                (root['spouse_name'] ??
                        root['wife_name'] ??
                        root['husband_name'] ??
                        root['partner_name'] ??
                        '')
                    .toString();
            _fatherNameController.text =
                (root['father_name'] ?? root['fathers_name'] ?? '').toString();
            _motherNameController.text =
                (root['mother_name'] ?? root['mothers_name'] ?? '').toString();
            _familyMemberController.text =
                (root['total_family_member'] ??
                        root['family_members'] ??
                        root['num_family_members'] ??
                        root['family_size'] ??
                        '')
                    .toString();
            final String rawFamily =
                (root['family_types'] ?? root['family_type'] ?? '').toString();
            _familyTypeSelections = rawFamily
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            _childQtyController.text =
                (root['child_qty'] ??
                        root['children'] ??
                        root['num_children'] ??
                        0)
                    .toString();
            final occRaw =
                ((root['occupation'] ??
                            root['profession'] ??
                            root['job_title'] ??
                            root['designation'] ??
                            '')
                        .toString()
                        .trim())
                    .toLowerCase();
            if (occRaw.contains('business')) {
              _occupationType = 'business';
              _orgNameController.text =
                  (root['business_name'] ??
                          root['company_name'] ??
                          root['shop_name'] ??
                          root['firm_name'] ??
                          '')
                      .toString();
            } else if (occRaw.contains('student')) {
              _occupationType = 'student';
              _orgNameController.text =
                  (root['college_university'] ??
                          root['university'] ??
                          root['college'] ??
                          root['institution'] ??
                          root['school'] ??
                          '')
                      .toString();
            } else if (occRaw.contains('service') ||
                occRaw.contains('job') ||
                occRaw.contains('employee') ||
                occRaw.contains('gov')) {
              _occupationType = 'service';
              _orgNameController.text =
                  (root['company_name'] ??
                          root['company'] ??
                          root['organization'] ??
                          root['employer'] ??
                          root['office_name'] ??
                          '')
                      .toString();
            } else {
              _occupationType = 'other';
              _orgNameController.text = '';
            }
            _prefPush = (root['pref_push'] ?? true) == true;
            _prefEmail = (root['pref_email'] ?? true) == true;
            _loading = false;
          });
          await _loadGeoOptions();
        } else {
          setState(() => _loading = false);
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadGeoOptions() async {
    try {
      // Try backend API first
      final api = ref.read(apiServiceProvider);
      final dResp = await api.get('/districts');
      List<String> districts = [];
      if (dResp.statusCode == 200 && dResp.data is List) {
        final List dd = dResp.data as List;
        districts = dd
            .map((e) => (e['name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .cast<String>()
            .toList();
      }
      List<String> thanas = [];
      if ((_selectedDistrict ?? '').isNotEmpty) {
        // Find selected district id by name
        String norm(String s) => s
            .toLowerCase()
            .replaceAll(' zila', '')
            .replaceAll(' district', '')
            .replaceAll('-', ' ')
            .replaceAll('_', ' ')
            .replaceAll(RegExp(r"\s+"), ' ')
            .trim();
        final list = (dResp.data as List);
        final match = list.cast<Map>().firstWhere(
          (e) => norm((e['name'] ?? '').toString()) == norm(_selectedDistrict!),
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          final tResp = await api.get('/districts/${match['id']}/upazilas');
          if (tResp.statusCode == 200 && tResp.data is List) {
            final List tt = tResp.data as List;
            thanas = tt
                .map((e) => (e['name'] ?? '').toString())
                .where((s) => s.isNotEmpty)
                .cast<String>()
                .toList();
          }
        }
      }
      // No local fallback
      if (!mounted) return;
      setState(() {
        _districtOptions = districts;
        _thanaOptions = thanas;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _districtOptions = const [];
        _thanaOptions = const [];
      });
    }
  }

  Future<void> _saveBasic() async {
    final api = ref.read(apiServiceProvider);
    try {
      final Map<String, dynamic> payload = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        'occupation': _occupationType,
      };
      if (_occupationType == 'service') {
        payload['company_name'] = _orgNameController.text.trim();
      } else if (_occupationType == 'business') {
        payload['business_name'] = _orgNameController.text.trim();
      } else if (_occupationType == 'student') {
        // Prefer the new backend field if present
        payload['college_university'] = _orgNameController.text.trim();
      }
      final resp = await api.put(
        '/tenant/profile/update-personal-info',
        data: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.statusCode == 200
                ? 'Personal information updated'
                : 'Failed to update personal info',
          ),
          backgroundColor: resp.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveContact() async {
    final api = ref.read(apiServiceProvider);
    try {
      final resp = await api.put(
        '/tenant/profile/update-contact',
        data: {
          'phone': _phoneController.text.trim(),
          'alt_phone': _altPhoneController.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.statusCode == 200
                ? 'Contact updated'
                : 'Failed to update contact',
          ),
          backgroundColor: resp.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveAddress() async {
    final api = ref.read(apiServiceProvider);
    try {
      final resp = await api.put(
        '/tenant/profile/update-address',
        data: {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'district': _districtController.text.trim(),
          'country': (_selectedCountry ?? '').toString().trim(),
          'zip': _zipController.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.statusCode == 200
                ? 'Address updated'
                : 'Failed to update address',
          ),
          backgroundColor: resp.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveDocuments() async {
    final api = ref.read(apiServiceProvider);
    try {
      dio.Response resp;
      if (_nidFrontImageFile != null || _nidBackImageFile != null) {
        final Map<String, dynamic> map = {
          'nid_number': _nidNumberController.text.trim(),
        };
        if (_nidFrontImageFile != null) {
          final String fName = _nidFrontImageFile!.path
              .split(Platform.pathSeparator)
              .last;
          map['nid_front_file'] = await dio.MultipartFile.fromFile(
            _nidFrontImageFile!.path,
            filename: fName,
          );
        }
        if (_nidBackImageFile != null) {
          final String bName = _nidBackImageFile!.path
              .split(Platform.pathSeparator)
              .last;
          map['nid_back_file'] = await dio.MultipartFile.fromFile(
            _nidBackImageFile!.path,
            filename: bName,
          );
        }
        final form = dio.FormData.fromMap(map);
        resp = await api.put('/tenant/profile/update-documents', data: form);
      } else {
        resp = await api.put(
          '/tenant/profile/update-documents',
          data: {'nid_number': _nidNumberController.text.trim()},
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.statusCode == 200
                ? 'Documents updated'
                : 'Failed to update documents',
          ),
          backgroundColor: resp.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveFamily() async {
    final api = ref.read(apiServiceProvider);
    try {
      // Reuse personal-info endpoint to avoid adding new routes
      final Map<String, dynamic> payload = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        'spouse_name': _spouseNameController.text.trim(),
        'father_name': _fatherNameController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'sister_name': _sisterNameController.text.trim(),
        'brother_name': _brotherNameController.text.trim(),
        'occupation': _occupationType,
        'total_family_member': _familyMemberController.text.trim(),
        'family_types': _familyTypeSelections.join(', '),
        'child_qty': _childQtyController.text.trim(),
      };
      if (_occupationType == 'service') {
        payload['company_name'] = _orgNameController.text.trim();
      } else if (_occupationType == 'business') {
        payload['business_name'] = _orgNameController.text.trim();
      } else if (_occupationType == 'student') {
        payload['college_university'] = _orgNameController.text.trim();
      }
      final resp = await api.put(
        '/tenant/profile/update-personal-info',
        data: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.statusCode == 200
                ? 'Family information updated'
                : 'Failed to update family information',
          ),
          backgroundColor: resp.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveSecurity() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final api = ref.read(apiServiceProvider);
    try {
      final resp = await api.put(
        '/tenant/profile/change-password',
        data: {
          'current_password': _currentPasswordController.text,
          'password': _newPasswordController.text,
          'password_confirmation': _confirmPasswordController.text,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.statusCode == 200
                ? 'Password updated'
                : 'Failed to update password',
          ),
          backgroundColor: resp.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
      if (resp.statusCode == 200) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _savePreferences() async {
    final api = ref.read(apiServiceProvider);
    try {
      final resp = await api.put(
        '/tenant/profile/update-preferences',
        data: {
          'pref_push': _prefPush ? 1 : 0,
          'pref_email': _prefEmail ? 1 : 0,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.statusCode == 200
                ? 'Preferences saved'
                : 'Failed to save preferences',
          ),
          backgroundColor: resp.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: widget.initialTabIndex.clamp(0, 5).toInt(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Update Profile'),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppColors.primary,
              child: TabBar(
                isScrollable: true,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Personal Information'),
                  Tab(text: 'Family'),
                  Tab(text: 'Address'),
                  Tab(text: 'Documents'),
                  Tab(text: 'Security'),
                  Tab(text: 'Preferences'),
                ],
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBasicSection(),
                  _buildFamilySection(),
                  _buildAddressSection(),
                  _buildDocumentsSection(),
                  _buildSecuritySection(),
                  _buildPreferencesSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildFamilySection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _familyMemberController,
            label: 'Total Family Members',
            icon: Icons.people_outline,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const Text(
            'Family Member',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _familyTypeChoices.map((type) {
                    final bool isSelected = _familyTypeSelections.contains(
                      type,
                    );
                    return FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _familyTypeSelections = [
                              ..._familyTypeSelections,
                              type,
                            ].toSet().toList();
                            if (type == 'Child' &&
                                !_familyTypeSelections.contains('Child')) {
                              _familyTypeSelections.add('Child');
                            }
                          } else {
                            _familyTypeSelections.remove(type);
                            if (type == 'Child') {
                              _childQtyController.text = '0';
                            }
                          }
                        });
                      },
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[600],
                    );
                  }).toList(),
                ),
                if (_familyTypeSelections.contains('Child')) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _childQtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Child Quantity',
                      prefixIcon: const Icon(Icons.child_care),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue[600]!,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
                if (_familyTypeSelections.contains('Spouse')) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _spouseNameController,
                    label: 'Spouse Name',
                    icon: Icons.favorite_outline,
                  ),
                ],
                if (_familyTypeSelections.contains('Parents')) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _fatherNameController,
                    label: 'Father Name',
                    icon: Icons.man_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _motherNameController,
                    label: 'Mother Name',
                    icon: Icons.woman_outlined,
                  ),
                ],
                if (_familyTypeSelections.contains('Sister')) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _sisterNameController,
                    label: 'Sister Name',
                    icon: Icons.face_3_outlined,
                  ),
                ],
                if (_familyTypeSelections.contains('Brother')) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _brotherNameController,
                    label: 'Brother Name',
                    icon: Icons.face_6_outlined,
                  ),
                ],
                if (_familyTypeSelections.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Selected: ${_familyTypeSelections.join(', ')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveFamily,
            child: const Text('Save Family Info'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: AppColors.inputBackground,
      ),
    );
  }

  Widget _buildBasicSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          // Mobile
          _buildTextField(
            controller: _phoneController,
            label: 'Mobile',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          // Gender
          DropdownButtonFormField<String>(
            value: (_gender.isEmpty) ? null : _gender,
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _gender = (v ?? '')),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _spouseNameController,
            label: 'Spouse Name',
            icon: Icons.favorite_outline,
          ),
          const SizedBox(height: 12),
          // Occupation
          DropdownButtonFormField<String>(
            value: (_occupationType.isEmpty) ? null : _occupationType,
            decoration: InputDecoration(
              labelText: 'Occupation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
            ),
            items: const [
              DropdownMenuItem(value: 'service', child: Text('Service')),
              DropdownMenuItem(value: 'business', child: Text('Business')),
              DropdownMenuItem(value: 'student', child: Text('Student')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() {
              _occupationType = (v ?? '');
              if (_occupationType == 'other') {
                _orgNameController.text = '';
              }
            }),
          ),
          const SizedBox(height: 12),
          if (_occupationType == 'service' ||
              _occupationType == 'business' ||
              _occupationType == 'student')
            _buildTextField(
              controller: _orgNameController,
              label: _occupationType == 'service'
                  ? 'Company Name'
                  : _occupationType == 'business'
                  ? 'Business Name'
                  : 'University',
              icon: Icons.apartment,
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveBasic,
            child: const Text('Save Personal Info'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _phoneController,
            label: 'Mobile',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _altPhoneController,
            label: 'Alternate Phone',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveContact,
            child: const Text('Save Contact'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _addressController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // District dropdown with basic in-popup search
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.inputBackground,
              border: Border.all(color: Colors.black26),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'District',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () async {
                    final selected = await SearchPicker.showBottomSheet<String>(
                      context: context,
                      title: 'Select District',
                      items: _districtOptions,
                      initiallySelected: _selectedDistrict,
                    );
                    if (selected != null) {
                      // Trigger onChanged logic
                      final v = selected;
                      setState(() {
                        _selectedDistrict = v;
                        _districtController.text = v;
                        _selectedThana = null;
                        _cityController.clear();
                        _thanaOptions = const [];
                      });
                      // Load thanas via backend API only
                      List<String> thanas = const [];
                      try {
                        final api = ref.read(apiServiceProvider);
                        // resolve id from name
                        final dResp = await api.get('/districts');
                        String norm(String s) => s
                            .toLowerCase()
                            .replaceAll(' zila', '')
                            .replaceAll(' district', '')
                            .replaceAll('-', ' ')
                            .replaceAll('_', ' ')
                            .replaceAll(RegExp(r"\\s+"), ' ')
                            .trim();
                        final list = (dResp.data as List);
                        final match = list.cast<Map>().firstWhere(
                          (e) => norm((e['name'] ?? '').toString()) == norm(v),
                          orElse: () => {},
                        );
                        if (match.isNotEmpty) {
                          final tResp = await api.get(
                            '/districts/${match['id']}/upazilas',
                          );
                          if (tResp.statusCode == 200 && tResp.data is List) {
                            final List tt = tResp.data as List;
                            thanas = tt
                                .map((e) => (e['name'] ?? '').toString())
                                .where((s) => s.isNotEmpty)
                                .cast<String>()
                                .toList();
                          }
                        }
                      } catch (_) {}
                      if (mounted) {
                        setState(() => _thanaOptions = thanas);
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDistrict ?? 'Tap to select district',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Thana dropdown with search
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.inputBackground,
              border: Border.all(color: Colors.black26),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thana/Upazila',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () async {
                    final selected = await SearchPicker.showBottomSheet<String>(
                      context: context,
                      title: 'Select Thana/Upazila',
                      items: _thanaOptions,
                      initiallySelected: _selectedThana,
                    );
                    if (selected != null) {
                      setState(() {
                        _selectedThana = selected;
                        _cityController.text = selected;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedThana ?? 'Tap to select thana/upazila',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _zipController,
            label: 'ZIP Code',
            icon: Icons.local_post_office,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          // Country picker (search)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.inputBackground,
              border: Border.all(color: Colors.black26),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Country',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () async {
                    final selected = await SearchPicker.showBottomSheet<String>(
                      context: context,
                      title: 'Select Country',
                      items: CountryHelper.getCountries(),
                      initiallySelected: _selectedCountry ?? 'Bangladesh',
                    );
                    if (selected != null) {
                      setState(() => _selectedCountry = selected);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (_selectedCountry == null ||
                                    _selectedCountry!.isEmpty)
                                ? 'Bangladesh'
                                : _selectedCountry!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveAddress,
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _nidNumberController,
            label: 'NID Number',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          const Text(
            'NID Front Side',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: _nidFrontImageFile != null
                    ? Colors.green
                    : Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: _nidFrontImageFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _nidFrontImageFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _nidFrontImageFile = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: () => _chooseNid(isFront: true),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add NID front side',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Camera or Gallery',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_nidFrontImageFile != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Front side selected',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _chooseNid(isFront: true),
                  child: const Text(
                    'Change',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'NID Back Side',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: _nidBackImageFile != null
                    ? Colors.green
                    : Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: _nidBackImageFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _nidBackImageFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _nidBackImageFile = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: () => _chooseNid(isFront: false),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add NID back side',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Camera or Gallery',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_nidBackImageFile != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Back side selected',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _chooseNid(isFront: false),
                  child: const Text(
                    'Change',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveDocuments,
            child: const Text('Save Documents'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickNid({
    required bool isFront,
    required ImageSource source,
  }) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          if (isFront) {
            _nidFrontImageFile = File(picked.path);
          } else {
            _nidBackImageFile = File(picked.path);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _chooseNid({required bool isFront}) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickNid(isFront: isFront, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from Gallery'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickNid(isFront: isFront, source: ImageSource.gallery);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecuritySection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _currentPasswordController,
            label: 'Current Password',
            icon: Icons.lock,
            obscure: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _newPasswordController,
            label: 'New Password',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveSecurity,
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: _prefPush,
            onChanged: (v) => setState(() => _prefPush = v),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive app notifications'),
          ),
          SwitchListTile(
            value: _prefEmail,
            onChanged: (v) => setState(() => _prefEmail = v),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive updates via email'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _savePreferences,
            child: const Text('Save Preferences'),
          ),
        ],
      ),
    );
  }
}
