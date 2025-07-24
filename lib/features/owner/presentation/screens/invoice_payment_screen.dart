import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';

class InvoicePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const InvoicePaymentScreen({Key? key, required this.invoice})
    : super(key: key);

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
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/dashboard'),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, color: AppColors.primary),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Invoice #${widget.invoice['invoice_number'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Invoice Summary Card
                      _buildInvoiceSummaryCard(),
                      SizedBox(height: 24),

                      // Payment Amount Section
                      _buildPaymentAmountSection(),
                      SizedBox(height: 24),

                      // Payment Method Section
                      _buildPaymentMethodSection(),
                      SizedBox(height: 24),

                      // Reference & Notes Section
                      _buildReferenceSection(),
                      SizedBox(height: 32),

                      // Submit Button
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return; // Already on billing
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/properties');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/units');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/tenants');
              break;
          }
        },
      ),
    );
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
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 Fees Breakdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...(widget.invoice['breakdown'] as List).map<Widget>((fee) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '• ${fee['name'] ?? 'Fee'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '৳${fee['amount'] ?? '0'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
            Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Payment Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
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
                prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
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
            Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildPaymentMethodOption('cash', 'Cash', Icons.money),
            _buildPaymentMethodOption(
              'bank_transfer',
              'Bank Transfer',
              Icons.account_balance,
            ),
            _buildPaymentMethodOption(
              'mobile_banking',
              'Mobile Banking',
              Icons.phone_android,
            ),
            _buildPaymentMethodOption('check', 'Check', Icons.receipt),
            _buildPaymentMethodOption('other', 'Other', Icons.more_horiz),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(width: 12),
          Text(label),
        ],
      ),
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
            Row(
              children: [
                Icon(Icons.note, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Reference & Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Reference Number (Optional)',
                prefixIcon: Icon(Icons.receipt, color: AppColors.primary),
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
                prefixIcon: Icon(Icons.note, color: AppColors.primary),
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
                  Icon(Icons.payment, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Process Payment',
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
