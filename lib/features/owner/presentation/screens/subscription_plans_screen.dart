import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState
    extends ConsumerState<SubscriptionPlansScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    // Debug: confirm route landed
    // ignore: avoid_print
    print('DEBUG: SubscriptionPlansScreen init');
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    // ignore: avoid_print
    print('DEBUG: Loading subscription plans...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get(ApiConfig.subscriptionPlans);
      final data = res.data as Map<String, dynamic>;
      final list = (data['plans'] as List).cast<dynamic>();
      setState(() {
        _plans = list
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
        _isLoading = false;
      });
      // ignore: avoid_print
      print('DEBUG: Plans loaded: ${_plans.length}');
    } on DioException catch (e) {
      // ignore: avoid_print
      print('DEBUG: Plans load DioException: ${e.message}');
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Plans load error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _buyPlan(Map<String, dynamic> plan) async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.post(
        ApiConfig.subscriptionPurchase,
        data: {'plan_id': plan['id'], 'payment_method': 'bkash'},
      );
      final data = res.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final payment = data['payment'] as Map<String, dynamic>?;
        if (payment != null &&
            payment['method'] == 'bkash' &&
            payment['payment_url'] != null &&
            payment['payment_url'] != '#') {
          // Open payment webview screen
          if (mounted) {
            context.push(
              '/subscription-payment',
              extra: {
                'url': payment['payment_url'],
                'invoice': data['invoice'],
              },
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invoice created. Please complete payment.'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to purchase plan'),
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/properties');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Subscription Plans')),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary.withOpacity(0.05), Colors.white],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadPlans,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final isPopular =
                        plan['is_popular'] == true ||
                        index == _plans.length - 1;
                    return _PlanCard(
                      plan: plan,
                      isPopular: isPopular,
                      onBuy: () => _buyPlan(plan),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // Removed unused helper
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isPopular;
  final VoidCallback onBuy;

  const _PlanCard({
    required this.plan,
    required this.isPopular,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12.withOpacity(0.06), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Most Popular',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title & price
                Text(
                  plan['name']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plan['formatted_price']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF6A88F7), Color(0xFF7ED2F8)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Per ${plan['billing_cycle_text']?.toString().toLowerCase().replaceAll('ly', '') ?? 'month'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Feature list (dynamic from API if available)
                ..._buildDynamicFeatures(plan),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBuy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7FA7F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatures(Map<String, dynamic> plan) {
    final feats = <String>[
      'Up to ${plan['properties_limit'] == -1 ? 'Unlimited' : plan['properties_limit']} properties/buildings',
      'Up to ${plan['tenants_limit'] == -1 ? 'Unlimited' : plan['tenants_limit']} tenants',
      'Up to ${plan['units_limit'] == -1 ? 'Unlimited' : plan['units_limit']} units/flats',
      if (plan['sms_notification'] == true)
        'SMS notifications'
      else
        'SMS credits/month: ${plan['sms_credit'] ?? 0}',
      '24/7 support',
    ];

    return feats
        .map(
          (t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF34C759),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF4D6282),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildDynamicFeatures(Map<String, dynamic> plan) {
    final dynamicList = (plan['features'] is List)
        ? (plan['features'] as List).cast<dynamic>()
        : <dynamic>[];
    final defaultFeats = _buildFeatures(plan);

    final featureWidgets = <Widget>[];

    String sanitize(String raw) {
      // Remove HTML tags
      final noHtml = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
      // Collapse whitespace
      final collapsed = noHtml.replaceAll(RegExp(r'\s+'), ' ').trim();
      return collapsed;
    }

    bool isCssLike(String raw) {
      final lower = raw.toLowerCase();
      if (raw.contains('{') || raw.contains('}') || raw.contains(';'))
        return true;
      if (lower.contains('color:') ||
          lower.contains('background') ||
          lower.contains('font') ||
          lower.contains('padding') ||
          lower.contains('margin')) {
        return true;
      }
      // Class selectors / ids
      if (lower.startsWith('.') || lower.startsWith('#')) return true;
      return false;
    }

    if (dynamicList.isNotEmpty) {
      for (final item in dynamicList) {
        String candidate = '';
        if (item is String) {
          candidate = item;
        } else if (item is Map<String, dynamic>) {
          candidate = (item['text'] ?? item['label'] ?? item['title'] ?? '')
              .toString();
        } else {
          candidate = item.toString();
        }

        if (candidate.trim().isEmpty) continue;
        if (isCssLike(candidate)) continue; // Skip CSS-like content from DB
        final text = sanitize(candidate);
        if (text.isEmpty) continue;

        featureWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF34C759),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF4D6282),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // If API provided features are present, show them first; then append defaults
    return [
      ...featureWidgets,
      if (featureWidgets.isNotEmpty) const SizedBox(height: 6),
      ...defaultFeats,
    ];
  }
}
