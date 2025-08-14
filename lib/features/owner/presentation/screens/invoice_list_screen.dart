import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load invoices')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    final List<Map<String, dynamic>> base = _selectedFilter == 'all'
        ? _invoices
        : _invoices
              .where(
                (invoice) =>
                    (invoice['status'] ?? '').toString().toLowerCase() ==
                    _selectedFilter,
              )
              .toList();

    final q = _searchQuery.trim().toLowerCase();
    List<Map<String, dynamic>> result;
    if (q.isEmpty) {
      result = List<Map<String, dynamic>>.from(base);
    } else {
      bool match(Map<String, dynamic> inv) {
        final name =
            (inv['tenant_name'] ??
                    (inv['tenant'] is Map ? inv['tenant']['name'] : null) ??
                    (inv['tenant'] is Map
                        ? inv['tenant']['full_name']
                        : null) ??
                    '')
                .toString()
                .toLowerCase();
        final invNo =
            (inv['invoice_number'] ?? inv['number'] ?? inv['invoiceNo'] ?? '')
                .toString()
                .toLowerCase();
        return name.contains(q) || invNo.contains(q);
      }

      result = base.where(match).toList();
    }

    // Sort to show unpaid first, then partial/due, then others, then paid last
    result.sort((a, b) {
      final pa = _statusPriority(a['status']);
      final pb = _statusPriority(b['status']);
      if (pa != pb) return pa.compareTo(pb);
      // Optional tie-breaker: newer due_date first if available
      final ad = (a['due_date'] ?? '').toString();
      final bd = (b['due_date'] ?? '').toString();
      return bd.compareTo(ad);
    });

    return result;
  }

  int _statusPriority(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    if (s == 'unpaid') return 0;
    if (s == 'partial' || s == 'due') return 1;
    if (s == 'pending') return 2;
    if (s == 'paid') return 3;
    return 4;
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildFilterButton('all', 'All')),
                const SizedBox(width: 6),
                Expanded(child: _buildFilterButton('unpaid', 'Unpaid')),
                const SizedBox(width: 6),
                Expanded(child: _buildFilterButton('paid', 'Paid')),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                  if (!mounted) return;
                  setState(() => _searchQuery = value);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or invoice #',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Invoice List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        final String tenantName =
                            (invoice['tenant_name'] ??
                                    (invoice['tenant'] is Map
                                        ? invoice['tenant']['name']
                                        : null) ??
                                    (invoice['tenant'] is Map
                                        ? invoice['tenant']['full_name']
                                        : null) ??
                                    '—')
                                .toString();
                        final String unitName =
                            (invoice['unit_name'] ??
                                    (invoice['unit'] is Map
                                        ? invoice['unit']['name']
                                        : null) ??
                                    invoice['unit_no'] ??
                                    '—')
                                .toString();
                        final String invoiceNo =
                            (invoice['invoice_number'] ??
                                    invoice['number'] ??
                                    invoice['invoiceNo'] ??
                                    'N/A')
                                .toString();
                        final String amountStr =
                            (invoice['amount'] ??
                                    invoice['net_amount'] ??
                                    invoice['total'] ??
                                    invoice['amount_due'] ??
                                    '0')
                                .toString();
                        final String dateStr = _formatDate(invoice['due_date']);
                        final String invoiceType =
                            (invoice['invoice_type'] ?? invoice['type'] ?? '')
                                .toString()
                                .trim();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              context.push('/invoice-payment', extra: invoice);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row 1: Name | Unit (left) | Status (right)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$tenantName | $unitName',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.text,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            invoice['status'],
                                          ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(invoice['status']),
                                          style: TextStyle(
                                            color: _getStatusColor(
                                              invoice['status'],
                                            ),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Row 2: Invoice # - Type (left) | Amount (right)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '#$invoiceNo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.gray,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (invoiceType.isNotEmpty) ...[
                                                const TextSpan(text: '  '),
                                                TextSpan(
                                                  text:
                                                      invoiceType[0]
                                                          .toUpperCase() +
                                                      invoiceType.substring(1),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: _getTypeColor(
                                                      invoiceType,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '৳$amountStr',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                            invoice['status'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
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

  Color _getStatusColor(String? status) {
    switch ((status ?? '').toString().toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'due':
      case 'partial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch ((status ?? '').toString().toLowerCase()) {
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'rent':
        return Colors.blue;
      case 'advance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        // Expecting formats like '2025-08-14 12:34:00'
        final parts = date.split(' ');
        return parts.isNotEmpty ? parts.first : date;
      }
      return date.toString();
    } catch (_) {
      return 'N/A';
    }
  }

  void _showPaymentOptions(Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            Text(
              'Invoice #${invoice['invoice_number'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ৳${invoice['amount'] ?? '0'}',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
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
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text('Make Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                    label: const Text('View PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
