import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/features/tenant/presentation/screens/invoice_pdf_screen.dart';
import 'package:hrms_app/features/tenant/presentation/screens/invoice_payment_screen.dart';
import 'package:hrms_app/features/tenant/presentation/widgets/tenant_bottom_nav.dart';

class TenantBillingScreen extends StatefulWidget {
  const TenantBillingScreen({super.key});

  @override
  _TenantBillingScreenState createState() => _TenantBillingScreenState();
}

class _TenantBillingScreenState extends State<TenantBillingScreen> {
  bool _isLoading = true;
  List<dynamic> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await AuthService.getToken();
      print('DEBUG: Token: $token');
      print('DEBUG: Token length: ${token?.length}');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Get user info for debugging
      final userInfo = await AuthService.getUserInfo();
      print('DEBUG: User Info: $userInfo');

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/tenant/invoices')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('DEBUG: API URL: ${ApiConfig.getApiUrl('/tenant/invoices')}');
      print('DEBUG: Response Status: ${response.statusCode}');
      print('DEBUG: Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: API Response: $data');
        print('DEBUG: Invoices count: ${data['invoices']?.length ?? 0}');

        if (data['invoices'] != null) {
          for (int i = 0; i < data['invoices'].length; i++) {
            final invoice = data['invoices'][i];
            print(
              'DEBUG: Invoice $i - ID: ${invoice['id']}, Status: ${invoice['status']}, Amount: ${invoice['amount']}',
            );
          }
        }

        setState(() {
          _invoices = data['invoices'] ?? [];
          _isLoading = false;
        });
      } else {
        print(
          'DEBUG: API Error - Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('Failed to load invoices');
      }
    } catch (e) {
      print('DEBUG: Exception: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load invoices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bills'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadInvoices),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInvoices,
              child: _invoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No invoices found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your bills will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _invoices[index];
                        return _buildInvoiceCard(invoice);
                      },
                    ),
            ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    print(
      'DEBUG: Building invoice card - ID: ${invoice['id']}, Status: ${invoice['status']}',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: invoice['status'] == 'paid'
              ? Colors.green.withOpacity(0.1)
              : Colors.white,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: invoice['status'] == 'paid'
                  ? Colors.green
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt, color: Colors.white, size: 24),
          ),
          title: Text(
            'Invoice #${invoice['id']}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text('Amount: \$${invoice['amount']}'),
              Text('Date: ${invoice['created_at']}'),
            ],
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: invoice['status'] == 'paid' ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              invoice['status'] ?? 'Unknown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () {
            _showInvoiceOptions(invoice);
          },
        ),
      ),
    );
  }

  void _showInvoiceOptions(Map<String, dynamic> invoice) {
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
              'Invoice #${invoice['id']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.picture_as_pdf,
                    label: 'View PDF',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _viewInvoicePDF(invoice);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.payment,
                    label: 'Make Payment',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(context);
                      _makePayment(invoice);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.share,
                    label: 'Share',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      _shareInvoice(invoice);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.download,
                    label: 'Download',
                    color: AppColors.primaryDark,
                    onTap: () {
                      Navigator.pop(context);
                      _downloadInvoice(invoice);
                    },
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

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewInvoicePDF(Map<String, dynamic> invoice) {
    // Navigate to PDF viewer using the same function as owner
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePdfScreen(
          invoiceId: invoice['id'],
          invoiceNumber:
              invoice['invoice_number'] ?? 'Invoice #${invoice['id']}',
        ),
      ),
    );
  }

  void _makePayment(Map<String, dynamic> invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePaymentScreen(
          amount: double.tryParse(invoice['amount']?.toString() ?? '0') ?? 0.0,
          invoiceId: invoice['id']?.toString() ?? '',
          invoiceNumber: invoice['invoice_number']?.toString() ?? '',
        ),
      ),
    );
  }

  void _shareInvoice(Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Share feature coming soon!')));
  }

  void _downloadInvoice(Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Download feature coming soon!')));
  }
}
