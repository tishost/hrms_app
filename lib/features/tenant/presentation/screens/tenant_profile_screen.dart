import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/tenant_bottom_nav.dart';

class TenantProfileScreen extends StatefulWidget {
  @override
  _TenantProfileScreenState createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tenantInfo;
  Map<String, dynamic>? _userInfo;

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

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/tenant/profile')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tenantInfo = data['tenant'];
          _userInfo = data['user'];
          _isLoading = false;
        });
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _tenantInfo?['first_name'] != null &&
                                    _tenantInfo?['last_name'] != null
                                ? '${_tenantInfo!['first_name']} ${_tenantInfo!['last_name']}'
                                : 'Tenant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tenant',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Personal Information
                    _buildSection('Personal Information', [
                      _buildInfoTile(
                        'Full Name',
                        '${_tenantInfo?['first_name'] ?? ''} ${_tenantInfo?['last_name'] ?? ''}',
                      ),
                      _buildInfoTile('Mobile', _tenantInfo?['mobile'] ?? 'N/A'),
                      _buildInfoTile('Email', _tenantInfo?['email'] ?? 'N/A'),
                      _buildInfoTile('Gender', _tenantInfo?['gender'] ?? 'N/A'),
                      _buildInfoTile(
                        'NID Number',
                        _tenantInfo?['nid_number'] ?? 'N/A',
                      ),
                    ]),
                    SizedBox(height: 16),

                    // Property Information
                    _buildSection('Property Information', [
                      _buildInfoTile(
                        'Property',
                        _tenantInfo?['property']?['name'] ?? 'N/A',
                      ),
                      _buildInfoTile(
                        'Unit',
                        _tenantInfo?['unit']?['name'] ?? 'N/A',
                      ),
                      _buildInfoTile(
                        'Address',
                        _tenantInfo?['address'] ?? 'N/A',
                      ),
                    ]),
                    SizedBox(height: 16),

                    // Rental Information
                    _buildSection('Rental Information', [
                      _buildInfoTile(
                        'Advance Amount',
                        '\$${_tenantInfo?['advance_amount'] ?? '0'}',
                      ),
                      _buildInfoTile(
                        'Start Month',
                        _tenantInfo?['start_month'] ?? 'N/A',
                      ),
                      _buildInfoTile(
                        'Frequency',
                        _tenantInfo?['frequency'] ?? 'N/A',
                      ),
                    ]),
                    SizedBox(height: 16),

                    // Account Information
                    _buildSection('Account Information', [
                      _buildInfoTile(
                        'User ID',
                        _userInfo?['id']?.toString() ?? 'N/A',
                      ),
                      _buildInfoTile(
                        'Account Created',
                        _userInfo?['created_at'] ?? 'N/A',
                      ),
                      _buildInfoTile(
                        'Last Updated',
                        _userInfo?['updated_at'] ?? 'N/A',
                      ),
                    ]),
                    SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await AuthService.logout();
                          Navigator.pushReplacementNamed(context, '/login');
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
      bottomNavigationBar: TenantBottomNav(
        currentIndex:
            3, // Profile tab (Dashboard=0, Tenants=1, Billing=2, Profile=3)
        onTap: (index) {
          if (kDebugMode) {
            print('DEBUG: Bottom nav tapped - index: $index');
          }
          if (index == 3) return; // Already on profile

          switch (index) {
            case 0:
              if (kDebugMode) print('DEBUG: Navigating to dashboard');
              context.go('/dashboard');
              break;
            case 1:
              if (kDebugMode) print('DEBUG: Navigating to tenants');
              context.go('/tenants');
              break;
            case 2:
              if (kDebugMode) print('DEBUG: Navigating to billing');
              context.go('/billing');
              break;
          }
        },
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
}
