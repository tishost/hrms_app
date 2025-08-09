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
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    // ignore: avoid_print
    print('DEBUG: SubscriptionCenterScreen init');
    _load();
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
      final invRes = await api.get(ApiConfig.subscriptionInvoices);
      _current = subRes.data['subscription'] as Map<String, dynamic>?;
      final list = (invRes.data['invoices'] as List).cast<dynamic>();
      _invoices = list
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('DEBUG: SubscriptionCenterScreen build()');
    return Scaffold(
      appBar: AppBar(title: const Text('My Subscription')),
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
                        const Text(
                          'Current Subscription',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (_current == null)
                          const Text('No active subscription')
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
                            onPressed: () =>
                                context.push('/subscription-plans'),
                            child: const Text('Upgrade'),
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
                              context.push(
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
