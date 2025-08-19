// lib/utils/api_config.dart

class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://barimanager.com/api';

  // API Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String profile = '/user';
  static const String refresh = '/auth/refresh';

  // Owner endpoints
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerProperties = '/owner/properties';
  static const String ownerUnits = '/owner/units';
  static const String ownerTenants = '/owner/tenants';
  static const String ownerInvoices = '/owner/invoices';
  static const String ownerReports = '/owner/reports';

  // Tenant endpoints
  static const String tenantDashboard = '/tenant/dashboard';
  static const String tenantInvoices = '/tenant/invoices';
  static const String tenantPayments = '/tenant/payments';
  static const String tenantProfile = '/tenant/profile';

  // Admin endpoints
  static const String adminDashboard = '/admin/dashboard';
  static const String adminOwners = '/admin/owners';
  static const String adminSettings = '/admin/settings';

  // Common endpoints
  static const String countries = '/common/countries';
  static const String charges = '/common/charges';
  static const String upload = '/common/upload';

  // Subscription endpoints
  static const String subscriptionPlans = '/subscription/plans';
  static const String subscriptionPurchase = '/subscription/purchase';
  static const String subscriptionPaymentMethods =
      '/subscription/payment-methods';
  static const String subscriptionInvoices = '/subscription/invoices';
  static const String subscriptionCheckout = '/subscription/checkout';

  // Get full API URL
  static String getApiUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Get base URL
  static String getBaseUrl() {
    print('🔍 [ApiConfig] getBaseUrl() called, returning: $baseUrl');
    return baseUrl;
  }

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
