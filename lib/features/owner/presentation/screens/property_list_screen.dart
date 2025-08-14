import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/owner/data/services/property_service.dart';
// import 'package:hrms_app/features/owner/presentation/screens/property_entry_screen.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _filteredProperties = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  String _selectedFilter = 'Active';
  // int _selectedIndex = 1; // Property tab selected (unused)
  bool _planExpired = false;
  bool _canAddProperty = true;
  int _allowedPropertyLimit = 999999;
  bool _unlimitedProperties = false;

  final List<String> _filterOptions = [
    'Active',
    'All',
    'Archived',
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Get token from shared preferences
      String? token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please login again!')));
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        return;
      }

      // Map UI filter to API params
      String? statusParam;
      bool includeArchived = false;
      switch (_selectedFilter) {
        case 'Active':
          statusParam = 'active';
          break;
        case 'Archived':
          statusParam = 'archived';
          includeArchived = true;
          break;
        case 'Maintenance':
          statusParam = 'maintenance';
          break;
        case 'All':
        default:
          statusParam = null;
          includeArchived = false;
      }

      final properties = await PropertyService.getProperties(
        status: statusParam,
        includeArchived: includeArchived,
      );

      setState(() {
        _properties = properties;
        _filterProperties();
        _isLoading = false;
        _isRefreshing = false;
      });

      // After loading properties, evaluate limits
      _evaluatePropertyLimit();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _evaluatePropertyLimit() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final url = ApiConfig.getApiUrl('/owner/subscription');
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final sub = data['subscription'];
        bool expired =
            (sub == null) ||
            ((sub['status'] ?? '').toString().toLowerCase() != 'active');
        int count = _properties.length;
        int? limit;
        try {
          final raw = sub?['plan']?['properties_limit'];
          if (raw is num) limit = raw.toInt();
          if (raw is String) limit = int.tryParse(raw);
        } catch (_) {}
        bool unlimited = (limit == -1);
        int allowed = unlimited ? 999999 : (limit ?? 1);
        if (expired) {
          allowed = 1;
          unlimited = false;
        }
        bool canAdd = !expired && (unlimited || count < allowed);
        if (mounted) {
          setState(() {
            _planExpired = expired;
            _canAddProperty = canAdd;
            _allowedPropertyLimit = allowed;
            _unlimitedProperties = unlimited;
          });
        }
      }
    } catch (_) {
      // Silent fail; keep existing state
    }
  }

  void _filterProperties() {
    List<Map<String, dynamic>> filtered = _properties;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((property) {
        final name = property['name'].toString().toLowerCase();
        final address = property['address'].toString().toLowerCase();
        final city = property['city'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            address.contains(query) ||
            city.contains(query);
      }).toList();
    }

    // Apply status filter (client-side safeguard)
    if (_selectedFilter != 'All') {
      final expected = _selectedFilter.toLowerCase();
      filtered = filtered.where((property) {
        final st = (property['status'] ?? '').toString().toLowerCase();
        return expected == 'archived' ? st == 'archived' : st == expected;
      }).toList();
    }

    setState(() {
      _filteredProperties = filtered;
    });
  }

  // _onItemTapped removed (unused)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'My Properties',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: _isRefreshing
                ? null
                : () {
                    setState(() {
                      _isRefreshing = true;
                    });
                    _loadProperties();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterProperties();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search properties...',
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
                SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                            _filterProperties();
                          },
                          backgroundColor: AppColors.white,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Properties List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : _filteredProperties.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadProperties,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredProperties.length,
                      itemBuilder: (context, index) {
                        final property = _filteredProperties[index];
                        return _buildPropertyCard(property);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: (_planExpired || !_canAddProperty)
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/subscription-plans'),
              backgroundColor: AppColors.primary,
              icon: Icon(Icons.upgrade, color: AppColors.white),
              label: Text(
                'Upgrade to add',
                style: TextStyle(color: AppColors.white),
              ),
            )
          : FloatingActionButton(
              onPressed: () async {
                final result = await context.push('/property-entry');
                if (result == true) {
                  _loadProperties();
                }
              },
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add, color: AppColors.white),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 80, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first property to get started',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await context.push('/property-entry');

              if (result == true) {
                _loadProperties();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Add Property',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return Dismissible(
      key: ValueKey(property['id'] ?? property.hashCode),
      direction: DismissDirection.endToStart,
      background: _slideRightBackground(),
      confirmDismiss: (direction) async {
        // Show confirmation dialog before remove
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Remove Property'),
            content: Text('Are you sure you want to remove this property?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Remove', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          try {
            String? token = await AuthService.getToken();
            if (token == null) throw Exception('Not authenticated');
            try {
              await PropertyService.deleteProperty(property['id']);
            } catch (e) {
              final msg = e.toString();
              if (msg.contains('requires_checkout') ||
                  msg.contains('REQUIRES_CHECKOUT')) {
                // Show prompt to go to checkout list/form
                final go = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Checkout required'),
                    content: Text(
                      'Some units are currently rented. Please checkout tenants before deleting this property.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Go to Checkout'),
                      ),
                    ],
                  ),
                );
                if (go == true) {
                  // Try to prefill tenant/unit if possible from backend later
                  context.go('/owner/tenants');
                }
                return false;
              }
              if (msg.contains('ARCHIVE_REQUIRED')) {
                final archive = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Archive Property?'),
                    content: Text(
                      'This property has linked units or data. You can archive it to keep invoices/billing intact. Proceed to archive?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Archive'),
                      ),
                    ],
                  ),
                );
                if (archive == true) {
                  final ok = await PropertyService.archiveProperty(
                    property['id'],
                  );
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Property archived successfully')),
                    );
                    _loadProperties();
                  }
                }
                return false;
              }
              rethrow;
            }
            setState(() {
              _properties.removeWhere((p) => p['id'] == property['id']);
              _filterProperties();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Property deleted successfully!')),
            );
            return true;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Delete failed: ${e.toString()}')),
            );
            return false;
          }
        }
        return false;
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final index = _filteredProperties.indexOf(property);
              final isDisabled =
                  _planExpired ||
                  (!_unlimitedProperties && index >= _allowedPropertyLimit);
              if (isDisabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Limit reached. Upgrade to manage more properties.',
                    ),
                    action: SnackBarAction(
                      label: 'Upgrade',
                      onPressed: () => context.go('/subscription-plans'),
                      textColor: AppColors.primary,
                    ),
                  ),
                );
                return;
              }
              // Open edit form with property data
              print('DEBUG: Property tapped for edit: $property');
              final result = await context.push(
                '/property-entry',
                extra: property,
              );
              if (result == true) {
                _loadProperties();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property['name'] ?? 'Unnamed Property',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              property['property_type'] ?? 'Unknown Type',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(property['status'] ?? 'active'),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.hint),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${property['address'] ?? ''}, ${property['city'] ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.apartment, size: 16, color: AppColors.hint),
                      SizedBox(width: 4),
                      Text(
                        '${property['total_units'] ?? 0} units',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Added ${_formatDate(property['created_at'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slideRightBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete, color: AppColors.error, size: 28),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        color = AppColors.success;
        label = 'Active';
        break;
      case 'inactive':
        color = AppColors.error;
        label = 'Inactive';
        break;
      case 'maintenance':
        color = AppColors.warning;
        label = 'Maintenance';
        break;
      default:
        color = AppColors.textSecondary;
        label = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
