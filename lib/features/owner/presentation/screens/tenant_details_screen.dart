import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TenantDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tenant;

  const TenantDetailsScreen({super.key, required this.tenant});

  @override
  _TenantDetailsScreenState createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends State<TenantDetailsScreen> {
  Map<String, dynamic> _tenantData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTenantDetails();
  }

  Future<void> _fetchTenantDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/tenants/${widget.tenant['id']}')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tenantData = data['tenant'] ?? {};
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch tenant details');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Tenant Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primary),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Tenant Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primary),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading tenant details',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTenantDetails,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Handle null or empty tenant data
    if (_tenantData.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Tenant Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primary),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No tenant data found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, color: AppColors.primary),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tenant Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          '${_tenantData['first_name'] ?? ''} ${_tenantData['last_name'] ?? ''}'
                              .trim(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                _getInitials(
                                  '${_tenantData['first_name'] ?? ''} ${_tenantData['last_name'] ?? ''}',
                                ),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_tenantData['first_name'] ?? ''} ${_tenantData['last_name'] ?? ''}'
                                        .trim(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _tenantData['occupation'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        _tenantData['status'],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(_tenantData['status']),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Personal Information
                    _buildSectionCard('Personal Information', Icons.person, [
                      _buildInfoRow(
                        'Full Name',
                        '${_tenantData['first_name'] ?? ''} ${_tenantData['last_name'] ?? ''}'
                            .trim(),
                      ),
                      _buildInfoRow('Gender', _tenantData['gender'] ?? 'N/A'),
                      _buildInfoRow('Mobile', _tenantData['mobile'] ?? 'N/A'),
                      _buildInfoRow(
                        'Alt Mobile',
                        _tenantData['alt_mobile'] ?? 'N/A',
                      ),
                      _buildInfoRow('Email', _tenantData['email'] ?? 'N/A'),
                      _buildInfoRow(
                        'NID Number',
                        _tenantData['nid_number'] ?? 'N/A',
                      ),
                    ]),
                    SizedBox(height: 16),
                    // Address Information
                    _buildSectionCard(
                      'Address Information',
                      Icons.location_on,
                      [
                        _buildInfoRow(
                          'Address',
                          _tenantData['address'] ?? 'N/A',
                        ),
                        _buildInfoRow('City', _tenantData['city'] ?? 'N/A'),
                        _buildInfoRow('State', _tenantData['state'] ?? 'N/A'),
                        _buildInfoRow('ZIP Code', _tenantData['zip'] ?? 'N/A'),
                        _buildInfoRow(
                          'Country',
                          _tenantData['country'] ?? 'N/A',
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Work Information
                    _buildSectionCard('Work Information', Icons.work, [
                      _buildInfoRow(
                        'Occupation',
                        _tenantData['occupation'] ?? 'N/A',
                      ),
                      if (_tenantData['occupation']?.toString().toLowerCase() ==
                          'service')
                        _buildInfoRow(
                          'Company Name',
                          _tenantData['company_name'] ?? 'N/A',
                        ),
                      if (_tenantData['occupation']?.toString().toLowerCase() ==
                          'student')
                        _buildInfoRow(
                          'University/School',
                          _tenantData['college_university'] ?? 'N/A',
                        ),
                      if (_tenantData['occupation']?.toString().toLowerCase() ==
                          'business')
                        _buildInfoRow(
                          'Business Name',
                          _tenantData['business_name'] ?? 'N/A',
                        ),
                    ]),
                    SizedBox(height: 16),
                    // Family Information
                    _buildSectionCard(
                      'Family Information',
                      Icons.family_restroom,
                      [
                        _buildInfoRow(
                          'Total Family Members',
                          _tenantData['total_family_member']?.toString() ??
                              'N/A',
                        ),
                        _buildInfoRow(
                          'Family Types',
                          _formatFamilyTypes(_tenantData['family_types']),
                        ),
                        if (_tenantData['family_types'] != null &&
                            _tenantData['family_types']
                                .toString()
                                .toLowerCase()
                                .contains('child'))
                          _buildInfoRow(
                            'Child Quantity',
                            _tenantData['child_qty']?.toString() ?? 'N/A',
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Property Information
                    _buildSectionCard('Property Information', Icons.home, [
                      _buildInfoRow(
                        'Property',
                        _tenantData['property_name'] ?? 'N/A',
                      ),
                      _buildInfoRow('Unit', _tenantData['unit_name'] ?? 'N/A'),
                      _buildInfoRow(
                        'Check-in Date',
                        _formatDate(_tenantData['start_month']),
                      ),
                      _buildInfoRow(
                        'Frequency',
                        _tenantData['frequency'] ?? 'N/A',
                      ),
                    ]),
                    SizedBox(height: 16),
                    // Financial Information
                    _buildSectionCard(
                      'Financial Information',
                      Icons.attach_money,
                      [
                        _buildInfoRow(
                          'Monthly Rent',
                          '৳${_tenantData['rent'] ?? '0'}',
                        ),
                        _buildInfoRow(
                          'Total Amount',
                          '৳${_tenantData['total_rent'] ?? '0'}',
                        ),
                        _buildInfoRow(
                          'Due Balance',
                          '৳${_tenantData['due_balance'] ?? '0'}',
                        ),
                        _buildInfoRow(
                          'Security Deposit',
                          '৳${_tenantData['security_deposit'] ?? '0'}',
                        ),
                        // Unit Charges
                        if (_tenantData['unit_charges'] != null &&
                            (_tenantData['unit_charges'] as List)
                                .isNotEmpty) ...[
                          ...(_tenantData['unit_charges'] as List)
                              .map<Widget>(
                                (charge) => _buildInfoRow(
                                  charge['label'] ?? 'Unknown',
                                  '৳${charge['amount']?.toString() ?? '0'}',
                                ),
                              )
                              .toList(),
                        ] else ...[
                          _buildInfoRow(
                            'Cleaning Charges',
                            '৳${_tenantData['cleaning_charges'] ?? '0'}',
                          ),
                          _buildInfoRow(
                            'Other Charges',
                            '৳${_tenantData['other_charges'] ?? '0'}',
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 16),
                    // Additional Information
                    _buildSectionCard('Additional Information', Icons.info, [
                      _buildInfoRow(
                        'Driver',
                        _tenantData['is_driver'] == '1' ? 'Yes' : 'No',
                      ),
                      if (_tenantData['is_driver'] == '1')
                        _buildInfoRow(
                          'Driver Name',
                          _tenantData['driver_name'] ?? 'N/A',
                        ),
                      _buildInfoRow('Remarks', _tenantData['remarks'] ?? 'N/A'),
                    ]),
                    SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await context.push(
                                '/tenant-entry',
                                extra: widget.tenant,
                              );
                              if (result == true) {
                                // Refresh data
                                _fetchTenantDetails();
                              }
                            },
                            icon: Icon(Icons.edit),
                            label: Text('Edit Tenant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Payment history feature coming soon!',
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.payment),
                            label: Text('Payment History'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatFamilyTypes(dynamic familyTypes) {
    if (familyTypes == null || familyTypes.toString().isEmpty) {
      return 'N/A';
    }
    if (familyTypes is List) {
      return familyTypes.join(', ');
    }
    return familyTypes.toString();
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) {
      return 'N/A';
    }
    try {
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _getStatusText(dynamic status) {
    if (status == null) return 'Unknown';
    String statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'pending':
        return 'Pending';
      default:
        return status.toString();
    }
  }

  Color _getStatusColor(dynamic status) {
    if (status == null) return Colors.grey;
    String statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
