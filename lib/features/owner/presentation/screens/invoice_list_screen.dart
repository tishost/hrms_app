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
  const InvoiceListScreen({super.key});

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
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: Text(
          'Invoices',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: _fetchInvoices,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Filter Buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildFilterButton('all', 'All')),
                SizedBox(width: 6),
                Expanded(child: _buildFilterButton('unpaid', 'Unpaid')),
                SizedBox(width: 6),
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
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showPaymentOptions(invoice),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _getInvoiceTypeColor(
                                          invoice['invoice_type'],
                                        ),
                                        child: Icon(
                                          _getInvoiceTypeIcon(
                                            invoice['invoice_type'],
                                          ),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              invoice['description'] ??
                                                  'Invoice',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '👤 ${invoice['tenant_name'] ?? 'N/A'}',
                                              style: TextStyle(fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${invoice['amount'] ?? '0'} BDT',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                invoice['status'],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusText(invoice['status']),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  // Details Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '🏠 ${invoice['unit_name'] ?? 'N/A'}',
                                          style: TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '📅 ${_formatDate(invoice['due_date'])}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  // Fees breakdown (expanded)
                                  if (invoice['breakdown'] != null &&
                                      (invoice['breakdown'] as List)
                                          .isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.receipt_long,
                                                size: 16,
                                                color: AppColors.primary,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Invoice Breakdown',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              Spacer(),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${(invoice['breakdown'] as List).length} items',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          // Show all breakdown items
                                          ...(invoice['breakdown'] as List).map<
                                            Widget
                                          >((fee) {
                                            return Container(
                                              margin: EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.grey
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          fee['name'] ?? 'Fee',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        if (fee['description'] !=
                                                                null &&
                                                            fee['description']
                                                                .toString()
                                                                .isNotEmpty) ...[
                                                          SizedBox(height: 4),
                                                          Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.blue
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                              border: Border.all(
                                                                color: Colors
                                                                    .blue
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .info_outline,
                                                                  color: AppColors
                                                                      .primary,
                                                                  size: 12,
                                                                ),
                                                                SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    fee['description'],
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          9,
                                                                      color: Colors
                                                                          .grey[700],
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .italic,
                                                                    ),
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    '৳${fee['amount'] ?? '0'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
        padding: EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
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
      case 'due':
        return Colors.orange;
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
      case 'due':
        return 'Due';
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
                          builder: (context) =>
                              InvoicePdfScreen(invoiceId: invoice['id']),
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
