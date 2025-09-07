import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/owner/data/services/unit_service.dart';
import 'package:hrms_app/features/owner/presentation/screens/unit_entry_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/core/utils/api_config.dart';

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  _UnitListScreenState createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _planExpired = false;
  bool _canAddUnit = true;
  int _allowedUnitLimit = 999999;
  bool _unlimitedUnits = false;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All', // shows all units
    'Rented',
    'Vacant',
    'Maintained',
    'Archived',
  ];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String? token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');
      String? statusParam;
      switch (_selectedFilter) {
        case 'Rented':
          statusParam = 'rented';
          break;
        case 'Vacant':
          statusParam = 'vacant';
          break;
        case 'Maintained':
          statusParam = 'maintained';
          break;
        case 'Archived':
          statusParam = 'archived';
          break;
        case 'All':
        default:
          statusParam = null; // all
      }
      final units = await UnitService.getUnits(status: statusParam);
      setState(() {
        _units = units;
        _isLoading = false;
      });
      _evaluateUnitLimit();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _evaluateUnitLimit() async {
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
        int count = _units.length;
        int? limit;
        try {
          final raw = sub?['plan']?['units_limit'];
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
            _canAddUnit = canAdd;
            _allowedUnitLimit = allowed;
            _unlimitedUnits = unlimited;
          });
        }
      }
    } catch (_) {}
  }

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    double baseRent = double.tryParse(unit['rent']?.toString() ?? '0') ?? 0;
    double totalCharges = 0;
    if (unit['charges'] != null && unit['charges'] is List) {
      for (var c in unit['charges']) {
        var amt = 0.0;
        if (c is Map && c.containsKey('amount')) {
          amt = double.tryParse(c['amount']?.toString() ?? '0') ?? 0;
        }
        totalCharges += amt;
      }
    }
    double totalRent = baseRent + totalCharges;

    // Status configuration
    String status = unit['status'] ?? 'free';
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'rent':
        statusColor = AppColors.orange;
        break;
      case 'free':
        statusColor = AppColors.success;
        break;
      case 'archived':
        statusColor = AppColors.hint;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final index = _units.indexOf(unit);
            final isDisabled =
                _planExpired ||
                (!_unlimitedUnits && index >= _allowedUnitLimit);
            if (isDisabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Limit reached. Upgrade to manage more units.'),
                  action: SnackBarAction(
                    label: 'Upgrade',
                    onPressed: () => context.go('/subscription-plans'),
                    textColor: AppColors.primary,
                  ),
                ),
              );
              return;
            }
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UnitEntryScreen(unitId: unit['id']),
              ),
            );
            if (result == true) {
              _loadUnits();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Row: Unit Info + Status & Rent
                Row(
                  children: [
                    // Unit Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.home_work,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  unit['name'] ?? 'Unnamed Unit',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 14,
                                color: AppColors.hint,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  unit['property_name'] ?? 'No Property',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (unit['tenant_name'] != null) ...[
                            SizedBox(height: 2),
                            Text(
                              '👤 ${unit['tenant_name']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Status and Total Rent (Right Side)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: _getStatusGradient(status),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Total Rent',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '৳${totalRent.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
      ),
    );
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'rented':
        return LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'vacant':
        return LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'maintained':
        return LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'archived':
        return LinearGradient(
          colors: [Colors.grey, Colors.blueGrey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.grey, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'rented':
        return Icons.person;
      case 'vacant':
        return Icons.home_outlined;
      case 'maintained':
        return Icons.build;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'rented':
        return 'RENTED';
      case 'vacant':
        return 'VACANT';
      case 'maintained':
        return 'MAINTAINED';
      case 'archived':
        return 'ARCHIVED';
      default:
        return 'UNKNOWN';
    }
  }

  Widget _slideRightBackground() {
    return Container(
      color: AppColors.error,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 20),
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work, size: 60, color: AppColors.hint),
          SizedBox(height: 16),
          Text(
            'No units found',
            style: TextStyle(fontSize: 20, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Add a new unit to get started.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUnits = _units.where((unit) {
      final name = unit['name']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      if (!name.contains(query)) return false;
      if (_selectedFilter == 'All') return true;
      final st = (unit['status'] ?? '').toString().toLowerCase();
      if (_selectedFilter == 'Rented') return st == 'rented';
      if (_selectedFilter == 'Vacant') return st == 'vacant';
      if (_selectedFilter == 'Maintained') return st == 'maintained';
      if (_selectedFilter == 'Archived') return st == 'archived';
      return true;
    }).toList();

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
          'My Units',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadUnits,
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
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search units...',
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) async {
                            setState(() {
                              _selectedFilter = filter;
                            });
                            await _loadUnits();
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
          // Units List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : filteredUnits.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadUnits,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUnits.length,
                      itemBuilder: (context, index) {
                        final unit = filteredUnits[index];
                        return Dismissible(
                          key: ValueKey(unit['id'] ?? unit.hashCode),
                          direction: DismissDirection.endToStart,
                          background: _slideRightBackground(),
                          confirmDismiss: (direction) async {
                            final isDisabled =
                                _planExpired ||
                                (!_unlimitedUnits &&
                                    index >= _allowedUnitLimit);
                            if (isDisabled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Limit reached. Upgrade to manage more units.',
                                  ),
                                  action: SnackBarAction(
                                    label: 'Upgrade',
                                    onPressed: () =>
                                        context.go('/subscription-plans'),
                                    textColor: AppColors.primary,
                                  ),
                                ),
                              );
                              return false;
                            }
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Remove Unit'),
                                content: Text(
                                  'Are you sure you want to remove this unit?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                String? token = await AuthService.getToken();
                                if (token == null) {
                                  throw Exception('Not authenticated');
                                }
                                await UnitService.deleteUnit(unit['id']);
                                setState(() {
                                  _units.removeWhere(
                                    (u) => u['id'] == unit['id'],
                                  );
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Unit deleted successfully!'),
                                  ),
                                );
                                return true;
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Delete failed: ${e.toString()}',
                                    ),
                                  ),
                                );
                                return false;
                              }
                            }
                            return false;
                          },
                          child: _buildUnitCard(unit),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: (_planExpired || !_canAddUnit)
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
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UnitEntryScreen()),
                );
                if (result == true) {
                  _loadUnits();
                }
              },
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add, color: AppColors.white),
            ),
    );
  }
}
