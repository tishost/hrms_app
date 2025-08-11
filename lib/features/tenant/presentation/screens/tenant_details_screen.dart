import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/tenant/presentation/widgets/custom_bottom_nav.dart';

class TenantDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> tenant;

  const TenantDetailsScreen({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    // Reduced debug prints for better performance
    if (kDebugMode) {
      print(
        'DEBUG: TenantDetailsScreen building for: ${tenant['name'] ?? 'Unknown'}',
      );
    }

    // Handle null or empty tenant data
    if (tenant.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Tenant Details',
            style: TextStyle(color: AppColors.text),
          ),
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
                          tenant['name'] ?? 'Unknown',
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
                                _getInitials(tenant['name'] ?? ''),
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
                                    tenant['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    tenant['occupation'] ?? 'N/A',
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
                                      color: _getStatusColor(tenant['status']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(tenant['status']),
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
                      _buildInfoRow('Full Name', tenant['name'] ?? 'N/A'),
                      _buildInfoRow('Gender', tenant['gender'] ?? 'N/A'),
                      _buildInfoRow('Mobile', tenant['mobile'] ?? 'N/A'),
                      _buildInfoRow(
                        'Alt Mobile',
                        tenant['alt_mobile'] ?? 'N/A',
                      ),
                      _buildInfoRow('Email', tenant['email'] ?? 'N/A'),
                      _buildInfoRow(
                        'NID Number',
                        tenant['nid_number'] ?? 'N/A',
                      ),
                    ]),
                    SizedBox(height: 16),
                    // Address Information
                    _buildSectionCard(
                      'Address Information',
                      Icons.location_on,
                      [
                        _buildInfoRow('Address', tenant['address'] ?? 'N/A'),
                        _buildInfoRow('City', tenant['city'] ?? 'N/A'),
                        _buildInfoRow('State', tenant['state'] ?? 'N/A'),
                        _buildInfoRow('ZIP Code', tenant['zip'] ?? 'N/A'),
                        _buildInfoRow('Country', tenant['country'] ?? 'N/A'),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Work Information
                    _buildSectionCard('Work Information', Icons.work, [
                      _buildInfoRow(
                        'Occupation',
                        tenant['occupation'] ?? 'N/A',
                      ),
                      if (tenant['occupation']?.toString().toLowerCase() ==
                          'service')
                        _buildInfoRow(
                          'Company Name',
                          tenant['company_name'] ?? 'N/A',
                        ),
                      if (tenant['occupation']?.toString().toLowerCase() ==
                          'student')
                        _buildInfoRow(
                          'University/School',
                          tenant['college_university'] ?? 'N/A',
                        ),
                      if (tenant['occupation']?.toString().toLowerCase() ==
                          'business')
                        _buildInfoRow(
                          'Business Name',
                          tenant['business_name'] ?? 'N/A',
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
                          tenant['total_family_member']?.toString() ?? 'N/A',
                        ),
                        _buildInfoRow(
                          'Family Types',
                          _formatFamilyTypes(tenant['family_types']),
                        ),
                        if (tenant['family_types'] != null &&
                            tenant['family_types']
                                .toString()
                                .toLowerCase()
                                .contains('child'))
                          _buildInfoRow(
                            'Child Quantity',
                            tenant['child_qty']?.toString() ?? 'N/A',
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Property Information
                    _buildSectionCard('Property Information', Icons.home, [
                      _buildInfoRow(
                        'Property',
                        tenant['property_name'] ?? 'N/A',
                      ),
                      _buildInfoRow('Unit', tenant['unit_name'] ?? 'N/A'),
                      _buildInfoRow(
                        'Check-in Date',
                        _formatDate(tenant['check_in_date']),
                      ),
                      _buildInfoRow('Frequency', tenant['frequency'] ?? 'N/A'),
                    ]),
                    SizedBox(height: 16),
                    // Financial Information
                    _buildSectionCard(
                      'Financial Information',
                      Icons.attach_money,
                      [
                        _buildInfoRow(
                          'Security Deposit',
                          '৳${tenant['security_deposit'] ?? '0'}',
                        ),
                        _buildInfoRow(
                          'Cleaning Charges',
                          '৳${tenant['cleaning_charges'] ?? '0'}',
                        ),
                        _buildInfoRow(
                          'Other Charges',
                          '৳${tenant['other_charges'] ?? '0'}',
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Additional Information
                    _buildSectionCard('Additional Information', Icons.info, [
                      _buildInfoRow(
                        'Driver',
                        tenant['is_driver'] == '1' ? 'Yes' : 'No',
                      ),
                      if (tenant['is_driver'] == '1')
                        _buildInfoRow(
                          'Driver Name',
                          tenant['driver_name'] ?? 'N/A',
                        ),
                      _buildInfoRow('Remarks', tenant['remarks'] ?? 'N/A'),
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
                                extra: tenant,
                              );
                              if (result == true) {
                                // Refresh or go back
                                if (context.canPop()) {
                                  context.pop();
                                }
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
                              // Show payment history or billing info
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
      DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
