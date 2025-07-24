import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/owner/data/services/unit_service.dart';
import 'package:hrms_app/features/owner/presentation/screens/unit_entry_screen.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  _UnitListScreenState createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
      final units = await UnitService.getUnits();
      setState(() {
        _units = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
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
    String status = unit['status'] ?? 'vacant';
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'rented':
        statusColor = AppColors.orange;
        statusBgColor = AppColors.orange.withOpacity(0.1);
        statusIcon = Icons.person;
        break;
      case 'vacant':
        statusColor = AppColors.green;
        statusBgColor = AppColors.green.withOpacity(0.1);
        statusIcon = Icons.home_outlined;
        break;
      default:
        statusColor = AppColors.gray;
        statusBgColor = AppColors.gray.withOpacity(0.1);
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
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
          onTap: () async {
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
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Unit Name and Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit['name'] ?? 'Unnamed Unit',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            unit['property_name'] ?? 'No Property',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          SizedBox(width: 6),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                              'Total Rent',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '৳${totalRent.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Base: ৳${baseRent.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (totalCharges > 0)
                            Text(
                              '+৳${totalCharges.toStringAsFixed(0)} charges',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.orange,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tenant Information (if rented)
                if (unit['tenant_name'] != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.green.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: AppColors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit['tenant_name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              if (unit['tenant_mobile'] != null)
                                Text(
                                  unit['tenant_mobile'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Additional Info
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 16, color: AppColors.hint),
                    SizedBox(width: 8),
                    Text(
                      '${unit['charges'] != null ? unit['charges'].length : 0} charges',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Spacer(),
                    if (unit['floor'] != null) ...[
                      Icon(Icons.layers, size: 16, color: AppColors.hint),
                      SizedBox(width: 4),
                      Text(
                        'Floor ${unit['floor']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      return name.contains(query);
    }).toList();

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
          'My Units',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadUnits,
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
                                if (token == null)
                                  throw Exception('Not authenticated');
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
      floatingActionButton: FloatingActionButton(
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // Units tab
        onTap: (index) {
          print('DEBUG: Bottom nav tapped - index: $index');
          if (index == 2) return; // Already on units

          switch (index) {
            case 0:
              print('DEBUG: Navigating to dashboard');
              context.go('/dashboard');
              break;
            case 1:
              print('DEBUG: Navigating to properties');
              context.go('/properties');
              break;
            case 3:
              print('DEBUG: Navigating to tenants');
              context.go('/tenants');
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
}
