import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantRentAgreementScreen extends ConsumerStatefulWidget {
  const TenantRentAgreementScreen({super.key});

  @override
  _TenantRentAgreementScreenState createState() =>
      _TenantRentAgreementScreenState();
}

class _TenantRentAgreementScreenState
    extends ConsumerState<TenantRentAgreementScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _rentDetails;
  Map<String, dynamic>? _agreementDetails;

  @override
  void initState() {
    super.initState();
    _loadRentAgreementData();
  }

  Future<void> _loadRentAgreementData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final apiService = ref.read(apiServiceProvider);

      // Load rent details and agreement data
      final response = await apiService.get('/tenant/rent-agreement');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        setState(() {
          _rentDetails = data['rent_details'];
          _agreementDetails = data['agreement_details'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load rent agreement data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading rent agreement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Rent Agreement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tenant/dashboard');
            }
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadRentAgreementData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRentDetailsCard(),
                    SizedBox(height: 16),
                    _buildFeesCard(),
                    SizedBox(height: 16),
                    _buildAgreementDetailsCard(),
                    SizedBox(height: 16),
                    _buildPaymentHistoryCard(),
                    SizedBox(height: 16),
                    _buildTermsAndConditionsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRentDetailsCard() {
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
                Icon(
                  Icons.attach_money_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Rent Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              'Monthly Rent',
              _rentDetails?['monthly_rent'] ?? 'N/A',
            ),
            _buildDetailRow(
              'Payment Method',
              _rentDetails?['payment_method'] ?? 'N/A',
            ),
            SizedBox(height: 8),
            Divider(height: 1, thickness: 1),
            SizedBox(height: 8),
            _buildDetailRow(
              'Total Monthly Amount',
              _rentDetails?['total_monthly_amount'] ?? 'N/A',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeesCard() {
    final fees = _rentDetails?['fees'] ?? [];
    final totalFees = _rentDetails?['total_fees'] ?? 0.0;

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
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Monthly Fees & Charges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (fees.isEmpty)
              Center(
                child: Text(
                  'No additional fees',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              Column(
                children: [
                  ...fees
                      .map<Widget>(
                        (fee) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  fee['name'] ?? 'Unknown Fee',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  fee['amount']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  Divider(height: 24, thickness: 1),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Total Fees',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          totalFees.toString(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementDetailsCard() {
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
                Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Agreement Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              'Agreement Number',
              _agreementDetails?['agreement_number'] ?? 'N/A',
            ),
            _buildDetailRow(
              'Start Date',
              _agreementDetails?['start_date'] ?? 'N/A',
            ),
            _buildDetailRow(
              'End Date',
              _agreementDetails?['end_date'] ?? 'N/A',
            ),
            _buildDetailRow(
              'Duration',
              _agreementDetails?['duration'] ?? 'N/A',
            ),
            _buildDetailRow('Status', _agreementDetails?['status'] ?? 'N/A'),
            _buildDetailRow(
              'Property',
              _agreementDetails?['property_name'] ?? 'N/A',
            ),
            _buildDetailRow('Unit', _agreementDetails?['unit_name'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    final payments = _rentDetails?['payment_history'] ?? [];

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
                Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 12),
                Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (payments.isEmpty)
              Center(
                child: Text(
                  'No payment history available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: payment['status'] == 'paid'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        payment['status'] == 'paid'
                            ? Icons.check_circle
                            : Icons.pending,
                        color: payment['status'] == 'paid'
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      payment['month'] ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    subtitle: Text(
                      payment['date'] ?? 'N/A',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      payment['amount'] ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditionsCard() {
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
                Icon(Icons.rule_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 12),
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              _agreementDetails?['terms_conditions'] ??
                  'No terms and conditions available.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.download_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // TODO: Implement PDF download
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDF download coming soon!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: Text(
                    'Download Agreement PDF',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? AppColors.primary : AppColors.textSecondary,
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isTotal ? AppColors.primary : AppColors.text,
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
