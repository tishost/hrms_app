import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/features/tenant/presentation/screens/invoice_pdf_screen.dart';
import 'package:hrms_app/features/tenant/presentation/screens/debug_screen.dart';
import 'package:hrms_app/features/tenant/presentation/widgets/tenant_bottom_nav.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  _TenantDashboardScreenState createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic>? _tenantInfo;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/tenant/dashboard')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _dashboardData = data['data'] ?? {};
          _tenantInfo = data['data']['tenant'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load dashboard');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header (same as owner dashboard)
            Container(
              color: AppColors.background,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.go('/tenant/profile');
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
                        context.go('/tenant/profile');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tenantInfo?['first_name'] ?? 'Tenant',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _tenantInfo?['mobile'] ?? 'N/A',
                                style: TextStyle(
                                  color: AppColors.gray,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
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
                    icon: Icon(Icons.notifications_none, color: AppColors.red),
                    onPressed: () {
                      // TODO: Show notifications
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notifications coming soon!')),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.bug_report, color: AppColors.red),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DebugScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Scrollable Dashboard Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeCard(),
                            SizedBox(height: 24),
                            _buildSummaryCards(),
                            SizedBox(height: 24),
                            _buildQuickActions(),
                            SizedBox(height: 24),
                            _buildRecentInvoices(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _tenantInfo?['first_name'] ?? 'Tenant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.home, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_tenantInfo?['property']?['name'] ?? 'N/A'} - ${_tenantInfo?['unit']?['name'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _dashboardData['summary'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Invoices',
                '${summary['total_invoices'] ?? 0}',
                Icons.receipt,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Paid',
                '${summary['paid_invoices'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Pending',
                '${summary['pending_invoices'] ?? 0}',
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View Bills',
                Icons.receipt_long,
                Colors.blue,
                () => context.go('/tenant/billing'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'My Profile',
                Icons.person,
                Colors.green,
                () => context.go('/tenant/profile'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Contact Owner',
                Icons.message,
                Colors.orange,
                () {
                  // Handle contact owner
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contact feature coming soon!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices() {
    final recentInvoices = _dashboardData['recent_invoices'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Invoices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.go('/tenant/billing'),
              child: Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: recentInvoices.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No invoices found',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: recentInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = recentInvoices[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: invoice['status'] == 'paid'
                            ? Colors.green
                            : Colors.orange,
                        child: Icon(
                          invoice['status'] == 'paid'
                              ? Icons.check
                              : Icons.pending,
                          color: Colors.white,
                        ),
                      ),
                      title: Text('Invoice #${invoice['id']}'),
                      subtitle: Text('Amount: \$${invoice['amount']}'),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: invoice['status'] == 'paid'
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          invoice['status'] ?? 'Unknown',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      onTap: () {
                        // Navigate to PDF viewer using the same function as owner
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoicePdfScreen(
                              invoiceId: invoice['id'],
                              invoiceNumber:
                                  invoice['invoice_number'] ??
                                  'Invoice #${invoice['id']}',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
