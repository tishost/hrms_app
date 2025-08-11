import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:go_router/go_router.dart';

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
                  // Current Subscription
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Current Subscription',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            // Debug info (remove in production)
                            if (_current != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'API Data: ${_current!.keys.join(', ')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_current == null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plan: Free',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Status: Active',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[600],
                                ),
                              ),
                              Text(
                                'Valid: Lifetime',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plan: ${_current!['plan_name'] ?? _current!['plan']?['name'] ?? 'N/A'}',
                              ),
                              Text('Status: ${_current!['status']}'),
                              Text(
                                'Valid: ${_current!['start_date']} - ${_current!['end_date']}',
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: () => context.go('/subscription-plans'),
                            child: Text(
                              _current == null ? 'Upgrade' : 'Manage',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Debug section (remove in production)
                  if (_current != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug - Raw API Response:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Plan Name: ${_current!['plan_name'] ?? 'null'}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Plan ID: ${_current!['plan_id'] ?? 'null'}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Status: ${_current!['status'] ?? 'null'}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Start Date: ${_current!['start_date'] ?? 'null'}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'End Date: ${_current!['end_date'] ?? 'null'}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All Keys: ${_current!.keys.join(', ')}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Raw Data: ${_current.toString()}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Pending/Unpaid Subscription Info (if exists)
                  if (_current == null && _rawSubscriptionData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.amber[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Pending Subscription',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[800],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have a pending subscription that requires payment completion.',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Plan: ${_rawSubscriptionData!['plan_name'] ?? _rawSubscriptionData!['plan']?['name'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.amber[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Status: ${_rawSubscriptionData!['status'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.amber[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
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
                              backgroundColor: Colors.amber[600],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Complete Payment'),
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
