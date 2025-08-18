import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hrms_app/core/services/api_service.dart';
import '../widgets/tenant_bottom_nav.dart';
import 'tenant_profile_update_screen.dart';

class TenantProfileScreen extends ConsumerStatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  _TenantProfileScreenState createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends ConsumerState<TenantProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tenantInfo;
  Map<String, dynamic>? _userInfo;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final api = ref.read(apiServiceProvider);
      final response = await api.get('/tenant/profile');
      if (response.statusCode == 200) {
        final data = response.data;
        final Map<String, dynamic> root = (data is Map<String, dynamic>)
            ? (data['data'] is Map<String, dynamic>
                  ? data['data'] as Map<String, dynamic>
                  : data)
            : <String, dynamic>{};
        setState(() {
          _tenantInfo = root['tenant'];
          _userInfo = root['user'];
          _isLoading = false;
          // Prefill controllers for quick edit
          _firstNameController.text = (_tenantInfo?['first_name'] ?? '')
              .toString();
          _lastNameController.text = (_tenantInfo?['last_name'] ?? '')
              .toString();
          _emailController.text = _getEmail();
        });

        // Debug logs
        try {
          print(
            'DEBUG: Tenant keys => ' +
                ((_tenantInfo?.keys.toList()).toString()),
          );
          print(
            'DEBUG: User keys => ' + ((_userInfo?.keys.toList()).toString()),
          );
          print(
            'DEBUG: tenant.email=' +
                (_tenantInfo?['email']?.toString() ?? 'null'),
          );
          print(
            'DEBUG: user.email=' + (_userInfo?['email']?.toString() ?? 'null'),
          );
          print('DEBUG: resolved email=' + _getEmail());
          print(
            'DEBUG: occupation raw=' +
                (_tenantInfo?['occupation']?.toString() ?? 'null'),
          );
          print(
            'DEBUG: profession=' +
                (_tenantInfo?['profession']?.toString() ?? 'null'),
          );
          print(
            'DEBUG: job_title=' +
                (_tenantInfo?['job_title']?.toString() ?? 'null'),
          );
          print(
            'DEBUG: designation=' +
                (_tenantInfo?['designation']?.toString() ?? 'null'),
          );
        } catch (_) {}
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadProfile),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    SizedBox(height: 24),

                    // Accordion Sections
                    _buildAccordionSection(
                      title: 'Personal Information',
                      initiallyExpanded: true,
                      children: [
                        _buildInfoTile(
                          'Full Name',
                          '${_tenantInfo?['first_name'] ?? ''} ${_tenantInfo?['last_name'] ?? ''}'
                                  .trim()
                                  .isEmpty
                              ? (_tenantInfo?['name'] ?? 'N/A')
                              : '${_tenantInfo?['first_name'] ?? ''} ${_tenantInfo?['last_name'] ?? ''}',
                        ),
                        _buildInfoTile(
                          'Gender',
                          _tenantInfo?['gender'] ?? 'N/A',
                        ),
                        _buildInfoTile(
                          'Mobile',
                          _tenantInfo?['mobile'] ??
                              _tenantInfo?['phone'] ??
                              'N/A',
                        ),
                        _buildInfoTile('Email', _getEmail()),
                        _buildInfoTile(
                          'NID Number',
                          _tenantInfo?['nid_number'] ?? 'N/A',
                        ),
                        _buildInfoTile(
                          'Occupation',
                          (_tenantInfo?['occupation'] ??
                                  _tenantInfo?['profession'] ??
                                  _tenantInfo?['job_title'] ??
                                  _tenantInfo?['designation'] ??
                                  'N/A')
                              .toString(),
                        ),
                        _buildOptionalOccupationDetail(),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 10, bottom: 10),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TenantProfileUpdateScreen(
                                          initialTabIndex: 2,
                                        ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.edit, size: 18),
                              label: Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    _buildAccordionSection(
                      title: 'Family Information',
                      children: [
                        _buildInfoTile(
                          'Total family member',
                          _getFamilyMembersCount(),
                        ),
                        _buildFamilyTypeBadges(),

                        if (_getChildQty() != 'N/A' && _getChildQty() != '0')
                          _buildInfoTile('Child Quantity', _getChildQty()),
                        _buildInfoTile('Spouse Name', _getSpouseName()),
                        if (_hasParents())
                          _buildInfoTile('Father Name', _getFatherName()),
                        if (_hasParents())
                          _buildInfoTile('Mother Name', _getMotherName()),
                        if (_getSisterName() != 'N/A')
                          _buildInfoTile('Sister Name', _getSisterName()),
                        if (_getBrotherName() != 'N/A')
                          _buildInfoTile('Brother Name', _getBrotherName()),
                        _buildInfoTile('Emergency Contact', _getAltMobile()),
                      ],
                    ),
                    SizedBox(height: 12),

                    _buildAccordionSection(
                      title: 'Address',
                      children: [
                        _buildInfoTile('Address', _getAddressLine()),
                        _buildInfoTile('Upazila', _getCityName()),
                        _buildInfoTile('District', _getDistrictName()),
                        _buildInfoTile('ZIP', _getZipCode()),
                        _buildInfoTile('Country', _getCountryName()),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 10, bottom: 10),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TenantProfileUpdateScreen(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.edit, size: 18),
                              label: Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    _buildAccordionSection(
                      title: 'Property Information',
                      children: [
                        _buildInfoTile(
                          'Property',
                          _tenantInfo?['property']?['name'] ??
                              _tenantInfo?['property_name'] ??
                              'N/A',
                        ),
                        _buildInfoTile(
                          'Unit',
                          _tenantInfo?['unit']?['name'] ??
                              _tenantInfo?['unit_name'] ??
                              'N/A',
                        ),
                        _buildInfoTile(
                          'Address',
                          _tenantInfo?['address'] ?? 'N/A',
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    _buildAccordionSection(
                      title: 'Rental Information',
                      children: [
                        _buildInfoTile('Monthly Rent', _getMonthlyRent()),
                        _buildInfoTile('Advance Amount', _getAdvanceAmount()),
                        _buildInfoTile('Start Month', _getStartMonth()),
                        _buildInfoTile('Frequency', _getRentFrequency()),
                        _buildInfoTile('Lease Status', _getLeaseStatus()),
                      ],
                    ),
                    SizedBox(height: 12),

                    SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await AuthService.logout();
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildProfileHeader() {
    final name = _getFullName();
    final email = _getEmail();
    final pic = _getProfilePic();
    return Container(
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
        border: Border.all(color: Colors.black12, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade200,
                child: (pic.isEmpty)
                    ? Icon(Icons.person, size: 36, color: AppColors.primary)
                    : ClipOval(
                        child: _ResilientNetworkImage(
                          urls: _candidatePicUrls(pic),
                          width: 72,
                          height: 72,
                        ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: InkWell(
                  onTap: _showChangePhotoSheet,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              _showChangePhotoSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Icon(Icons.edit_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePhotoSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadProfilePic(source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadProfilePic(source: ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadProfilePic({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;

      final api = ref.read(apiServiceProvider);
      // Try original first, then compressed as fallback
      final compressedPath = await _compressImageToTemp(
        file.path,
        prefix: 'profile',
      );
      final List<String> uploadCandidates = [
        file.path,
        if (compressedPath != null) compressedPath,
      ];
      dio.Response uploadResp = dio.Response(
        requestOptions: dio.RequestOptions(path: '/common/upload'),
      );
      Object? lastError;
      for (final path in uploadCandidates) {
        try {
          final form = dio.FormData.fromMap({
            'file': await dio.MultipartFile.fromFile(path, filename: file.name),
            'folder': 'tenants',
          });
          uploadResp = await api.post('/common/upload', data: form);
          if (uploadResp.statusCode == 200) break;
        } catch (e) {
          lastError = e;
          continue;
        }
      }
      if (uploadResp.statusCode == 200 && uploadResp.data is Map) {
        final String url =
            uploadResp.data['url'] ?? uploadResp.data['path'] ?? '';
        if (url.isEmpty) return;
        // Prepare safe name values for required validation
        final currentFull = _getFullName();
        final parts = currentFull.trim().split(' ');
        final dynamic firstDyn = (_tenantInfo != null)
            ? _tenantInfo!['first_name']
            : null;
        final dynamic lastDyn = (_tenantInfo != null)
            ? _tenantInfo!['last_name']
            : null;
        final safeFirst = (firstDyn?.toString().trim().isNotEmpty ?? false)
            ? firstDyn.toString()
            : (parts.isNotEmpty ? parts.first : 'Tenant');
        final safeLast = (lastDyn?.toString().trim().isNotEmpty ?? false)
            ? lastDyn.toString()
            : (parts.length > 1 ? parts.sublist(1).join(' ') : '');
        // Update tenant profile_pic
        final resp = await api.put(
          '/tenant/profile/update-personal-info',
          data: {
            'profile_pic': url,
            'first_name': safeFirst,
            'last_name': safeLast,
          },
        );
        if (!mounted) return;
        if (resp.statusCode == 200) {
          await _loadProfile();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed (${resp.statusCode})'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _compressImageToTemp(
    String srcPath, {
    String prefix = 'img',
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        srcPath,
        targetPath,
        quality: 75,
        minWidth: 1080,
        minHeight: 1080,
      );
      return result?.path;
    } catch (_) {
      return null;
    }
  }

  void _showEditPersonalInfo() {
    _firstNameController.text = (_tenantInfo?['first_name'] ?? '').toString();
    _lastNameController.text = (_tenantInfo?['last_name'] ?? '').toString();
    _emailController.text = _getEmail();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Personal Information'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final api = ref.read(apiServiceProvider);
              try {
                final resp = await api.put(
                  '/tenant/profile/update-basic',
                  data: {
                    'first_name': _firstNameController.text.trim(),
                    'last_name': _lastNameController.text.trim(),
                    'email': _emailController.text.trim(),
                  },
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      resp.statusCode == 200
                          ? 'Updated successfully'
                          : 'Update failed',
                    ),
                    backgroundColor: resp.statusCode == 200
                        ? Colors.green
                        : Colors.red,
                  ),
                );
                if (resp.statusCode == 200) {
                  await _loadProfile();
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getFullName() {
    final first = (_tenantInfo?['first_name'] ?? '').toString().trim();
    final last = (_tenantInfo?['last_name'] ?? '').toString().trim();
    final name = (_tenantInfo?['name'] ?? '').toString().trim();
    if (first.isNotEmpty || last.isNotEmpty) return ('$first $last').trim();
    return name.isNotEmpty ? name : 'Tenant';
  }

  String _getEmail() {
    String pick(dynamic v) => (v ?? '').toString().trim();
    final candidates = [
      pick(_tenantInfo?['email']),
      pick(_tenantInfo?['contact_email']),
      pick(_tenantInfo?['primary_email']),
      pick(_tenantInfo?['tenant_email']),
      pick(_tenantInfo?['work_email']),
      pick(_tenantInfo?['official_email']),
    ];
    for (final c in candidates) {
      if (c.isNotEmpty && c.toLowerCase() != 'n/a' && c != '—' && c != '-') {
        return c;
      }
    }
    final userEmail = pick(_userInfo?['email']).isNotEmpty
        ? pick(_userInfo?['email'])
        : pick(_userInfo?['email_address']);
    return userEmail.isNotEmpty ? userEmail : '—';
  }

  String _getProfilePic() {
    final raw =
        (_tenantInfo?['profile_pic'] ??
                _tenantInfo?['nid_picture'] ??
                _tenantInfo?['photo'] ??
                _tenantInfo?['avatar'] ??
                '')
            .toString();
    return raw;
  }

  String _normalizePic(String raw) {
    final pic = raw.trim();
    if (pic.isEmpty) return '';
    String origin() {
      final base = ApiConfig.getBaseUrl();
      return base.replaceFirst(RegExp(r'/api/?$'), '');
    }

    // Absolute URL
    if (pic.startsWith('http://') || pic.startsWith('https://')) {
      try {
        final uri = Uri.parse(pic);
        final p = uri.path;
        if (p.startsWith('/storage/')) {
          final without = p.replaceFirst('/storage/', '/');
          return without.startsWith('/profiles/')
              ? '${origin()}/media$without'
              : '${origin()}$without';
        }
        if (p.startsWith('/profiles/')) {
          return '${origin()}/media$p';
        }
        return pic;
      } catch (_) {
        return pic;
      }
    }
    // Relative
    if (pic.startsWith('/storage/')) {
      final without = pic.replaceFirst('/storage/', '/');
      return without.startsWith('/profiles/')
          ? '${origin()}/media$without'
          : '${origin()}$without';
    }
    if (pic.startsWith('/profiles/')) {
      return '${origin()}/media$pic';
    }
    if (pic.startsWith('profiles/')) {
      return '${origin()}/media/$pic';
    }
    return '${origin()}/$pic';
  }

  List<String> _candidatePicUrls(String raw) {
    final String pic = raw.trim();
    if (pic.isEmpty) return [];
    String origin() {
      final base = ApiConfig.getBaseUrl();
      return base.replaceFirst(RegExp(r'/api/?$'), '');
    }

    String bust(String url) {
      final sep = url.contains('?') ? '&' : '?';
      return '$url${sep}t=${DateTime.now().millisecondsSinceEpoch}';
    }

    final List<String> urls = [];
    if (pic.startsWith('http://') || pic.startsWith('https://')) {
      urls.add(bust(pic));
      try {
        final uri = Uri.parse(pic);
        final p = uri.path;
        if (p.startsWith('/profiles/')) {
          urls.add(bust('${origin()}/api/media$p'));
        }
        if (p.startsWith('/tenants/')) {
          urls.add(bust('${origin()}/api/media$p'));
        }
        if (p.startsWith('/storage/')) {
          final without = p.replaceFirst('/storage/', '/');
          if (without.startsWith('/profiles/')) {
            urls.add(bust('${origin()}/api/media$without'));
          }
          if (without.startsWith('/tenants/')) {
            urls.add(bust('${origin()}/api/media$without'));
          }
        }
      } catch (_) {}
    } else {
      if (pic.startsWith('/profiles/')) {
        urls.add(bust('${origin()}$pic'));
        urls.add(bust('${origin()}/api/media$pic'));
      } else if (pic.startsWith('/tenants/')) {
        urls.add(bust('${origin()}$pic'));
        urls.add(bust('${origin()}/api/media$pic'));
      } else if (pic.startsWith('profiles/')) {
        urls.add(bust('${origin()}/$pic'));
        urls.add(bust('${origin()}/api/media/$pic'));
      } else if (pic.startsWith('tenants/')) {
        urls.add(bust('${origin()}/$pic'));
        urls.add(bust('${origin()}/api/media/$pic'));
      } else if (pic.startsWith('/storage/')) {
        final without = pic.replaceFirst('/storage/', '/');
        urls.add(bust('${origin()}$without'));
        if (without.startsWith('/profiles/')) {
          urls.add(bust('${origin()}/api/media$without'));
        }
        if (without.startsWith('/tenants/')) {
          urls.add(bust('${origin()}/api/media$without'));
        }
      } else {
        // Unknown relative path: try as-is under origin and via media
        urls.add(bust('${origin()}/$pic'));
        if (pic.contains('profiles/')) {
          final normalized = pic.startsWith('/') ? pic : '/$pic';
          urls.add(bust('${origin()}/api/media$normalized'));
        }
        if (pic.contains('tenants/')) {
          final normalized = pic.startsWith('/') ? pic : '/$pic';
          urls.add(bust('${origin()}/api/media$normalized'));
        }
      }
    }
    // De-duplicate
    final seen = <String>{};
    return urls.where((u) => seen.add(u)).toList();
  }

  // Family helpers with robust fallbacks
  String _resolveString(List<dynamic> sources) {
    for (final s in sources) {
      final v = (s ?? '').toString().trim();
      if (v.isNotEmpty && v.toLowerCase() != 'n/a' && v != '—' && v != '-') {
        return v;
      }
    }
    return 'N/A';
  }

  // Address helpers
  String _getAddressLine() {
    return _resolveString([
      _tenantInfo?['address'],
      _tenantInfo?['address_line'],
      _tenantInfo?['street_address'],
      _tenantInfo?['present_address'],
      _tenantInfo?['permanent_address'],
    ]);
  }

  String _getCityName() {
    return _resolveString([
      _tenantInfo?['city'],
      _tenantInfo?['thana'],
      _tenantInfo?['upazila'],
    ]);
  }

  String _getDistrictName() {
    return _resolveString([_tenantInfo?['district'], _tenantInfo?['zilla']]);
  }

  String _getZipCode() {
    return _resolveString([_tenantInfo?['zip'], _tenantInfo?['postal_code']]);
  }

  String _getCountryName() {
    return _resolveString([_tenantInfo?['country']]);
  }

  String _getSpouseName() {
    return _resolveString([
      _tenantInfo?['spouse_name'],
      _tenantInfo?['wife_name'],
      _tenantInfo?['husband_name'],
      _tenantInfo?['partner_name'],
    ]);
  }

  String _getSisterName() {
    return _resolveString([_tenantInfo?['sister_name']]);
  }

  String _getBrotherName() {
    return _resolveString([_tenantInfo?['brother_name']]);
  }

  String _getFatherName() {
    return _resolveString([
      _tenantInfo?['father_name'],
      _tenantInfo?['fathers_name'],
      _tenantInfo?['guardian_name'],
    ]);
  }

  String _getMotherName() {
    return _resolveString([
      _tenantInfo?['mother_name'],
      _tenantInfo?['mothers_name'],
    ]);
  }

  bool _hasParents() {
    final types =
        (_tenantInfo?['family_types'] ?? _tenantInfo?['family_type'] ?? '')
            .toString()
            .toLowerCase();
    return types.contains('parent');
  }

  String _getFamilyMembersCount() {
    final v =
        (_tenantInfo?['total_family_member'] ??
                _tenantInfo?['family_members'] ??
                _tenantInfo?['num_family_members'] ??
                _tenantInfo?['family_size'] ??
                '')
            .toString()
            .trim();
    return v.isEmpty ? 'N/A' : v;
  }

  String _getChildQty() {
    final v =
        (_tenantInfo?['child_qty'] ??
                _tenantInfo?['children'] ??
                _tenantInfo?['num_children'] ??
                '')
            .toString()
            .trim();
    return v.isEmpty ? 'N/A' : v;
  }

  String _getEmergencyContactName() {
    return _resolveString([
      _tenantInfo?['emergency_contact_name'],
      _tenantInfo?['emergency_name'],
      _tenantInfo?['ice_contact_name'],
      _tenantInfo?['emergency_person'],
    ]);
  }

  String _getEmergencyContactPhone() {
    return _resolveString([
      _tenantInfo?['emergency_contact_phone'],
      _tenantInfo?['emergency_phone'],
      _tenantInfo?['ice_contact_phone'],
      _tenantInfo?['emergency_mobile'],
    ]);
  }

  String _getAltMobile() {
    return _resolveString([
      _tenantInfo?['alt_mobile'],
      _tenantInfo?['alternate_mobile'],
      _tenantInfo?['alternate_phone'],
      _tenantInfo?['secondary_mobile'],
      _tenantInfo?['secondary_phone'],
    ]);
  }

  String _getFamilyType() {
    // Tenant model shows 'family_types' in fillable
    final raw =
        (_tenantInfo?['family_types'] ?? _tenantInfo?['family_type'] ?? '')
            .toString()
            .trim();
    return raw.isEmpty ? 'N/A' : raw;
  }

  // removed duplicate _getFamilyMembersCount

  // Occupation helpers
  String _getMonthlyRent() {
    final info = _tenantInfo;
    if (info == null) return 'N/A';
    dynamic rentRaw =
        info['monthly_rent'] ??
        info['rent'] ??
        info['monthly_amount'] ??
        info['total_rent'] ??
        info['total_monthly_rent'];
    // nested under unit
    final unitObj = info['unit'] is Map ? info['unit'] as Map : null;
    rentRaw ??=
        unitObj?['rent'] ?? unitObj?['monthly_rent'] ?? unitObj?['total_rent'];
    // nested under lease/tenancy
    final leaseObj = info['lease'] is Map
        ? info['lease'] as Map
        : (info['tenancy'] is Map ? info['tenancy'] as Map : null);
    rentRaw ??=
        leaseObj?['rent'] ??
        leaseObj?['monthly_rent'] ??
        leaseObj?['total_rent'];
    if (rentRaw == null) return 'N/A';
    return rentRaw.toString();
  }

  String _getAdvanceAmount() {
    final v = _resolveString([
      _tenantInfo?['advance_amount'],
      _tenantInfo?['security_deposit'],
      _tenantInfo?['deposit'],
    ]);
    return v == 'N/A' ? '0' : v;
  }

  String _getStartMonth() {
    return _resolveString([
      _tenantInfo?['start_month'],
      _tenantInfo?['lease_start'],
      _tenantInfo?['start_date'],
      _tenantInfo?['check_in_date'],
    ]);
  }

  String _getRentFrequency() {
    return _resolveString([
      _tenantInfo?['frequency'],
      _tenantInfo?['payment_frequency'],
      _tenantInfo?['rent_cycle'],
    ]);
  }

  String _getLeaseStatus() {
    return _resolveString([
      _tenantInfo?['lease_status'],
      _tenantInfo?['status'],
      _tenantInfo?['rental_status'],
    ]);
  }

  String _getOccupationType() {
    final occ =
        (_tenantInfo?['occupation'] ??
                _tenantInfo?['profession'] ??
                _tenantInfo?['job_title'] ??
                _tenantInfo?['designation'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();
    if (occ.contains('business')) return 'business';
    if (occ.contains('student')) return 'student';
    if (occ.contains('service') ||
        occ.contains('job') ||
        occ.contains('employee') ||
        occ.contains('gov')) {
      return 'service';
    }
    return occ;
  }

  String _getOccupationDetailLabel() {
    switch (_getOccupationType()) {
      case 'service':
        return 'Company Name';
      case 'business':
        return 'Business Name';
      case 'student':
        return 'University';
      default:
        return '';
    }
  }

  String _getOccupationDetailValue() {
    final type = _getOccupationType();
    String? v;
    if (type == 'service') {
      v =
          (_tenantInfo?['company_name'] ??
                  _tenantInfo?['company'] ??
                  _tenantInfo?['organization'] ??
                  _tenantInfo?['employer'] ??
                  _tenantInfo?['office_name'])
              ?.toString();
    } else if (type == 'business') {
      v =
          (_tenantInfo?['business_name'] ??
                  _tenantInfo?['company_name'] ??
                  _tenantInfo?['shop_name'] ??
                  _tenantInfo?['firm_name'])
              ?.toString();
    } else if (type == 'student') {
      // Extended fallbacks for various API field names (prefer college_university)
      v =
          (_tenantInfo?['college_university'] ??
                  _tenantInfo?['university'] ??
                  _tenantInfo?['university_name'] ??
                  _tenantInfo?['college'] ??
                  _tenantInfo?['college_name'] ??
                  _tenantInfo?['institution'] ??
                  _tenantInfo?['institution_name'] ??
                  _tenantInfo?['school'] ??
                  _tenantInfo?['school_name'] ??
                  _tenantInfo?['institute'] ??
                  _tenantInfo?['educational_institution'] ??
                  _tenantInfo?['education_institute'])
              ?.toString();
    }
    if (v == null) return 'N/A';
    final s = v.trim();
    return s.isEmpty ? 'N/A' : s;
  }

  Widget _buildOptionalOccupationDetail() {
    final label = _getOccupationDetailLabel();
    final value = _getOccupationDetailValue();
    if (label.isEmpty || value == 'N/A') return SizedBox.shrink();
    return _buildInfoTile(label, value);
  }

  Widget _buildAccordionSection({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
    Widget? headerTrailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (headerTrailing != null) ...[
                SizedBox(width: 8),
                headerTrailing,
              ],
            ],
          ),
          initiallyExpanded: initiallyExpanded,
          childrenPadding: EdgeInsets.only(bottom: 8),
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: children,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTypeBadges() {
    final raw = _getFamilyType();
    final List<String> types = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (types.isEmpty || raw == 'N/A') {
      return _buildInfoTile('Family Member', 'N/A');
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Family Member',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((t) {
                final color = _badgeColorForType(t.toLowerCase());
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _darken(color),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColorForType(String t) {
    if (t.contains('child')) return Colors.blue;
    if (t.contains('parent')) return Colors.teal;
    if (t.contains('spouse')) return Colors.pinkAccent;
    if (t.contains('sister')) return Colors.purple;
    if (t.contains('brother')) return Colors.indigo;
    return Colors.grey;
  }

  Color _darken(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class _ResilientNetworkImage extends StatefulWidget {
  final List<String> urls;
  final double width;
  final double height;
  const _ResilientNetworkImage({
    required this.urls,
    required this.width,
    required this.height,
  });

  @override
  State<_ResilientNetworkImage> createState() => _ResilientNetworkImageState();
}

class _ResilientNetworkImageState extends State<_ResilientNetworkImage> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.transparent,
      );
    }
    final url = widget.urls[_index];
    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        if (_index < widget.urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index++);
          });
        }
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.transparent,
          child: Icon(
            Icons.person,
            color: AppColors.primary,
            size: widget.width * 0.6,
          ),
        );
      },
    );
  }
}
