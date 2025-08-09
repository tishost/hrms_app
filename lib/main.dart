import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';

// Core
import 'core/constants/app_constants.dart';
import 'core/utils/performance_config.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
// import 'core/providers/language_provider.dart';

// Features
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/screens/owner_registration_screen.dart';
import 'features/auth/presentation/screens/tenant_registration_screen.dart';
import 'features/auth/presentation/screens/mobile_entry_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/owner/presentation/screens/dashboard_screen.dart';
import 'features/owner/presentation/screens/property_list_screen.dart';
import 'features/owner/presentation/screens/unit_list_screen.dart';
import 'features/owner/presentation/screens/owner_tenant_list_screen.dart';
import 'features/owner/presentation/screens/invoice_list_screen.dart';
import 'features/owner/presentation/screens/reports_screen.dart';
import 'features/owner/presentation/screens/profile_screen.dart';
import 'features/owner/presentation/screens/profile_edit_screen.dart';
import 'features/owner/presentation/screens/subscription_plans_screen.dart';
import 'features/owner/presentation/screens/subscription_payment_webview.dart';
import 'features/owner/presentation/screens/subscription_checkout_screen.dart';
import 'features/owner/presentation/screens/subscription_center_screen.dart';
import 'features/owner/presentation/screens/property_entry_screen.dart';
import 'features/owner/presentation/screens/tenant_entry_screen.dart';
// import 'features/owner/presentation/screens/tenant_entry_simple.dart';
import 'features/owner/presentation/screens/checkout_form_screen.dart';
import 'features/owner/presentation/screens/checkout_list_screen.dart';
import 'features/owner/presentation/screens/checkout_details_screen.dart';
import 'features/tenant/presentation/screens/tenant_dashboard_screen.dart';

