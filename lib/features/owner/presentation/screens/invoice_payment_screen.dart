import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/owner/presentation/screens/invoice_pdf_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';

class InvoicePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const InvoicePaymentScreen({super.key, required this.invoice});

  @override
  _InvoicePaymentScreenState createState() => _InvoicePaymentScreenState();
}

class _InvoicePaymentScreenState extends State<InvoicePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;
  bool _isFullPayment = true;

  @override
  void initState() {
    super.initState();
    print('=== INVOICE PAYMENT SCREEN INIT ===');
    print('Invoice data: ${widget.invoice}');
    print('Invoice ID: ${widget.invoice['id']}');
    print('Invoice amount: ${widget.invoice['amount']}');
    print('Invoice status: ${widget.invoice['status']}');

    final invoiceAmountRaw = widget.invoice['amount'];
    final invoiceAmount = invoiceAmountRaw is String
        ? invoiceAmountRaw
        : (invoiceAmountRaw is num ? invoiceAmountRaw.toString() : '0');

    _amountController.text = invoiceAmount;
    print('Amount controller set to: ${_amountController.text}');
  }

  @override
  Widget build(BuildContext context) {
    print('=== BUILDING INVOICE PAYMENT SCREEN ===');
    print(
      'Current state: _isLoading=$_isLoading, _selectedPaymentMethod=$_selectedPaymentMethod',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: Text('Invoice Payment', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/billing');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_buildAllInOneSection(), SizedBox(height: 80)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _downloadPdf,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  minimumSize: Size(double.infinity, 56),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Download PDF'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _isInvoicePaid()
                  ? SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Already Paid'),
                      ),
                    )
                  : _buildSubmitButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    final invoiceNo = (widget.invoice['invoice_number'] ?? 'N/A').toString();
    final type =
        (widget.invoice['invoice_type'] ?? widget.invoice['type'] ?? '')
            .toString();
    final tenant = (widget.invoice['tenant_name'] ?? 'N/A').toString();
    final unit = (widget.invoice['unit_name'] ?? 'N/A').toString();
    final status = (widget.invoice['status'] ?? '').toString();
    final amount = (widget.invoice['amount'] ?? '0').toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#$invoiceNo - ${type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : 'Invoice'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$tenant | $unit',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '৳$amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  Color _getStatusColor(String? status) {
    switch ((status ?? '').toString().toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'partial':
      case 'due':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  double _parseAmount(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  double _getInvoiceTotal() {
    final total = _parseAmount(widget.invoice['amount']);
    if (total > 0) return total;
    final breakdown = widget.invoice['breakdown'];
    if (breakdown is List) {
      double sum = 0;
      for (final item in breakdown) {
        final amt = _parseAmount(item is Map ? item['amount'] : null);
        sum += amt;
      }
      return sum;
    }
    return 0.0;
  }

  Widget _buildInvoiceMetaTable() {
    final invoiceNo = (widget.invoice['invoice_number'] ?? 'N/A').toString();
    final tenant = (widget.invoice['tenant_name'] ?? 'N/A').toString();
    final unit = (widget.invoice['unit_name'] ?? 'N/A').toString();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            _kvRow('Invoice no:', '#$invoiceNo'),
            Divider(height: 10),
            _kvRow('Name:', tenant),
            Divider(height: 10),
            _kvRow('Unit:', unit),
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFeesTable() {
    final breakdown = widget.invoice['breakdown'];
    if (breakdown is! List || breakdown.isEmpty) return SizedBox.shrink();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fees details',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ...breakdown.map<Widget>((fee) {
              final name = (fee['name'] ?? 'Fee').toString();
              final amt = _parseAmount(fee['amount']).toStringAsFixed(2);
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '৳$amt',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsAndPaymentSection() {
    final total = _getInvoiceTotal();
    final paid = _parseAmount(_amountController.text);
    final due = (total - paid).clamp(0, double.infinity);
    final isPartial = due > 0 && paid > 0;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kvRow('Total:', '৳${total.toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text(
              'Paid Amount:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter amount to pay',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              validator: (v) {
                final val = _parseAmount(v);
                if (val <= 0) return 'Enter a valid amount';
                if (val > total) return 'Amount cannot exceed total';
                return null;
              },
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Due:', style: TextStyle(color: AppColors.textSecondary)),
                Row(
                  children: [
                    Text(
                      '৳${due.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: due > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                    if (isPartial) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Partial',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Payment Method
            Text(
              'Payment Method:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Bank Transfer'),
                ),
                DropdownMenuItem(
                  value: 'mobile_banking',
                  child: Text('Mobile Banking'),
                ),
                DropdownMenuItem(value: 'check', child: Text('Check')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) =>
                  setState(() => _selectedPaymentMethod = v ?? 'cash'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllInOneSection() {
    final total = _getInvoiceTotal();
    final paid = _parseAmount(_amountController.text);
    final due = (total - paid).clamp(0, double.infinity);
    final isPartial = due > 0 && paid > 0;
    final invoiceNo = (widget.invoice['invoice_number'] ?? 'N/A').toString();
    final tenant = (widget.invoice['tenant_name'] ?? 'N/A').toString();
    final unit = (widget.invoice['unit_name'] ?? 'N/A').toString();
    final breakdown = widget.invoice['breakdown'];
    final String gatewayRaw =
        (widget.invoice['payment_gateway'] ??
                widget.invoice['payment_method'] ??
                widget.invoice['gateway'] ??
                widget.invoice['method'] ??
                '')
            .toString();
    final String gateway = _prettyGatewayName(gatewayRaw);
    final String txDate = _formatDate(
      widget.invoice['payment_date'] ??
          widget.invoice['paid_date'] ??
          widget.invoice['paid_at'] ??
          widget.invoice['issue_date'],
    );
    final status = (widget.invoice['status'] ?? '').toString();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment status badge
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(status).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            // Meta rows
            _kvRow('Invoice no:', '#$invoiceNo'),
            SizedBox(height: 8),
            _kvRow('Name:', tenant),
            SizedBox(height: 8),
            _kvRow('Unit:', unit),
            SizedBox(height: 8),
            _kvRow('Transaction Date:', txDate.isNotEmpty ? txDate : 'N/A'),
            SizedBox(height: 8),
            _kvRow('Gateway:', gateway.isNotEmpty ? gateway : 'N/A'),

            // Fees table (optional)
            if (breakdown is List && breakdown.isNotEmpty) ...[
              SizedBox(height: 12),
              Divider(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fees details',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),

              Divider(height: 12),
              ...breakdown.map<Widget>((fee) {
                final name = (fee['name'] ?? 'Fee').toString();
                final amt = _parseAmount(fee['amount']).toStringAsFixed(2);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(color: AppColors.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '৳$amt',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Totals & payment fields
            //r SizedBox(height: 4),
            Divider(height: 12),
            _kvRow('Total:', '৳${total.toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text(
              'Paid Amount:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter amount to pay',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              validator: (v) {
                final val = _parseAmount(v);
                if (val <= 0) return 'Enter a valid amount';
                if (val > total) return 'Amount cannot exceed total';
                return null;
              },
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Due:', style: TextStyle(color: AppColors.textSecondary)),
                Row(
                  children: [
                    Text(
                      '৳${due.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: due > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                    if (isPartial) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Partial',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),
            Text(
              'Payment Method:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Bank Transfer'),
                ),
                DropdownMenuItem(
                  value: 'mobile_banking',
                  child: Text('Mobile Banking'),
                ),
                DropdownMenuItem(value: 'check', child: Text('Check')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) =>
                  setState(() => _selectedPaymentMethod = v ?? 'cash'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
            ),

            SizedBox(height: 12),
            // Reference & Notes
            Text(
              'Reference/Transaction ID',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 6),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: 'e.g. TXN12345',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text('Note', style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Optional',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyGatewayName(String raw) {
    final s = raw.toLowerCase();
    switch (s) {
      case 'cash':
        return 'Cash';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'mobile_banking':
        return 'Mobile Banking';
      case 'bkash':
        return 'bKash';
      case 'nagad':
        return 'Nagad';
      case 'card':
        return 'Card';
      case 'check':
        return 'Check';
      case 'other':
        return 'Other';
      default:
        return raw;
    }
  }

  Widget _buildInvoiceSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(widget.invoice['status']),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildSummaryRow(
              'Invoice Number',
              '#${widget.invoice['invoice_number'] ?? 'N/A'}',
            ),
            _buildSummaryRow('Tenant', widget.invoice['tenant_name'] ?? 'N/A'),
            _buildSummaryRow(
              'Property',
              widget.invoice['property_name'] ?? 'N/A',
            ),
            _buildSummaryRow('Unit', widget.invoice['unit_name'] ?? 'N/A'),
            _buildSummaryRow(
              'Issue Date',
              _formatDate(widget.invoice['issue_date']),
            ),
            _buildSummaryRow(
              'Due Date',
              _formatDate(widget.invoice['due_date']),
            ),

            // Fees breakdown
            if (widget.invoice['breakdown'] != null &&
                (widget.invoice['breakdown'] as List).isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Invoice Breakdown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(widget.invoice['breakdown'] as List).length} items',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...(widget.invoice['breakdown'] as List).map<Widget>((fee) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    fee['name'] ?? 'Fee',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '৳${fee['amount'] ?? '0'}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (fee['description'] != null &&
                                fee['description'].toString().isNotEmpty) ...[
                              SizedBox(height: 6),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        fee['description'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            Divider(color: Colors.white.withOpacity(0.3), height: 24),
            _buildSummaryRow(
              'Total Amount',
              '৳${widget.invoice['amount'] ?? '0'}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAmountSection() {
    print('Building payment amount section');
    print('_isFullPayment: $_isFullPayment');
    print('Amount controller text: ${_amountController.text}');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Full Payment'),
                    value: true,
                    groupValue: _isFullPayment,
                    onChanged: (value) {
                      print('Full payment selected: $value');
                      setState(() {
                        _isFullPayment = value!;
                        final invoiceAmountRaw = widget.invoice['amount'];
                        final invoiceAmount = invoiceAmountRaw is String
                            ? invoiceAmountRaw
                            : (invoiceAmountRaw is num
                                  ? invoiceAmountRaw.toString()
                                  : '0');
                        _amountController.text = invoiceAmount;
                      });
                      print(
                        'Amount controller updated to: ${_amountController.text}',
                      );
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Partial Payment'),
                    value: false,
                    groupValue: _isFullPayment,
                    onChanged: (value) {
                      print('Partial payment selected: $value');
                      setState(() {
                        _isFullPayment = value!;
                        _amountController.text = '';
                      });
                      print('Amount controller cleared');
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (BDT)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: 'BDT',
              ),
              validator: (value) {
                print('Validating amount: $value');
                if (value == null || value.isEmpty) {
                  print('Amount is empty');
                  return 'Amount is required';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  print('Invalid amount: $amount');
                  return 'Please enter a valid amount';
                }
                final invoiceAmountRaw = widget.invoice['amount'];
                final invoiceAmount = invoiceAmountRaw is String
                    ? double.tryParse(invoiceAmountRaw) ?? 0.0
                    : (invoiceAmountRaw is num
                          ? invoiceAmountRaw.toDouble()
                          : 0.0);

                print('Invoice amount (raw): $invoiceAmountRaw');
                print('Invoice amount (parsed): $invoiceAmount');

                if (amount > invoiceAmount) {
                  print(
                    'Amount exceeds invoice total: $amount > $invoiceAmount',
                  );
                  return 'Amount cannot exceed invoice total';
                }
                print('Amount validation passed: $amount');
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            _buildPaymentMethodOption('cash', 'Cash'),
            _buildPaymentMethodOption('bank_transfer', 'Bank Transfer'),
            _buildPaymentMethodOption('mobile_banking', 'Mobile Banking'),
            _buildPaymentMethodOption('check', 'Check'),
            _buildPaymentMethodOption('other', 'Other'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (newValue) {
        print('Payment method changed to: $newValue');
        setState(() {
          _selectedPaymentMethod = newValue!;
        });
        print('Selected payment method: $_selectedPaymentMethod');
      },
      activeColor: AppColors.primary,
    );
  }

  Widget _buildReferenceSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reference & Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Reference Number (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Transaction ID, Check Number, etc.',
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Additional notes about this payment...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    print('Building submit button - _isLoading: $_isLoading');

    return Container(
      width: double.infinity,
      height: 56,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: () {
          print('=== PAYMENT BUTTON TAPPED ===');
          print('Button state: _isLoading = $_isLoading');
          print('Form key: ${_formKey.currentState}');
          print('Amount controller: ${_amountController.text}');
          print('Payment method: $_selectedPaymentMethod');

          if (_isLoading) {
            print('Button is in loading state, ignoring tap');
            return;
          }

          _submitPayment();
        },
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pay Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    print('_submitPayment called');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    print('Form validation passed');
    setState(() => _isLoading = true);

    try {
      String? token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      print('=== API CALL DETAILS ===');
      print('Invoice ID: ${widget.invoice['id']}');
      print('Invoice amount: ${widget.invoice['amount']}');
      print('Payment amount: ${_amountController.text}');
      print('Payment method: $_selectedPaymentMethod');
      print('Reference: ${_referenceController.text}');
      print('Notes: ${_notesController.text}');
      print(
        'API URL: ${ApiConfig.getApiUrl('/invoices/${widget.invoice['id']}/pay')}',
      );

      final requestBody = {
        'amount': double.parse(_amountController.text),
        'payment_method': _selectedPaymentMethod,
        'reference_number': _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      };

      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse(ApiConfig.getApiUrl('/invoices/${widget.invoice['id']}/pay')),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('=== API RESPONSE ===');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      print('Response length: ${response.body.length}');

      print('=== RESPONSE ANALYSIS ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          print('Success response data: $data');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment processed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true); // Return true to refresh invoice list
        } catch (e) {
          print('JSON decode error: $e');
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 422) {
        try {
          final errorData = json.decode(response.body);
          print('Validation error data: $errorData');

          final errors = errorData['errors'] ?? {};
          String errorMessage = 'Validation failed:\n';
          errors.forEach((key, value) {
            if (value is List) {
              errorMessage += '${value.first}\n';
            }
          });
          throw Exception(errorMessage);
        } catch (e) {
          print('Error parsing validation response: $e');
          throw Exception('Validation failed');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          print('Error response data: $errorData');

          final message =
              errorData['message'] ??
              errorData['error'] ??
              'Payment failed with status ${response.statusCode}';
          throw Exception(message);
        } catch (e) {
          print('Error parsing error response: $e');
          throw Exception('Payment failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      print('=== PAYMENT ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Error stack trace: ${e.toString()}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      print('=== PAYMENT PROCESS COMPLETED ===');
      setState(() => _isLoading = false);
      print('Loading state set to false');
    }
  }

  bool _isInvoicePaid() {
    final status = (widget.invoice['status'] ?? '').toString().toLowerCase();
    return status == 'paid';
  }

  Future<void> _downloadPdf() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Opening PDF...')));
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InvoicePdfScreen(
            invoiceId: (widget.invoice['id'] as num).toInt(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
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
        return date.split(' ')[0];
      }
      return date.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentMethodController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
