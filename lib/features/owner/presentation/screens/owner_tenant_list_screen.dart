import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/routing/app_routes.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/features/tenant/presentation/screens/tenant_details_screen.dart';
import 'tenant_entry_screen.dart';
import 'checkout_form_screen.dart';

class OwnerTenantListScreen extends StatefulWidget {
  const OwnerTenantListScreen({super.key});

  @override
  _OwnerTenantListScreenState createState() => _OwnerTenantListScreenState();
}

class _OwnerTenantListScreenState extends State<OwnerTenantListScreen> {
  List<Map<String, dynamic>> _tenants = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'Active';
  String _selectedPropertyFilter = 'All';
  List<Map<String, dynamic>> _filteredTenants = [];
  final List<String> _statusOptions = ['All', 'Active', 'Inactive', 'Pending'];
  List<String> _propertyOptions = ['All'];

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

      // Build URL with filters
      final queryParams = <String, String>{};

      if (_selectedStatusFilter != 'All') {
        queryParams['status'] = _selectedStatusFilter.toLowerCase();
      }

      if (_selectedPropertyFilter != 'All') {
        queryParams['property'] = _selectedPropertyFilter;
      }

      final uri = Uri.parse(
        ApiConfig.getApiUrl('/tenants'),
      ).replace(queryParameters: queryParams);
      print('DEBUG: API URL: $uri');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };
      print('DEBUG: Request headers: $headers');

      final response = await http.get(uri, headers: headers);

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
        _updatePropertyOptions();
        _applyFilters();
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
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _tenants;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tenant) {
        final name = (tenant['name'] ?? '').toString().toLowerCase();
        final mobile = (tenant['mobile'] ?? '').toString().toLowerCase();
        final property = (tenant['property_name'] ?? '')
            .toString()
            .toLowerCase();
        final unit = (tenant['unit_name'] ?? '').toString().toLowerCase();
        final queryLower = _searchQuery.toLowerCase();

        return name.contains(queryLower) ||
            mobile.contains(queryLower) ||
            property.contains(queryLower) ||
            unit.contains(queryLower);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != 'All') {
      filtered = filtered.where((tenant) {
        final status = (tenant['status'] ?? 'active').toString().toLowerCase();
        final selectedStatus = _selectedStatusFilter.toLowerCase();

        // Handle different status formats
        if (selectedStatus == 'active') {
          return status == 'active';
        } else if (selectedStatus == 'inactive') {
          return status == 'inactive' || status == 'checked_out';
        } else if (selectedStatus == 'pending') {
          return status == 'pending' || status == 'pending_approval';
        }

        return status == selectedStatus;
      }).toList();
    }

    // Apply property filter
    if (_selectedPropertyFilter != 'All') {
      filtered = filtered.where((tenant) {
        final property = (tenant['property_name'] ?? '').toString();
        return property == _selectedPropertyFilter;
      }).toList();
    }

    setState(() {
      _filteredTenants = filtered;
    });
  }

  void _updatePropertyOptions() {
    final properties = _tenants
        .map((tenant) => tenant['property_name'] ?? '')
        .toSet()
        .toList();
    properties.removeWhere((property) => property.isEmpty);
    setState(() {
      _propertyOptions = ['All', ...properties];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Tenants',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search and Filter Section
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
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
                    SizedBox(height: 12),
                    // Filter Row
                    Row(
                      children: [
                        // Status Filter
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatusFilter,
                                isExpanded: true,
                                items: _statusOptions
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatusFilter = value!;
                                  });
                                  _fetchTenants(); // Refresh data with new filter
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Property Filter
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPropertyFilter,
                                isExpanded: true,
                                items: _propertyOptions
                                    .map(
                                      (property) => DropdownMenuItem(
                                        value: property,
                                        child: Text(property),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPropertyFilter = value!;
                                  });
                                  _fetchTenants(); // Refresh data with new filter
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Results Count
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_filteredTenants.length} tenant${_filteredTenants.length != 1 ? 's' : ''} found',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tenant List
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/tenant-entry');
          if (result == true) {
            // Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Refreshing tenant list...'),
                duration: Duration(seconds: 1),
                backgroundColor: AppColors.primary,
              ),
            );
            // Refresh tenant list
            await _fetchTenants();
          }
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (kDebugMode) {
            print('DEBUG: Bottom nav tapped - index: $index');
          }
          if (index == 3) return;
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/properties');
              break;
            case 2:
              context.go('/units');
              break;
            case 4:
              context.go('/billing');
              break;
            case 5:
              context.go('/reports');
              break;
          }
        },
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    // Status configuration
    String status = tenant['status'] ?? 'active';
    Color statusColor;
    Color statusBgColor;

    switch (status.toLowerCase()) {
      case 'active':
        statusColor = AppColors.green;
        statusBgColor = AppColors.green.withOpacity(0.2);
        break;
      case 'inactive':
        statusColor = AppColors.error;
        statusBgColor = AppColors.error.withOpacity(0.2);
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warning.withOpacity(0.2);
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusBgColor = AppColors.textSecondary.withOpacity(0.2);
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (kDebugMode) {
            print('DEBUG: Tenant tapped: ${tenant['name'] ?? 'Unknown'}');
          }
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // --- HEADER ROW ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tenant Name
                  Text(
                    tenant['name'] ?? 'Unknown Tenant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // --- PROPERTY INFO ---
              _buildInfoRow(
                Icons.home,
                tenant['property_name'] ?? 'No Property',
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                Icons.door_front_door,
                tenant['unit_name'] ?? 'No Unit',
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                Icons.attach_money,
                '৳${tenant['rent']?.toString() ?? '0'} / month',
              ),
              SizedBox(height: 12),
              // --- FOOTER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Phone
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        tenant['mobile'] ?? 'No Mobile',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
                            // Show loading indicator
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Refreshing tenant list...'),
                                duration: Duration(seconds: 1),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            // Refresh tenant list
                            await _fetchTenants();
                          }
                          break;
                        case 'billing':
                          context.push('/billing', extra: tenant);
                          break;
                        case 'checkout':
                          context.push('/checkout', extra: tenant);
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
                            Icon(
                              Icons.visibility,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'View Details',
                              style: TextStyle(color: AppColors.text),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(color: AppColors.text),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'billing',
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Billing',
                              style: TextStyle(color: AppColors.text),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'checkout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.exit_to_app,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Checkout',
                              style: TextStyle(color: AppColors.text),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 16,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
