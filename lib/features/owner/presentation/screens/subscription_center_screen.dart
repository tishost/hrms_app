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
                  // Current Subscription - New Modern Design
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Logo Header
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                // Logo Container
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue[600]!,
                                        Colors.blue[700]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // House Icon (Top Left)
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Icon(
                                          Icons.home_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      // Document Icon (Right)
                                      Positioned(
                                        top: 20,
                                        right: 12,
                                        child: Icon(
                                          Icons.description_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      // BM Text (Bottom Center)
                                      Positioned(
                                        bottom: 12,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Text(
                                            'BM',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // App Name
                                Text(
                                  'BariManager',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Subscription Center',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_current == null)
                          // Free Plan - Modern Card Design
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.blue[50]!, Colors.purple[50]!],
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
                                // Plan Icon and Name
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: Colors.blue[600],
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Free Plan',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Basic features included',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.blue[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Plan Details
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'Active',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey[300],
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              'Validity',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Lifetime',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Upgrade Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        context.go('/subscription-plans'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
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
                                      'Upgrade Now',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Paid Plan - Modern Card Design
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.purple[50]!,
                                  Colors.indigo[50]!,
                                ],
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
                                // Plan Icon and Name
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.purple.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.workspace_premium_rounded,
                                        color: Colors.purple[600],
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _current!['plan_name'] ??
                                                _current!['plan']?['name'] ??
                                                'Premium Plan',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple[800],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Premium features unlocked',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.purple[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Plan Details
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _current!['status'] ?? 'Active',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey[300],
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              'Valid Until',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _current!['end_date'] ?? 'N/A',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.purple[800],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Manage Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        context.go('/subscription-plans'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.purple[700],
                                      side: BorderSide(
                                        color: Colors.purple[300]!,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Manage Subscription',
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
