import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SubscriptionPaymentWebView extends StatefulWidget {
  final String url;
  const SubscriptionPaymentWebView({super.key, required this.url});

  @override
  State<SubscriptionPaymentWebView> createState() =>
      _SubscriptionPaymentWebViewState();
}

class _SubscriptionPaymentWebViewState
    extends State<SubscriptionPaymentWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  DateTime? _lastBack;

  bool _handleCallbackUrl(String url) {
    try {
      final lower = url.toLowerCase();
      // Common patterns for success/cancel/fail
      final isSuccess =
          lower.contains('payment-success') ||
          lower.contains('status=success') ||
          lower.contains('status=completed') ||
          lower.contains('transactionstatus=completed');
      final isCancel =
          lower.contains('payment-cancel') ||
          lower.contains('status=cancel') ||
          lower.contains('status=cancelled');
      final isFail =
          lower.contains('payment-fail') ||
          lower.contains('status=failure') ||
          lower.contains('status=fail');

      if (isSuccess) {
        if (mounted) {
          // Go to subscription center
          context.go('/subscription-center');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Payment successful')));
        }
        return true;
      }
      if (isCancel || isFail) {
        if (mounted) {
          // Back to plans for retry
          context.go('/subscription-plans');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isCancel ? 'Payment cancelled' : 'Payment failed'),
            ),
          );
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
            // Intercept early if callback hit quickly
            if (_handleCallbackUrl(url)) return;
          },
          onPageFinished: (url) {
            setState(() => _loading = false);
            _handleCallbackUrl(url);
          },
          onNavigationRequest: (request) {
            final handled = _handleCallbackUrl(request.url);
            return handled
                ? NavigationDecision.prevent
                : NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastBack == null ||
            now.difference(_lastBack!) > const Duration(seconds: 2)) {
          _lastBack = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to cancel payment')),
          );
          return false;
        }
        context.go('/subscription-plans');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Complete Payment')),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
