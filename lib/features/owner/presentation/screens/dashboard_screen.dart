import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/owner/presentation/screens/property_list_screen.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_drawer.dart';
import 'package:hrms_app/features/owner/presentation/screens/profile_screen.dart';
import 'package:hrms_app/features/owner/presentation/screens/unit_list_screen.dart';
import 'package:hrms_app/features/owner/presentation/screens/owner_tenant_list_screen.dart';
import 'package:hrms_app/features/owner/data/services/dashboard_service.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DashboardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  String userName = 'User';
  String userMobile = '';
  bool userPhoneVerified = false;

  // Dashboard data
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadDashboardData();
  }

  Future<void> _loadUserInfo() async {
    try {
      print('DEBUG: Loading user info from API...');

      // Get API service from provider
      final apiService = ref.read(apiServiceProvider);

      // Call user profile API
      final response = await apiService.get('/user');

      print(
        'DEBUG: User API Response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final userData = response.data;
        setState(() {
          // Build full name from first_name and last_name
          String firstName = userData['first_name'] ?? '';
          String lastName = userData['last_name'] ?? '';
          String fullName = userData['name'] ?? '';

          if (fullName.isEmpty &&
              (firstName.isNotEmpty || lastName.isNotEmpty)) {
            fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
          }

          userName = fullName.isNotEmpty ? fullName : 'User';
          userMobile = userData['phone'] ?? userData['mobile'] ?? '';
          userPhoneVerified = userData['phone_verified'] ?? false;
        });

        // Save to SharedPreferences for offline access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_info', jsonEncode(userData));

        print('DEBUG: User info loaded successfully: $userName');
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('API user load error: $e');

      // Fallback to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        String? userJson = prefs.getString('user_info');
        if (userJson != null) {
          final user = jsonDecode(userJson);
          setState(() {
            // Build full name from first_name and last_name
            String firstName = user['first_name'] ?? '';
            String lastName = user['last_name'] ?? '';
            String fullName = user['name'] ?? '';

            if (fullName.isEmpty &&
                (firstName.isNotEmpty || lastName.isNotEmpty)) {
              fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
            }

            userName = fullName.isNotEmpty ? fullName : 'User';
            userMobile = user['phone'] ?? user['mobile'] ?? '';
            userPhoneVerified = user['phone_verified'] ?? false;
          });
          print('DEBUG: User info loaded from cache: $userName');
        } else {
          setState(() {
            userName = 'User';
            userMobile = '';
            userPhoneVerified = false;
          });
          print('DEBUG: No cached user info found');
        }
      } catch (e) {
        print('SharedPreferences user load error: $e');
        setState(() {
          userName = 'User';
          userMobile = '';
          userPhoneVerified = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyListScreen(),
          maintainState: true,
        ),
      );
    } else if (index == 2) {
      context.go('/tenants');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      endDrawer: CustomDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: AppColors.primary,
          backgroundColor: AppColors.background,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Custom Header (with menu icon that opens endDrawer)
                Builder(
                  builder: (context) => Container(
                    color: AppColors.background,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.push('/profile').then((_) {
                              // Refresh user info when returning from profile
                              _loadUserInfo();
                            });
                          },
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.lightGray,
                            child: Icon(
                              Icons.person,
                              color: AppColors.gray,
                              size: 36,
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.push('/profile').then((_) {
                                // Refresh user info when returning from profile
                                _loadUserInfo();
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      userMobile,
                                      style: TextStyle(
                                        color: AppColors.gray,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (userPhoneVerified == true)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4.0,
                                        ),
                                        child: Icon(
                                          Icons.verified,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                      ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.notifications_none,
                            color: AppColors.red,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.menu, color: AppColors.red),
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Summary Cards (Compact Grid)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.symmetric(horizontal: 16),
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
                              SizedBox(height: 8),
                              Text(
                                'Loading dashboard...',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // First Row - 3 cards
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Tenants',
                                    value:
                                        '${_dashboardStats['total_tenants'] ?? 0}',
                                    icon: Icons.people,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Units',
                                    value:
                                        '${_dashboardStats['total_units'] ?? 0}',
                                    icon: Icons.home_work,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Properties',
                                    value:
                                        '${_dashboardStats['total_properties'] ?? 0}',
                                    icon: Icons.business,
                                    color: AppColors.orange,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            // Second Row - 3 cards
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Rent Collected',
                                    value:
                                        '\u09F3 ${_dashboardStats['rent_collected'] ?? 0}',
                                    icon: Icons.attach_money,
                                    color: AppColors.green,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Dues',
                                    value:
                                        '\u09F3 ${_dashboardStats['total_dues'] ?? 0}',
                                    icon: Icons.warning_amber_rounded,
                                    color: AppColors.yellow,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Vacant Units',
                                    value:
                                        '${_dashboardStats['vacant_units'] ?? 0}',
                                    icon: Icons.home_outlined,
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                // Reports Section
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reports',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/reports');
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 130,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _ReportCard(
                              title: 'Financial Report',
                              subtitle: 'Revenue & Payments',
                              icon: Icons.attach_money,
                              color: AppColors.green,
                              onTap: () {
                                context.push('/reports');
                              },
                            ),
                            SizedBox(width: 12),
                            _ReportCard(
                              title: 'Occupancy Report',
                              subtitle: 'Property Status',
                              icon: Icons.home,
                              color: AppColors.blue,
                              onTap: () {
                                context.push('/reports');
                              },
                            ),
                            SizedBox(width: 12),
                            _ReportCard(
                              title: 'Tenant Report',
                              subtitle: 'Tenant Information',
                              icon: Icons.people,
                              color: AppColors.orange,
                              onTap: () {
                                context.push('/reports');
                              },
                            ),
                            SizedBox(width: 12),
                            _ReportCard(
                              title: 'Transaction Report',
                              subtitle: 'Detailed Ledger',
                              icon: Icons.receipt_long,
                              color: AppColors.purple,
                              onTap: () {
                                context.go('/reports');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Just For You - Banner Ads Section
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Just For You',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'বিশেষ অফার',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 170,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _BannerAdCard(
                              title: 'সুপার ফ্যামিলি প্যাক',
                              subtitle: '৩ জনের জন্য',
                              price: '৳ ৫০০',
                              details: '৩০ জিবি + এসএমএস\nমেয়াদ ৩০ দিন',
                              buttonText: 'ট্যাপ করুন',
                              color: AppColors.primary,
                              icon: Icons.family_restroom,
                            ),
                            SizedBox(width: 12),
                            _BannerAdCard(
                              title: 'ডেটা প্যাক',
                              subtitle: 'হাই স্পিড',
                              price: '৳ ১৯৯',
                              details: '১৫ জিবি + ফ্রি হোইচোই\nমেয়াদ ৭ দিন',
                              buttonText: 'ট্যাপ করুন',
                              color: AppColors.green,
                              icon: Icons.wifi,
                            ),
                            SizedBox(width: 12),
                            _BannerAdCard(
                              title: 'মিনিট প্যাক',
                              subtitle: 'আনলিমিটেড',
                              price: '৳ ২৯০',
                              details: '৪০০ মিনিট\nমেয়াদ ৩০ দিন',
                              buttonText: 'ট্যাপ করুন',
                              color: AppColors.orange,
                              icon: Icons.phone,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Recent Transactions
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          GestureDetector(
                            onTap: _refreshDashboard,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.refresh,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Loading transactions...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _recentTransactions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No recent transactions',
                                  style: TextStyle(color: AppColors.gray),
                                ),
                              ),
                            )
                          : Container(
                              height: 200, // Fixed height for transactions
                              child: ListView.builder(
                                itemCount: _recentTransactions.length,
                                itemBuilder: (context, index) {
                                  final transaction =
                                      _recentTransactions[index];
                                  return _TransactionTile(
                                    name:
                                        transaction['tenant_name'] ?? 'Unknown',
                                    action:
                                        transaction['description'] ??
                                        transaction['type'] ??
                                        'Transaction',
                                    amount:
                                        '${transaction['is_credit'] ? '+' : '-'}${transaction['amount']}',
                                    date: transaction['date'] ?? '',
                                    color: transaction['is_credit']
                                        ? AppColors.green
                                        : AppColors.yellow,
                                  );
                                },
                              ),
                            ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          print('DEBUG: Bottom nav tapped - index: $index');
          if (index == 0) return; // Already on dashboard

          switch (index) {
            case 1:
              print('DEBUG: Navigating to properties');
              context.go('/properties');
              break;
            case 2:
              print('DEBUG: Navigating to units');
              context.go('/units');
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

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      print('DEBUG: Loading dashboard data...');

      // Get dashboard service from provider
      final dashboardService = ref.read(dashboardServiceProvider);

      // Load dashboard stats
      final statsData = await dashboardService.getDashboardStats();
      final transactionsData = await dashboardService.getRecentTransactions();

      print('DEBUG: Dashboard stats loaded: $statsData');
      print(
        'DEBUG: Recent transactions loaded: ${transactionsData.length} items',
      );

      setState(() {
        _dashboardStats = statsData['stats'] ?? {};
        _recentTransactions = transactionsData;
        _isLoading = false;
      });
    } catch (e) {
      print('Dashboard Load Error: $e');
      setState(() => _isLoading = false);

      // Show error in UI instead of snackbar
      setState(() {
        _dashboardStats = {
          'total_tenants': 0,
          'total_units': 0,
          'total_properties': 0,
          'rent_collected': 0,
          'total_dues': 0,
          'vacant_units': 0,
        };
        _recentTransactions = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load dashboard data. Please check your connection.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle card tap for ads/actions
        print('Card tapped: $title');
        // You can add navigation or ad logic here
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
              color.withOpacity(0.1),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 4,
              offset: Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: AppColors.gray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerAdCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String details;
  final String buttonText;
  final Color color;
  final IconData icon;

  const _BannerAdCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.details,
    required this.buttonText,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('Banner ad tapped: $title');
        // Add your ad logic here
      },
      child: Container(
        width: 250,
        height: 160,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Icon and content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  // Bottom section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right side - Decorative element
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: AppColors.gray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String name;
  final String action;
  final String amount;
  final String date;
  final Color color;
  const _TransactionTile({
    required this.name,
    required this.action,
    required this.amount,
    required this.date,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(Icons.account_circle, color: color),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(action),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          SizedBox(height: 2),
          Text(date, style: TextStyle(fontSize: 12, color: AppColors.gray)),
        ],
      ),
    );
  }
}
