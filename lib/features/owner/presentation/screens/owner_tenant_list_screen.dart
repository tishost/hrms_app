import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/routing/app_routes.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';
import 'package:hrms_app/features/owner/presentation/screens/invoice_payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/features/tenant/presentation/screens/tenant_details_screen.dart';
import 'package:hrms_app/features/tenant/presentation/screens/tenant_entry_screen.dart';

class OwnerTenantListScreen extends StatefulWidget {
  @override
  _OwnerTenantListScreenState createState() => _OwnerTenantListScreenState();
}

class _OwnerTenantListScreenState extends State<OwnerTenantListScreen> {
  List<Map<String, dynamic>> _tenants = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredTenants = [];

  @override
  void initState() {
    super.initState();
    _fetchTenants();
  }

  Future<void> _fetchTenants() async {
    print('DEBUG: Starting to fetch tenants...');
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      print(
        'DEBUG: Token found: ${token.substring(0, 20)}..., making API call...',
      );

      // Get current user info
      final userResponse = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/user')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      print('DEBUG: User info response: ${userResponse.body}');

      final url = ApiConfig.getApiUrl('/tenants');
      print('DEBUG: API URL: $url');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };
      print('DEBUG: Request headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('DEBUG: API Response status: ${response.statusCode}');
      print('DEBUG: API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tenants = List<Map<String, dynamic>>.from(data['tenants'] ?? []);

        print('DEBUG: Parsed tenants data: $tenants');
        print('DEBUG: Loaded ${tenants.length} tenants');

        setState(() {
          _tenants = tenants;
          _filteredTenants = tenants; // Initialize filtered tenants
          _isLoading = false;
        });
      } else {
        print('DEBUG: API call failed with status: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error fetching tenants: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTenants(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTenants = _tenants;
      } else {
        _filteredTenants = _tenants.where((tenant) {
          final name = (tenant['name'] ?? '').toString().toLowerCase();
          final mobile = (tenant['mobile'] ?? '').toString().toLowerCase();
          final property = (tenant['property_name'] ?? '')
              .toString()
              .toLowerCase();
          final unit = (tenant['unit_name'] ?? '').toString().toLowerCase();
          final queryLower = query.toLowerCase();

          return name.contains(queryLower) ||
              mobile.contains(queryLower) ||
              property.contains(queryLower) ||
              unit.contains(queryLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tenants',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await context.push('/tenant-entry');
              if (result == true) {
                _fetchTenants();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterTenants,
              decoration: InputDecoration(
                hintText: 'Search tenants...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Tenants List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredTenants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No tenants found'
                              : 'No tenants match your search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchTenants,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _filteredTenants.length,
                      itemBuilder: (context, index) {
                        final tenant = _filteredTenants[index];
                        return _buildTenantCard(tenant);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex:
            3, // Tenants tab (Dashboard=0, Properties=1, Units=2, Tenants=3, Billing=4, Reports=5)
        onTap: (index) {
          if (kDebugMode) {
            print('DEBUG: Bottom nav tapped - index: $index');
          }
          if (index == 3) return; // Already on tenants

          switch (index) {
            case 0:
              if (kDebugMode) print('DEBUG: Navigating to dashboard');
              context.go('/dashboard');
              break;
            case 1:
              if (kDebugMode) print('DEBUG: Navigating to properties');
              context.go('/properties');
              break;
            case 2:
              if (kDebugMode) print('DEBUG: Navigating to units');
              context.go('/units');
              break;
            case 4:
              if (kDebugMode) print('DEBUG: Navigating to billing');
              context.go('/billing');
              break;
            case 5:
              if (kDebugMode) print('DEBUG: Navigating to reports');
              context.go('/reports');
              break;
          }
        },
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (kDebugMode) {
              print('DEBUG: Tenant tapped: ${tenant['name'] ?? 'Unknown'}');
            }
            // Don't navigate to tenant details, just show popup menu
            // context.push('/tenant-details', extra: tenant);
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Tenant Name and Actions
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant['name'] ?? 'Unknown Tenant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            tenant['mobile'] ?? 'No Mobile',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Menu
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'view':
                            context.push('/tenant-details', extra: tenant);
                            break;
                          case 'edit':
                            final result = await context.push(
                              '/tenant-entry',
                              extra: tenant,
                            );
                            if (result == true) {
                              _fetchTenants();
                            }
                            break;
                          case 'billing':
                            context.push('/billing', extra: tenant);
                            break;
                          case 'delete':
                            _showDeleteConfirmation(tenant);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'billing',
                          child: Row(
                            children: [
                              Icon(Icons.receipt, size: 20),
                              SizedBox(width: 8),
                              Text('Billing'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Property and Unit Information
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.home, size: 20, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Property',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  tenant['property_name'] ?? 'No Property',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.apartment,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  tenant['unit_name'] ?? 'No Unit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Rent Information
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Rent',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '৳${tenant['rent']?.toString() ?? '0'}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Tenant'),
        content: Text(
          'Are you sure you want to delete ${tenant['name']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTenant(tenant['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTenant(int tenantId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.getApiUrl('/tenants/$tenantId')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tenant deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchTenants();
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete tenant');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
