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
  Map<String, dynamic>? _currentSubscription;

  @override
  void initState() {
    super.initState();
    // Debug: confirm route landed
    // ignore: avoid_print
    print('DEBUG: SubscriptionPlansScreen init');
    _loadCurrentSubscription();
    _loadPlans();
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/owner/subscription');
      print('DEBUG: Current subscription API response: ${response.data}');

      if (response.data['success'] == true &&
          response.data['subscription'] != null) {
        final subscription =
            response.data['subscription'] as Map<String, dynamic>?;

        // Check if subscription is active (paid and active)
        final status = subscription!['status']?.toString().toLowerCase();
        final isActive = status == 'active' || status == 'paid';

        if (isActive) {
          setState(() {
            _currentSubscription = subscription;
          });
          print('DEBUG: Active subscription loaded: $_currentSubscription');
        } else {
          // Subscription exists but not active (pending/unpaid)
          setState(() {
            _currentSubscription = null;
          });
          print(
            'DEBUG: Subscription found but not active. Status: $status, defaulting to Free plan',
          );
        }
      } else {
        setState(() {
          _currentSubscription = null;
        });
        print('DEBUG: No current subscription found');
      }
    } catch (e) {
      print('DEBUG: Failed to load current subscription: $e');
      setState(() {
        _currentSubscription = null;
      });
    }
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
      print('DEBUG: Making API call to: ${ApiConfig.subscriptionPlans}');
      final res = await api.get(ApiConfig.subscriptionPlans);
      print('DEBUG: API response status: ${res.statusCode}');
      print('DEBUG: API response data: ${res.data}');

      final data = res.data as Map<String, dynamic>;
      if (data['plans'] == null) {
        print('DEBUG: No plans key in response');
        setState(() {
          _plans = [];
          _isLoading = false;
        });
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building subscription plans screen');
    print('DEBUG: _isLoading: $_isLoading');
    print('DEBUG: _error: $_error');
    print('DEBUG: _plans.length: ${_plans.length}');
    print('DEBUG: _currentSubscription: $_currentSubscription');

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
          constraints: const BoxConstraints(maxWidth: double.infinity),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary.withValues(alpha: 0.05), Colors.white],
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading subscription plans...'),
                    ],
                  ),
                )
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
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadCurrentSubscription();
                    await _loadPlans();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // App Logo Header
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
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
                                      color: Colors.blue.withValues(alpha: 0.3),
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
                                'Choose Your Plan',
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
                      
                      // Debug info (remove in production)
                      if (_currentSubscription != null)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            maxWidth: double.infinity,
                          ),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Subscription:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              Text(
                                'Plan: ${_currentSubscription!['plan_name'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                              Text(
                                'Status: ${_currentSubscription!['status'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ],
                          ),
                        ),
                      // Plans list
                      if (_plans.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No subscription plans available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please try again later or contact support',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...List.generate(_plans.length, (index) {
                          final plan = _plans[index];
                          final isPopular =
                              plan['is_popular'] == true ||
                              index == _plans.length - 1;
                          return _PlanCard(
                            plan: plan,
                            isPopular: isPopular,
                            currentSubscription: _currentSubscription,
                            onBuy: () => _buyPlan(plan),
                          );
                        }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _buyPlan(Map<String, dynamic> plan) async {
    try {
      final api = ref.read(apiServiceProvider);

      // Check if this is an upgrade or new purchase
      if (_currentSubscription != null) {
        // This is an upgrade
        final currentPlanPrice = _currentSubscription!['plan_price'] ?? 0.0;
        final newPlanPrice = plan['price'] ?? 0.0;

        if (newPlanPrice <= currentPlanPrice) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only upgrade to a higher-priced plan.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Initiate upgrade
        final response = await api.post(
          '/subscription/upgrade',
          data: {'plan_id': plan['id']},
        );

        if (response.data['success'] == true) {
          final invoice = response.data['invoice'];

          // Navigate to checkout with upgrade invoice
          if (context.mounted) {
            context.go(
              '/subscription-checkout',
              extra: {
                'invoice': invoice,
                'isUpgrade': true,
                'upgradeRequest': response.data['upgrade_request'],
              },
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.data['message'] ?? 'Upgrade failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // This is a new purchase
        final response = await api.post(
          '/subscription/purchase',
          data: {'plan_id': plan['id']},
        );

        if (response.data['success'] == true) {
          final invoice = response.data['invoice'];

          // Navigate to checkout
          if (context.mounted) {
            context.go(
              '/subscription-checkout',
              extra: {'invoice': invoice, 'isUpgrade': false},
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.data['message'] ?? 'Purchase failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error in _buyPlan: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isPopular;
  final Map<String, dynamic>? currentSubscription;
  final VoidCallback onBuy;

  const _PlanCard({
    required this.plan,
    required this.isPopular,
    this.currentSubscription,
    required this.onBuy,
  });

  bool _isCurrentPlan() {
    if (currentSubscription == null) return false;

    // Check if this plan matches the current subscription
    final currentPlanId = currentSubscription!['plan_id']?.toString();
    final currentPlanName = currentSubscription!['plan_name']
        ?.toString()
        .toLowerCase();
    final planId = plan['id']?.toString();
    final planName = plan['name']?.toString().toLowerCase();

    // Match by ID or name
    return (currentPlanId != null &&
            planId != null &&
            currentPlanId == planId) ||
        (currentPlanName != null &&
            planName != null &&
            currentPlanName == planName);
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentPlan = _isCurrentPlan();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      constraints: const BoxConstraints(maxWidth: double.infinity),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black12.withValues(alpha: 0.06),
          width: 1,
        ),
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
                  color: AppColors.primary.withValues(alpha: 0.15),
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
          if (isCurrentPlan)
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Current Plan',
                  style: TextStyle(
                    color: Colors.green[700],
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        plan['formatted_price']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFF6A88F7), Color(0xFF7ED2F8)],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Per ${plan['billing_cycle_text']?.toString().toLowerCase().replaceAll('ly', '') ?? 'month'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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
                    onPressed: isCurrentPlan ? null : onBuy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? Colors.grey[400]
                          : const Color(0xFF7FA7F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Current Plan'
                          : (currentSubscription != null
                                ? 'Upgrade'
                                : 'Buy Now'),
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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
