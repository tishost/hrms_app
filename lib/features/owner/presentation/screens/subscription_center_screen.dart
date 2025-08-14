import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SubscriptionCenterScreen extends ConsumerStatefulWidget {
  const SubscriptionCenterScreen({super.key});

  @override
  ConsumerState<SubscriptionCenterScreen> createState() =>
      _SubscriptionCenterScreenState();
}

class _SubscriptionCenterScreenState
    extends ConsumerState<SubscriptionCenterScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _current;
  Map<String, dynamic>? _rawSubscriptionData; // Store raw subscription data
  List<Map<String, dynamic>> _invoices = [];

  // Helpers to render plan resource limits in cards
  Map<String, dynamic>? _getPlanDataForDisplay() {
    // Prefer active subscription's embedded plan
    if (_current != null) {
      final planField = _current!['plan'];
      if (planField is Map<String, dynamic>) {
        return planField;
      }
      return _current;
    }
    // Fallback: raw subscription data (pending)
    if (_rawSubscriptionData != null) {
      final planField = _rawSubscriptionData!['plan'];
      if (planField is Map<String, dynamic>) {
        return planField;
      }
      return _rawSubscriptionData;
    }
    return null;
  }

  String _formatLimit(dynamic value) {
    if (value == null) return '—';
    if (value is num) {
      if (value < 0) return 'Unlimited';
      return value.toInt().toString();
    }
    // Try parse
    final parsed = int.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return parsed < 0 ? 'Unlimited' : parsed.toString();
  }

  // Removed old chip helper

  // Old pill helper removed

  String _formatCompact(dynamic value) {
    final s = _formatLimit(value);
    if (s == 'Unlimited') return '∞';
    if (s == '—') return '0';
    return s;
  }

  Widget _compactStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // removed older unused helpers

  String _validUntilWithDays(String? rawEndDate) {
    if (rawEndDate == null || rawEndDate.trim().isEmpty) return 'N/A';
    try {
      final end = DateTime.parse(rawEndDate).toLocal();
      final now = DateTime.now();
      int days = end.difference(now).inDays;
      if (days < 0) days = 0;
      final dateText = DateFormat('d MMM yyyy').format(end);
      return '$dateText (${days.toString()} Days)';
    } catch (_) {
      return rawEndDate;
    }
  }

  @override
  void initState() {
    super.initState();
    // ignore: avoid_print
    print('DEBUG: SubscriptionCenterScreen init');
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (e.g., after navigation)
    print('DEBUG: SubscriptionCenterScreen didChangeDependencies');
  }

  Future<void> _load() async {
    // ignore: avoid_print
    print('DEBUG: Loading subscription center data...');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final subRes = await api.get('/owner/subscription');
      print('DEBUG: Subscription API response: ${subRes.data}');
      print('DEBUG: Response keys: ${subRes.data.keys.toList()}');
      print('DEBUG: Success value: ${subRes.data['success']}');
      print('DEBUG: Subscription value: ${subRes.data['subscription']}');

      // Store raw subscription data for reference
      _rawSubscriptionData =
          subRes.data['subscription'] as Map<String, dynamic>?;

      // Check if subscription exists in response
      if (subRes.data['success'] == true &&
          subRes.data['subscription'] != null) {
        final subscription =
            subRes.data['subscription'] as Map<String, dynamic>?;

        // Check if subscription is active (paid and active)
        final status = subscription!['status']?.toString().toLowerCase();
        final isActive = status == 'active' || status == 'paid';

        if (isActive) {
          _current = subscription;
          print('DEBUG: Active subscription found: $_current');
          print('DEBUG: Subscription keys: ${_current!.keys.toList()}');
        } else {
          // Subscription exists but not active (pending/unpaid)
          _current = null;
          print(
            'DEBUG: Subscription found but not active. Status: $status, defaulting to Free plan',
          );
        }
      } else {
        _current = null;
        print('DEBUG: No subscription found, defaulting to Free plan');
        print('DEBUG: Response success: ${subRes.data['success']}');
        print('DEBUG: Response subscription: ${subRes.data['subscription']}');
      }

      try {
        final invRes = await api.get(ApiConfig.subscriptionInvoices);
        final list = (invRes.data['invoices'] as List).cast<dynamic>();
        _invoices = list
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
        print('DEBUG: Invoices loaded: ${_invoices.length}');
      } catch (e) {
        print('DEBUG: Failed to load invoices: $e');
        _invoices = [];
      }
      setState(() => _loading = false);
      // ignore: avoid_print
      print(
        'DEBUG: SubscriptionCenter loaded — invoices: ${_invoices.length}, hasCurrent: ${_current != null}',
      );
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: SubscriptionCenter load error: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
        // Set default values for free plan
        _current = null;
        _invoices = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('DEBUG: SubscriptionCenterScreen build()');
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/properties');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('DEBUG: Manual refresh triggered');
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Current Subscription - Modern Summary Card (logo removed)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_current == null)
                          // Free Plan - Minimal Summary Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.shadowLight,
                                          blurRadius: 14,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: const Text(
                                      'Free Plan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Resource summary compact: icons + qty (3 in first line)
                                Builder(
                                  builder: (_) {
                                    final plan = _getPlanDataForDisplay();
                                    final props = _formatCompact(
                                      plan?['properties_limit'],
                                    );
                                    final units = _formatCompact(
                                      plan?['units_limit'],
                                    );
                                    final smsCredit = _formatCompact(
                                      plan?['sms_credit'] ??
                                          plan?['sms_credits'],
                                    );
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _compactStat(
                                            icon: Icons.apartment_rounded,
                                            value: props,
                                            color: AppColors.indigo,
                                          ),
                                        ),
                                        Expanded(
                                          child: _compactStat(
                                            icon: Icons.meeting_room_rounded,
                                            value: units,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Expanded(
                                          child: _compactStat(
                                            icon: Icons.sms_rounded,
                                            value: smsCredit,
                                            color: AppColors.teal,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Second line: validity/renew info (Free = Lifetime)
                                Builder(
                                  builder: (_) {
                                    // Free plan
                                    return const Text(
                                      'Valid: Lifetime',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        context.go('/subscription-plans'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF7FA7F3),
                                      foregroundColor: AppColors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text('Upgrade'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Paid Plan - Minimal Summary Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.shadowLight,
                                          blurRadius: 14,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      _current!['plan_name'] ??
                                          _current!['plan']?['name'] ??
                                          'Premium Plan',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Resource summary compact: icons + qty (3 in first line)
                                Builder(
                                  builder: (_) {
                                    final plan = _getPlanDataForDisplay();
                                    final props = _formatCompact(
                                      plan?['properties_limit'],
                                    );
                                    final units = _formatCompact(
                                      plan?['units_limit'],
                                    );
                                    final smsCredit = _formatCompact(
                                      plan?['sms_credit'] ??
                                          plan?['sms_credits'],
                                    );
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _compactStat(
                                            icon: Icons.apartment_rounded,
                                            value: props,
                                            color: AppColors.indigo,
                                          ),
                                        ),
                                        Expanded(
                                          child: _compactStat(
                                            icon: Icons.meeting_room_rounded,
                                            value: units,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Expanded(
                                          child: _compactStat(
                                            icon: Icons.sms_rounded,
                                            value: smsCredit,
                                            color: AppColors.teal,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Second line: validity + renew counter (Paid/Lifetime)
                                Builder(
                                  builder: (_) {
                                    final end = _current!['end_date']
                                        ?.toString();
                                    final label = (end == null || end.isEmpty)
                                        ? 'Lifetime'
                                        : _validUntilWithDays(end);
                                    return Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Valid Until : $label',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        context.go('/subscription-plans'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF7FA7F3),
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text('Upgrade'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Pending Subscription - Modern Design
                  if (_current == null && _rawSubscriptionData != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.orange[50]!, Colors.amber[50]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header with icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.pending_actions_rounded,
                                  color: Colors.orange[700],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending Subscription',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Payment completion required',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Plan details
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Plan Name',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _rawSubscriptionData!['plan_name'] ??
                                                _rawSubscriptionData!['plan']?['name'] ??
                                                'N/A',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange[800],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Status',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[100],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _rawSubscriptionData!['status'] ??
                                                  'N/A',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to invoices or payment page
                                print(
                                  'DEBUG: Navigate to pending subscription payment',
                                );
                                // Check if there are unpaid invoices
                                final unpaidInvoices = _invoices
                                    .where(
                                      (inv) =>
                                          (inv['status'] ?? '')
                                              .toString()
                                              .toLowerCase() !=
                                          'paid',
                                    )
                                    .toList();

                                if (unpaidInvoices.isNotEmpty) {
                                  // Navigate to the first unpaid invoice
                                  context.go(
                                    '/subscription-checkout',
                                    extra: {'invoice': unpaidInvoices.first},
                                  );
                                } else {
                                  // Navigate to subscription plans
                                  context.go('/subscription-plans');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Complete Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Invoices',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ..._invoices.map(
                    (inv) => Card(
                      child: ListTile(
                        title: Text(inv['invoice_number'] ?? ''),
                        subtitle: Text('৳${inv['amount']} • ${inv['status']}'),
                        trailing: TextButton(
                          onPressed: () {
                            if ((inv['status'] ?? '')
                                    .toString()
                                    .toLowerCase() !=
                                'paid') {
                              context.go(
                                '/subscription-checkout',
                                extra: {'invoice': inv},
                              );
                            }
                          },
                          child: Text(
                            (inv['status'] ?? '').toString().toLowerCase() ==
                                    'paid'
                                ? 'Paid'
                                : 'Pay',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
