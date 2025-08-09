import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:go_router/go_router.dart';

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
      if (_methods.isNotEmpty) {
        _selectedMethod = _methods.first['code']?.toString();
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
      final res = await api.post(
        ApiConfig.subscriptionCheckout,
        data: {
          'invoice_id': widget.invoice['id'],
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
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
                          'Invoice: ${inv['invoice_number']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text('Amount: ৳${inv['amount']}'),
                        const SizedBox(height: 4),
                        Text('Status: ${inv['status']}'),
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
                      onPressed: _pay,
                      child: const Text('Pay Now'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
