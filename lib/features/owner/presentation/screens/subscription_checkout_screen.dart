import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

class SubscriptionCheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> invoice;
  const SubscriptionCheckoutScreen({super.key, required this.invoice});

  @override
  ConsumerState<SubscriptionCheckoutScreen> createState() =>
      _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState
    extends ConsumerState<SubscriptionCheckoutScreen> {
  List<Map<String, dynamic>> _methods = [];
  String? _selectedMethod;
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _extractInvoice(Map<String, dynamic> raw) {
    final inner = raw['invoice'];
    if (inner is Map<String, dynamic>) {
      return inner;
    }
    return raw;
  }

  String _readString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final k in keys) {
      final v = map[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  String _readAmount(Map<String, dynamic> map) {
    final keys = ['amount', 'total', 'amount_due', 'net_amount'];
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString();
      if (s.isEmpty) continue;
      return s;
    }
    return '0';
  }

  double _chargeableAmount(Map<String, dynamic> map) {
    double net = 0.0;
    final n = map['net_amount'];
    if (n != null) {
      net = double.tryParse(n.toString()) ?? 0.0;
    }
    if (net > 0) return net;
    final a = map['amount'];
    return double.tryParse((a ?? '0').toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get(ApiConfig.subscriptionPaymentMethods);
      final data = res.data as Map<String, dynamic>;
      final list = (data['methods'] as List).cast<dynamic>();
      _methods = list
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Prefer bank_transfer for small amounts; remove bKash if chargeable < 1
      final inv = _extractInvoice(widget.invoice);
      final chargeAmt = _chargeableAmount(inv);
      if (chargeAmt < 1.0) {
        _methods = _methods
            .where((m) => (m['code']?.toString().toLowerCase() != 'bkash'))
            .toList();
      }
      if (_methods.isNotEmpty) {
        final bank = _methods.firstWhere(
          (m) => (m['code']?.toString().toLowerCase() == 'bank_transfer'),
          orElse: () => {},
        );
        if (chargeAmt < 1.0 && bank.isNotEmpty) {
          _selectedMethod = 'bank_transfer';
        } else {
          _selectedMethod = _methods.first['code']?.toString();
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pay() async {
    if (_selectedMethod == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      final inv = _extractInvoice(widget.invoice);
      final res = await api.post(
        ApiConfig.subscriptionCheckout,
        data: {
          'invoice_id': inv['id'] ?? inv['invoice_id'],
          'payment_method': _selectedMethod,
        },
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final payment = data['payment'] as Map<String, dynamic>?;
        if (payment != null &&
            payment['method'] == 'bkash' &&
            payment['payment_url'] != null &&
            payment['payment_url'] != '#') {
          if (mounted) {
            context.push(
              '/subscription-payment',
              extra: {'url': payment['payment_url']},
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Follow the provided instructions to complete payment.',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to initiate payment'),
            ),
          );
        }
      }
    } on DioException catch (e) {
      String serverMsg = 'Checkout failed';
      try {
        final m = e.response?.data;
        if (m is Map && m['message'] != null)
          serverMsg = m['message'].toString();
        // Collect field errors if present (Laravel 422)
        if (m is Map && m['errors'] is Map) {
          final errors = m['errors'] as Map;
          final parts = <String>[];
          for (final entry in errors.entries) {
            final val = entry.value;
            if (val is List && val.isNotEmpty) {
              parts.add(val.first.toString());
            } else if (val != null) {
              parts.add(val.toString());
            }
          }
          if (parts.isNotEmpty) {
            serverMsg = parts.join('\n');
          }
        }
      } catch (_) {}
      // Suggest bank transfer if bKash not configured
      if ((_selectedMethod == 'bkash') &&
          serverMsg.toLowerCase().contains('bkash')) {
        final bank = _methods.firstWhere(
          (m) => (m['code']?.toString().toLowerCase() == 'bank_transfer'),
          orElse: () => {},
        );
        if (bank.isNotEmpty) {
          setState(() => _selectedMethod = 'bank_transfer');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('bKash unavailable. Switched to Bank Transfer.'),
            ),
          );
          await _pay();
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(serverMsg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Checkout error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = _extractInvoice(widget.invoice);
    final invoiceNumber = _readString(inv, [
      'invoice_number',
      'invoiceNo',
      'number',
    ]);
    final amountText = _readAmount(inv);
    final chargeable = _chargeableAmount(inv).toStringAsFixed(2);
    final statusText = _readString(inv, ['status', 'state']);
    return WillPopScope(
      onWillPop: () async {
        context.go('/subscription-center');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              context.go('/subscription-center');
            },
          ),
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
                    ElevatedButton(
                      onPressed: _loadMethods,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice: $invoiceNumber',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text('Amount: ৳$amountText'),
                          const SizedBox(height: 4),
                          Text('Chargeable: ৳$chargeable'),
                          const SizedBox(height: 4),
                          Text('Status: $statusText'),
                          if (inv['due_date'] != null &&
                              inv['due_date'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Due: ${inv['due_date']}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ..._methods.map(
                      (m) => RadioListTile<String>(
                        value: m['code'],
                        groupValue: _selectedMethod,
                        onChanged: (v) => setState(() => _selectedMethod = v),
                        title: Text(m['name'] ?? m['code'] ?? ''),
                        subtitle: (m['transaction_fee'] ?? 0) > 0
                            ? Text('Fee: ${m['transaction_fee']}%')
                            : null,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final extracted = _extractInvoice(widget.invoice);
                          final invoiceId =
                              extracted['id'] ?? extracted['invoice_id'];
                          if (invoiceId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Invalid invoice. Please try again.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (_selectedMethod == 'bkash') {
                            // Optional client-side guard: block obvious zero/invalid amounts
                            final amt = double.tryParse(_readAmount(extracted));
                            if (amt == null || amt < 1.0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invalid amount. Please refresh and try again.',
                                  ),
                                ),
                              );
                              return;
                            }
                          }
                          // If amount < 1, and bank_transfer exists, force-select it
                          final amt2 =
                              double.tryParse(_readAmount(extracted)) ?? 0.0;
                          if (amt2 < 1.0 &&
                              _selectedMethod != 'bank_transfer') {
                            final hasBank = _methods.any(
                              (m) =>
                                  (m['code']?.toString().toLowerCase() ==
                                  'bank_transfer'),
                            );
                            if (hasBank) {
                              setState(() => _selectedMethod = 'bank_transfer');
                            }
                          }
                          _pay();
                        },
                        child: const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
