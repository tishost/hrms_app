import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/tenant/presentation/widgets/custom_bottom_nav.dart';
import 'tenant_entry_screen.dart';

class TenantDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> tenant;

  const TenantDetailsScreen({Key? key, required this.tenant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/dashboard'),
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
                              backgroundColor: Colors.white,
                              child: Text(
                                (tenant['name'] ?? 'T')[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
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
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusText(tenant['status']),
                                      style: TextStyle(
                                        color: Colors.white,
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
                    SizedBox(height: 20),

                    // Quick Actions
                    _buildSectionCard(
                      title: 'Quick Actions',
                      icon: Icons.flash_on,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.phone,
                                label: 'Call',
                                color: AppColors.green,
                                onTap: () {
                                  // TODO: Implement call functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Call feature coming soon!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.message,
                                label: 'Message',
                                color: AppColors.primary,
                                onTap: () {
                                  // TODO: Implement message functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Message feature coming soon!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.receipt,
                                label: 'Invoices',
                                color: AppColors.orange,
                                onTap: () {
                                  // TODO: Navigate to tenant invoices
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Invoices feature coming soon!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.payment,
                                label: 'Payment',
                                color: AppColors.darkBlue,
                                onTap: () {
                                  // TODO: Navigate to tenant payments
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Payment feature coming soon!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.edit,
                                label: 'Edit',
                                color: AppColors.yellow,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TenantEntryScreen(tenant: tenant),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.logout,
                                label: 'Checkout',
                                color: AppColors.red,
                                onTap: () {
                                  // TODO: Navigate to checkout
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Checkout feature coming soon!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Personal Information
                    _buildSectionCard(
                      title: 'Personal Information',
                      icon: Icons.person,
                      children: [
                        _buildInfoRow('Name', tenant['name'] ?? 'N/A'),
                        _buildInfoRow('Gender', tenant['gender'] ?? 'N/A'),
                        _buildInfoRow(
                          'NID Number',
                          tenant['nid_number'] ?? 'N/A',
                        ),
                        _buildInfoRow(
                          'Total Family Members',
                          '${tenant['total_family_member'] ?? 'N/A'}',
                        ),
                        if (tenant['family_types'] != null &&
                            tenant['family_types'].toString().isNotEmpty)
                          _buildInfoRow(
                            'Family Types',
                            _formatFamilyTypes(tenant['family_types']),
                          ),
                        if (tenant['child_qty'] != null &&
                            tenant['child_qty'] > 0)
                          _buildInfoRow('Children', '${tenant['child_qty']}'),
                      ],
                    ),

                    // Contact Information
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.phone,
                      children: [
                        _buildInfoRow('Mobile', tenant['mobile'] ?? 'N/A'),
                        if (tenant['alt_mobile'] != null &&
                            tenant['alt_mobile'].toString().isNotEmpty)
                          _buildInfoRow(
                            'Alternative Mobile',
                            tenant['alt_mobile'],
                          ),
                        if (tenant['email'] != null &&
                            tenant['email'].toString().isNotEmpty)
                          _buildInfoRow('Email', tenant['email']),
                      ],
                    ),

                    // Address Information
                    _buildSectionCard(
                      title: 'Address Information',
                      icon: Icons.location_on,
                      children: [
                        _buildInfoRow(
                          'Street Address',
                          tenant['address'] ?? 'N/A',
                        ),
                        if (tenant['city'] != null &&
                            tenant['city'].toString().isNotEmpty)
                          _buildInfoRow('City', tenant['city']),
                        if (tenant['state'] != null &&
                            tenant['state'].toString().isNotEmpty)
                          _buildInfoRow('State', tenant['state']),
                        if (tenant['zip'] != null &&
                            tenant['zip'].toString().isNotEmpty)
                          _buildInfoRow('ZIP Code', tenant['zip']),
                        _buildInfoRow('Country', tenant['country'] ?? 'N/A'),
                      ],
                    ),

                    // Occupation Information
                    _buildSectionCard(
                      title: 'Occupation Information',
                      icon: Icons.work,
                      children: [
                        _buildInfoRow(
                          'Occupation',
                          tenant['occupation'] ?? 'N/A',
                        ),
                        if (tenant['company_name'] != null &&
                            tenant['company_name'].toString().isNotEmpty)
                          _buildInfoRow('Company Name', tenant['company_name']),
                        if (tenant['college_university'] != null &&
                            tenant['college_university'].toString().isNotEmpty)
                          _buildInfoRow(
                            'College/University',
                            tenant['college_university'],
                          ),
                        if (tenant['business_name'] != null &&
                            tenant['business_name'].toString().isNotEmpty)
                          _buildInfoRow(
                            'Business Name',
                            tenant['business_name'],
                          ),
                        _buildInfoRow(
                          'Is Driver',
                          tenant['is_driver'] == true ? 'Yes' : 'No',
                        ),
                        if (tenant['driver_name'] != null &&
                            tenant['driver_name'].toString().isNotEmpty)
                          _buildInfoRow('Driver Name', tenant['driver_name']),
                      ],
                    ),

                    // Unit Information
                    _buildSectionCard(
                      title: 'Unit Information',
                      icon: Icons.home,
                      children: [
                        _buildInfoRow(
                          'Property',
                          tenant['property_name'] ?? 'N/A',
                        ),
                        _buildInfoRow('Unit', tenant['unit_name'] ?? 'N/A'),
                        _buildInfoRow(
                          'Check-in Date',
                          _formatDate(tenant['check_in_date']),
                        ),
                        if (tenant['check_out_date'] != null)
                          _buildInfoRow(
                            'Check-out Date',
                            _formatDate(tenant['check_out_date']),
                          ),
                        _buildInfoRow(
                          'Security Deposit',
                          '${tenant['security_deposit'] ?? '0'} BDT',
                        ),
                        _buildInfoRow(
                          'Rent Frequency',
                          tenant['frequency'] ?? 'N/A',
                        ),
                      ],
                    ),

                    // Additional Information
                    if (tenant['remarks'] != null &&
                        tenant['remarks'].toString().isNotEmpty)
                      _buildSectionCard(
                        title: 'Additional Information',
                        icon: Icons.note,
                        children: [_buildInfoRow('Remarks', tenant['remarks'])],
                      ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, // Tenants tab
        onTap: (index) {
          print('DEBUG: Bottom nav tapped - index: $index');
          if (index == 3) return; // Already on tenants

          switch (index) {
            case 0:
              print('DEBUG: Navigating to dashboard');
              context.go('/dashboard');
              break;
            case 1:
              print('DEBUG: Navigating to properties');
              context.go('/properties');
              break;
            case 2:
              print('DEBUG: Navigating to units');
              context.go('/units');
              break;
            case 4:
              print('DEBUG: Navigating to billing');
              context.go('/billing');
              break;
            case 5:
              print('DEBUG: Navigating to reports');
              context.go('/reports');
              break;
          }
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
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
