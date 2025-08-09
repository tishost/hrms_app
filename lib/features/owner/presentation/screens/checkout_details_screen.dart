import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/utils/api_config.dart';
import '../../../auth/data/services/auth_service.dart';

class CheckoutDetailsScreen extends StatefulWidget {
  final String checkoutId;

  const CheckoutDetailsScreen({super.key, required this.checkoutId});

  @override
  State<CheckoutDetailsScreen> createState() => _CheckoutDetailsScreenState();
}

class _CheckoutDetailsScreenState extends State<CheckoutDetailsScreen> {
  Map<String, dynamic>? _checkoutData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCheckoutDetails();
  }

  Future<void> _loadCheckoutDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/checkouts/${widget.checkoutId}')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Checkout details API response: $data');
        setState(() {
          _checkoutData = data['checkout'];
          _isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load checkout details: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '৳0';
    final numAmount = double.tryParse(amount.toString()) ?? 0;
    return '৳${numAmount.toStringAsFixed(2)}';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout Details'),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/checkouts');
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[600]!, Colors.blue[50]!],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading checkout details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCheckoutDetails,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            : _checkoutData == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Checkout not found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The requested checkout record could not be found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: Colors.blue[600],
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Checkout #${_checkoutData!['id']}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Checkout Date: ${_formatDate(_checkoutData!['checkout_date'])}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Tenant Information
                    _buildInfoCard('Tenant Information', Icons.person, [
                      _buildInfoRow(
                        'Name',
                        _checkoutData!['tenant_name'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Property',
                        _checkoutData!['property_name'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Unit',
                        _checkoutData!['unit_name'] ?? 'N/A',
                      ),
                    ]),
                    SizedBox(height: 16),

                    // Settlement Information
                    _buildInfoCard(
                      'Settlement Details',
                      Icons.account_balance_wallet,
                      [
                        _buildInfoRowWithDescription(
                          'Security Deposit Return',
                          _formatAmount(_checkoutData!['security_deposit']),
                          'Original deposit amount to be returned',
                        ),
                        _buildInfoRowWithDescription(
                          'Outstanding Dues Deduction',
                          '-${_formatAmount(_checkoutData!['outstanding_dues'])}',
                          'Unpaid rent and invoice amounts',
                        ),
                        _buildInfoRowWithDescription(
                          'Utility Bills Deduction',
                          '-${_formatAmount(_checkoutData!['utility_bills'])}',
                          'Pending utility charges (electricity, water, gas)',
                        ),
                        _buildInfoRowWithDescription(
                          'Cleaning Charges Deduction',
                          '-${_formatAmount(_checkoutData!['cleaning_charges'])}',
                          'Unit cleaning and maintenance costs',
                        ),
                        _buildInfoRowWithDescription(
                          'Other Charges Deduction',
                          '-${_formatAmount(_checkoutData!['other_charges'])}',
                          'Additional charges (damages, late fees)',
                        ),
                        Divider(height: 20),
                        _buildInfoRowWithDescription(
                          'Final Settlement Amount',
                          _formatAmount(
                            _checkoutData!['final_settlement_amount'],
                          ),
                          _checkoutData!['final_settlement_amount'] >= 0
                              ? 'Amount to be paid to tenant'
                              : 'Amount tenant owes to owner',
                          isTotal: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Additional Information
                    _buildInfoCard(
                      'Additional Information',
                      Icons.info_outline,
                      [
                        _buildInfoRow(
                          'Checkout Reason',
                          _checkoutData!['checkout_reason'] ?? 'N/A',
                        ),
                        _buildInfoRow(
                          'Handover Date',
                          _formatDate(_checkoutData!['handover_date']),
                        ),
                        _buildInfoRow(
                          'Property Condition',
                          _checkoutData!['property_condition'] ?? 'N/A',
                        ),
                        _buildInfoRow(
                          'Additional Note',
                          _checkoutData!['additional_note'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
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
                Icon(icon, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithDescription(
    String label,
    String value,
    String description, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    color: isTotal ? Colors.blue[600] : Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isTotal ? 16 : 14,
                    color: isTotal ? Colors.blue[600] : Colors.black87,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: 120),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
