import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/routing/app_routes.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';
import 'package:hrms_app/features/tenant/presentation/screens/invoice_payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/features/tenant/presentation/screens/tenant_details_screen.dart';
import 'package:hrms_app/features/tenant/presentation/screens/tenant_entry_screen.dart';

class TenantListScreen extends StatefulWidget {
  @override
  _TenantListScreenState createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
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
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/tenants')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tenants = List<Map<String, dynamic>>.from(data['tenants'] ?? []);

        // Debug print first tenant data (reduced for performance)
        if (tenants.isNotEmpty) {
          print('DEBUG: Loaded ${tenants.length} tenants');
        }

        setState(() {
          _tenants = tenants;
          _filteredTenants = tenants; // Initialize filtered tenants
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching tenants: $e');
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            // এই অংশটি পরিবর্তন করুন
            if (context.canPop()) {
              context.pop(); // যদি পেছনে যাওয়ার পেইজ থাকে, তাহলে pop করো
            } else {
              context.go(
                '/dashboard',
              ); // যদি কোনো কারণে পেছনে যাওয়ার পেইজ না থাকে, তাহলে fallback হিসেবে dashboard পেইজে যাও
            }
          },
        ),
        title: Text(
          'Tenants',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchTenants,
          ),
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primary),
            onPressed: () async {
              final result = await context.push('/tenant-entry');
              if (result == true) {
                _fetchTenants();
              }
            },
          ),
          // Test button for debugging
          if (_tenants.isNotEmpty && kDebugMode)
            IconButton(
              icon: Icon(Icons.bug_report, color: Colors.orange),
              onPressed: () {
                print('DEBUG: Test button pressed');
                context.push('/tenant-details', extra: _tenants.first);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterTenants(value);
              },
              decoration: InputDecoration(
                hintText: 'Search tenants...',
                prefixIcon: Icon(Icons.search, color: AppColors.hint),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading tenants...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredTenants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No tenants found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first tenant to get started',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await context.push('/tenant-entry');
                            if (result == true) {
                              _fetchTenants();
                            }
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add Tenant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchTenants,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredTenants.length,
                      itemBuilder: (context, index) {
                        final tenant = _filteredTenants[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                _getInitials(tenant['name'] ?? ''),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              tenant['name'] ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  '📱 ${tenant['mobile'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '🏠 ${tenant['property_name'] ?? 'N/A'} - ${tenant['unit_name'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                if (tenant['rent_amount'] != null)
                                  Text(
                                    '💰 Rent: \$${tenant['rent_amount']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'view':
                                    context.push(
                                      '/tenant-details',
                                      extra: tenant,
                                    );
                                    break;
                                  case 'edit':
                                    context
                                        .push('/tenant-entry', extra: tenant)
                                        .then((result) {
                                          if (result == true) {
                                            _fetchTenants();
                                          }
                                        });
                                    break;
                                  case 'delete':
                                    _showDeleteDialog(tenant);
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
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (kDebugMode) {
                                print(
                                  'DEBUG: Tenant tapped: ${tenant['name'] ?? 'Unknown'}',
                                );
                              }
                              // Don't navigate to tenant details, just show popup menu
                              // context.push('/tenant-details', extra: tenant);
                            },
                          ),
                        );
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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showDeleteDialog(Map<String, dynamic> tenant) {
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
            onPressed: () {
              Navigator.pop(context);
              _deleteTenant(tenant['id']);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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
            backgroundColor: Colors.green,
          ),
        );
        _fetchTenants(); // Refresh the list
      } else {
        throw Exception('Failed to delete tenant');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting tenant: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
