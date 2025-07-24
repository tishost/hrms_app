import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';
import 'invoice_payment_screen.dart';
import 'invoice_pdf_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  @override
  _InvoiceListScreenState createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, unpaid, paid

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      String? token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/invoices')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _invoices = List<Map<String, dynamic>>.from(data['invoices'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load invoices')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    if (_selectedFilter == 'all') return _invoices;
    return _invoices
        .where((invoice) => invoice['status']?.toLowerCase() == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoices', style: TextStyle(color: AppColors.primary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchInvoices,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Filter Buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildFilterButton('all', 'All')),
                SizedBox(width: 8),
                Expanded(child: _buildFilterButton('unpaid', 'Unpaid')),
                SizedBox(width: 8),
                Expanded(child: _buildFilterButton('paid', 'Paid')),
              ],
            ),
          ),
          // Invoice List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No invoices found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchInvoices,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getInvoiceTypeColor(
                                invoice['invoice_type'],
                              ),
                              child: Icon(
                                _getInvoiceTypeIcon(invoice['invoice_type']),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              invoice['description'] ?? 'Invoice',
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
                                  '👤 ${invoice['tenant_name'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '🏠 ${invoice['unit_name'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '📅 Due: ${_formatDate(invoice['due_date'])}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                // Fees breakdown
                                if (invoice['breakdown'] != null &&
                                    (invoice['breakdown'] as List)
                                        .isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '💰 Fees Breakdown:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        ...(invoice['breakdown'] as List).map<
                                          Widget
                                        >((fee) {
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: 2),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '• ${fee['name'] ?? 'Fee'}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                Text(
                                                  '৳${fee['amount'] ?? '0'}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${invoice['amount'] ?? '0'} BDT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(invoice['status']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(invoice['status']),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Show payment options
                              _showPaymentOptions(invoice);
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
        currentIndex: 4, // Billing tab
        onTap: (index) {
          print('DEBUG: Bottom nav tapped - index: $index');
          if (index == 4) return; // Already on billing

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
            case 3:
              print('DEBUG: Navigating to tenants');
              context.go('/tenants');
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

  Widget _buildFilterButton(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getInvoiceTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'advance':
        return Colors.orange;
      case 'rent':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getInvoiceTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'advance':
        return Icons.security;
      case 'rent':
        return Icons.home;
      default:
        return Icons.receipt;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'unpaid':
        return 'Unpaid';
      case 'partial':
        return 'Partial';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        return date.split(' ')[0]; // Remove time part if present
      }
      return date.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  void _showPaymentOptions(Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Invoice #${invoice['invoice_number'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Amount: ৳${invoice['amount'] ?? '0'}',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InvoicePaymentScreen(invoice: invoice),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _fetchInvoices(); // Refresh list after payment
                        }
                      });
                    },
                    icon: Icon(Icons.payment, color: Colors.white),
                    label: Text('Make Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoicePdfScreen(
                            invoiceId: invoice['id'],
                            invoiceNumber: invoice['invoice_number'] ?? 'N/A',
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.picture_as_pdf, color: AppColors.primary),
                    label: Text('View PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
