import 'package:flutter/material.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvoicePaymentScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final double amount;

  const InvoicePaymentScreen({
    Key? key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
  }) : super(key: key);

  @override
  _InvoicePaymentScreenState createState() => _InvoicePaymentScreenState();
}

class _InvoicePaymentScreenState extends State<InvoicePaymentScreen> {
  bool _isLoading = false;
  String _selectedPaymentMethod = 'cash';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment - Invoice #${widget.invoiceNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Summary
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Invoice Number:',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            widget.invoiceNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount Due:',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            '\$${widget.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Payment Method Selection
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 12),

              // Cash Payment Option
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.money, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Cash Payment'),
                  ],
                ),
                subtitle: Text('Pay with cash to property manager'),
                value: 'cash',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: AppColors.primary,
              ),

              // Bank Transfer Option
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.account_balance, color: AppColors.info),
                    SizedBox(width: 8),
                    Text('Bank Transfer'),
                  ],
                ),
                subtitle: Text('Transfer to bank account'),
                value: 'bank',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: AppColors.primary,
              ),

              // Mobile Banking Option
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.phone_android, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('Mobile Banking'),
                  ],
                ),
                subtitle: Text('Pay via mobile banking apps'),
                value: 'mobile',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: AppColors.primary,
              ),

              Spacer(),

              // Payment Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Confirm Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.getApiUrl('/invoices/${widget.invoiceId}/payment')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'payment_method': _selectedPaymentMethod,
          'amount': widget.amount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment processed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Payment failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
