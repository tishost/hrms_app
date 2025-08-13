class AppConstants {
  // App Info
  static const String appName = 'BariManager';
  static const String appVersion = '1.0.0';

  // API Constants
  static const int apiTimeout = 30000; // 30 seconds
  static const String apiBaseUrl = 'http://103.98.76.11/api';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userInfoKey = 'user_info';
  static const String rememberMeKey = 'remember_me';
  static const String isFirstTimeKey = 'is_first_time';

  // Validation Constants
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 4.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Loading States
  static const String loadingText = 'Loading...';
  static const String errorText = 'Something went wrong';
  static const String retryText = 'Retry';

  // User Types
  static const String userTypeOwner = 'owner';
  static const String userTypeTenant = 'tenant';
  static const String userTypeAdmin = 'admin';

  // Property Status
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusMaintenance = 'maintenance';

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentBankTransfer = 'bank_transfer';
  static const String paymentMobileBanking = 'mobile_banking';
  static const String paymentCheck = 'check';
  static const String paymentOther = 'other';

  // Invoice Status
  static const String invoicePaid = 'paid';
  static const String invoiceUnpaid = 'unpaid';
  static const String invoicePartial = 'partial';
  static const String invoiceOverdue = 'overdue';
}
