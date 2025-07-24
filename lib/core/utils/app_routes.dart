class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String otp = '/otp';

  // Owner Routes
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerProperties = '/owner/properties';
  static const String ownerPropertyCreate = '/owner/properties/create';
  static const String ownerPropertyEdit = '/owner/properties/edit';
  static const String ownerUnits = '/owner/units';
  static const String ownerUnitCreate = '/owner/units/create';
  static const String ownerUnitEdit = '/owner/units/edit';
  static const String ownerTenants = '/owner/tenants';
  static const String ownerTenantCreate = '/owner/tenants/create';
  static const String ownerTenantEdit = '/owner/tenants/edit';
  static const String ownerInvoices = '/owner/invoices';
  static const String ownerInvoiceCreate = '/owner/invoices/create';
  static const String ownerInvoiceEdit = '/owner/invoices/edit';
  static const String ownerInvoicePdf = '/owner/invoices/pdf';
  static const String ownerInvoicePayment = '/owner/invoices/payment';
  static const String ownerReports = '/owner/reports';
  static const String ownerProfile = '/owner/profile';
  static const String ownerSettings = '/owner/settings';

  // Tenant Routes
  static const String tenantDashboard = '/tenant/dashboard';
  static const String tenantInvoices = '/tenant/invoices';
  static const String tenantInvoicePdf = '/tenant/invoices/pdf';
  static const String tenantInvoicePayment = '/tenant/invoices/payment';
  static const String tenantProfile = '/tenant/profile';
  static const String tenantBilling = '/tenant/billing';
  static const String tenantRegistration = '/tenant/registration';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminOwners = '/admin/owners';
  static const String adminOwnerCreate = '/admin/owners/create';
  static const String adminOwnerEdit = '/admin/owners/edit';
  static const String adminSettings = '/admin/settings';
  static const String adminUsers = '/admin/users';

  // Common Routes
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String debug = '/debug';
  static const String notFound = '/not-found';
  static const String error = '/error';

  // Splash and Welcome
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';

  // Modal Routes
  static const String imageViewer = '/image-viewer';
  static const String pdfViewer = '/pdf-viewer';
  static const String confirmation = '/confirmation';
  static const String loading = '/loading';

  // Helper method to get route with parameters
  static String getRouteWithParams(String route, Map<String, String> params) {
    String result = route;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value);
    });
    return result;
  }

  // Helper method to check if route is auth route
  static bool isAuthRoute(String route) {
    return route == login ||
        route == register ||
        route == forgotPassword ||
        route == resetPassword ||
        route == otp;
  }

  // Helper method to check if route is owner route
  static bool isOwnerRoute(String route) {
    return route.startsWith('/owner/');
  }

  // Helper method to check if route is tenant route
  static bool isTenantRoute(String route) {
    return route.startsWith('/tenant/');
  }

  // Helper method to check if route is admin route
  static bool isAdminRoute(String route) {
    return route.startsWith('/admin/');
  }
}