import 'features/tenant/presentation/screens/tenant_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity state (if needed later)
  // final initialConnectivity = await Connectivity().checkConnectivity();
  // final hasInternet = await InternetConnectionChecker().hasConnection;

  // Performance optimizations
  if (kDebugMode) {
    // Disable debug prints for better performance
    debugPrintRebuildDirtyWidgets = PerformanceConfig.enableWidgetRebuildLogs;
    debugPrint = (String? message, {int? wrapWidth}) {
      // Use performance config for debug prints
      if (message != null && message.contains('DEBUG:')) {
        PerformanceConfig.debugPrint(message);
      }
    };
  }

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final networkState = ref.watch(networkStateProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: ref.watch(routerProvider),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final maintenance = ref.watch(maintenanceStateProvider);
            return PopScope(
              canPop: false,
              onPopInvoked: (didPop) {
                if (didPop) return;
                // Global back behavior: pop if possible, else go to properties (user preference)
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              child: Stack(
                children: [
                  // If maintenance, show maintenance overlay page and block app
                  if (maintenance.isMaintenance)
                    _MaintenanceOverlay()
                  else
                    child!,
                  if (!networkState.isConnected)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          'No internet connection',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ================== ROUTER CONFIGURATION ==================
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => SignupScreen()),
      GoRoute(
        path: '/owner-registration',
        builder: (context, state) {
          // Extract query parameters
          final mobile = state.uri.queryParameters['mobile'];
          final email = state.uri.queryParameters['email'];
          final name = state.uri.queryParameters['name'];
          return OwnerRegistrationScreen(
            initialMobile: mobile,
            initialEmail: email,
            initialName: name,
          );
        },
      ),
      GoRoute(
        path: '/mobile-entry',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final name = state.uri.queryParameters['name'];
          return MobileEntryScreen(initialEmail: email, initialName: name);
        },
      ),
      GoRoute(
        path: '/tenant-registration',
        builder: (context, state) => TenantRegistrationScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(extra: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardScreen(),
      ),
      GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/tenant-dashboard',
        builder: (context, state) => TenantDashboardScreen(),
      ),
      // Owner routes
      GoRoute(
        path: '/properties',
        builder: (context, state) => PropertyListScreen(),
      ),
      GoRoute(
        path: '/property-entry',
        builder: (context, state) =>
            PropertyEntryScreen(property: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(path: '/units', builder: (context, state) => UnitListScreen()),
      GoRoute(
        path: '/tenants',
        builder: (context, state) => OwnerTenantListScreen(),
      ),
      GoRoute(
        path: '/tenant-entry',
        builder: (context, state) {
          return TenantEntryScreen(
            tenant: state.extra as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final tenant = state.extra as Map<String, dynamic>?;
          return CheckoutFormScreen(
            tenant: tenant,
            unit: tenant?['unit'],
            property: tenant?['property'],
          );
        },
      ),
      GoRoute(
        path: '/checkout/:id',
        builder: (context, state) {
          final checkoutId = state.pathParameters['id'] ?? '';
          return CheckoutDetailsScreen(checkoutId: checkoutId);
        },
      ),
      GoRoute(
        path: '/checkouts',
        builder: (context, state) {
          return CheckoutListScreen();
        },
      ),
      GoRoute(
        path: '/tenant-details',
        builder: (context, state) =>
            TenantDetailsScreen(tenant: state.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/billing',
        builder: (context, state) => InvoiceListScreen(),
      ),
      GoRoute(path: '/reports', builder: (context, state) => ReportsScreen()),
      GoRoute(
        path: '/subscription-plans',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      // Common typo alias (fallback)
      GoRoute(
        path: '/subcription-plans',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: '/subscription-checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final invoice = (extra?['invoice'] ?? {}) as Map<String, dynamic>;
          return SubscriptionCheckoutScreen(invoice: invoice);
        },
      ),
      GoRoute(
        path: '/subscription-center',
        builder: (context, state) => const SubscriptionCenterScreen(),
      ),
      // Alias for backward compatibility
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: '/subscription-payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final url = (extra?['url'] ?? '') as String;
          return SubscriptionPaymentWebView(url: url);
        },
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.matchedLocation;
      final userRole = authState.user?.role;

      print(
        'DEBUG: ROUTER REDIRECT - '
        'isLoading: $isLoading, '
        'isAuthenticated: $isAuthenticated, '
        'location: $location, '
        'userRole: $userRole',
      );

      // final isGoingToLogin = location == '/login';
      final isGoingToSplash = location == '/';

      final publicRoutes = [
        '/login',
        '/signup',
        '/owner-registration',
        '/tenant-registration',
        '/mobile-entry',
        '/forgot-password',
        '/reset-password',
      ];
      final isPublicRoute = publicRoutes.contains(location);

      // 1. While app is loading, show splash screen
      if (isLoading) {
        return isGoingToSplash ? null : '/';
      }

      // 2. If authenticated, handle redirects
      if (isAuthenticated) {
        // If on a public route (like login/signup), redirect to the correct dashboard
        if (isPublicRoute) {
          switch (userRole) {
            case 'tenant':
              return '/tenant-dashboard';
            case 'admin':
              return '/admin-dashboard';
            default:
              return '/dashboard';
          }
        }
        // If on splash, also redirect to dashboard
        if (isGoingToSplash) {
          switch (userRole) {
            case 'tenant':
              return '/tenant-dashboard';
            case 'admin':
              return '/admin-dashboard';
            default:
              return '/dashboard';
          }
        }
      }
      // 3. If not authenticated, handle redirects
      else {
        // If trying to access a private route, redirect to login
        if (!isPublicRoute && !isGoingToSplash) {
          return '/login';
        }
        // If on splash, redirect to login
        if (isGoingToSplash) {
          return '/login';
        }
      }

      // 4. No redirection needed
      return null;
    },
  );
});

// ================== SPLASH SCREEN ==================
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print(
      'DEBUG: SplashScreen initState - AuthState provider will handle checkAuthStatus',
    );
    // No need to call checkAuthStatus here - AuthState provider handles it
    // Kick off maintenance check
    Future.microtask(
      () => ref.read(maintenanceStateProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 80.w, color: Theme.of(context).primaryColor),
            SizedBox(height: 24.h),
            Text(
              AppConstants.appName,
              style: AppTheme.heading1.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 48.h),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== MAINTENANCE OVERLAY ==================
class _MaintenanceOverlay extends ConsumerWidget {
  const _MaintenanceOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(maintenanceStateProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.build_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 4),
                if ((data.companyName ?? '').isNotEmpty)
                  Text(
                    data.companyName!,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                const SizedBox(height: 12),
                Text(
                  data.message ?? 'The system is under maintenance',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if ((data.description ?? '').isNotEmpty)
                  Text(
                    data.description!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                if ((data.until ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Estimated until: ${data.until}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Refresh maintenance state; overlay auto-closes if disabled
                    ref.read(maintenanceStateProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
