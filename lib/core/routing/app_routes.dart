class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String tenantRegistration = '/tenant-registration';
  static const String ownerRegistration = '/owner-registration';

  // Owner Routes
  static const String ownerDashboard = '/dashboard';
  static const String propertyList = '/properties';
  static const String propertyCreate = '/properties/create';
  static const String propertyEdit = '/properties/edit';
  static const String unitList = '/units';
  static const String unitCreate = '/units/create';
  static const String unitEdit = '/units/edit';
  static const String tenantList = '/tenants';
  static const String tenantCreate = '/tenants/create';
  static const String tenantEdit = '/tenants/edit';
  static const String ownerProfile = '/profile';
  static const String reports = '/reports';

  // Tenant Routes
  static const String tenantDashboard = '/tenant-dashboard';
  static const String tenantBilling = '/tenant-billing';
  static const String tenantProfile = '/tenant-profile';
  static const String invoicePdf = '/invoice-pdf';
  static const String invoicePayment = '/invoice-payment';

  // Common Routes
  static const String debug = '/debug';
  static const String splash = '/splash';
  static const String home = '/';
}
