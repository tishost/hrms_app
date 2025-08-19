import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// Core
import 'core/constants/app_constants.dart';
import 'core/utils/performance_config.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/widgets/main_app_shell.dart';
import 'core/widgets/tenant_app_shell.dart';

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
import 'features/owner/presentation/screens/checkout_form_screen.dart';
import 'features/owner/presentation/screens/invoice_payment_screen.dart';
import 'features/tenant/presentation/screens/tenant_dashboard_screen.dart';
import 'features/tenant/presentation/screens/tenant_profile_screen.dart';
import 'features/tenant/presentation/screens/tenant_billing_screen.dart';
import 'features/tenant/presentation/screens/tenant_rent_agreement_screen.dart';
import 'features/tenant/presentation/screens/tenant_more_screen.dart';
import 'core/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrintRebuildDirtyWidgets = PerformanceConfig.enableWidgetRebuildLogs;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.contains('DEBUG:')) {
        PerformanceConfig.debugPrint(message);
      }
    };
  }

  runApp(const ProviderScope(child: MyApp()));
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
            return Stack(
              children: [
                child!,
                if (maintenance.isMaintenance) const _MaintenanceOverlay(),
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
                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, __) => WillPopScope(
          onWillPop: () async {
            print('DEBUG: SplashScreen WillPopScope - Back button pressed');
            // Prevent back button on splash screen
            return false;
          },
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => BackButtonListener(
          onBackButtonPressed: () async {
            print(
              'DEBUG: LoginScreen BackButtonListener - Back button pressed',
            );
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App?'),
                content: const Text('Do you want to exit the application?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );

            if (shouldExit == true) {
              SystemNavigator.pop();
            }
            return true; // Prevent default back behavior
          },
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => BackButtonListener(
          onBackButtonPressed: () async {
            print(
              'DEBUG: SignupScreen BackButtonListener - Back button pressed',
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
            return true;
          },
          child: SignupScreen(),
        ),
      ),
      GoRoute(
        path: '/owner-registration',
        builder: (context, state) => BackButtonListener(
          onBackButtonPressed: () async {
            print(
              'DEBUG: Owner Registration BackButtonListener - Back button pressed',
            );
            context.go('/signup');
            return true;
          },
          child: OwnerRegistrationScreen(
            initialMobile: state.uri.queryParameters['mobile'],
            initialEmail: state.uri.queryParameters['email'],
            initialName: state.uri.queryParameters['name'],
          ),
        ),
      ),
      GoRoute(
        path: '/mobile-entry',
        builder: (context, state) => BackButtonListener(
          onBackButtonPressed: () async {
            print(
              'DEBUG: Mobile Entry BackButtonListener - Back button pressed',
            );
            context.go('/login');
            return true;
          },
          child: MobileEntryScreen(
            initialEmail: state.uri.queryParameters['email'],
            initialName: state.uri.queryParameters['name'],
          ),
        ),
      ),
      GoRoute(
        path: '/tenant-registration',
        builder: (context, state) => BackButtonListener(
          onBackButtonPressed: () async {
            print(
              'DEBUG: Tenant Registration BackButtonListener - Back button pressed',
            );
            context.go('/signup');
            return true;
          },
          child: TenantRegistrationScreen(
            mobile: state.uri.queryParameters['mobile'],
            email: state.uri.queryParameters['email'],
          ),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, __) => BackButtonListener(
          onBackButtonPressed: () async {
            print(
              'DEBUG: Forgot Password BackButtonListener - Back button pressed',
            );
            context.go('/login');
            return true;
          },
          child: ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => BackButtonListener(
          onBackButtonPressed: () async {
            print(
              'DEBUG: Reset Password BackButtonListener - Back button pressed',
            );
            context.go('/login');
            return true;
          },
          child: ResetPasswordScreen(
            extra: state.extra as Map<String, dynamic>?,
          ),
        ),
      ),

      // Owner Shell
      ShellRoute(
        builder: (_, __, child) => MainAppShell(child: child),
        routes: [
          GoRoute(
            path: '/checkout',
            builder: (context, state) => BackButtonListener(
              onBackButtonPressed: () async {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/owner/tenants');
                }
                return true;
              },
              child: CheckoutFormScreen(
                tenant: state.extra is Map<String, dynamic>
                    ? (state.extra as Map<String, dynamic>)['tenant']
                    : null,
                unit: state.extra is Map<String, dynamic>
                    ? (state.extra as Map<String, dynamic>)['unit']
                    : null,
                property: state.extra is Map<String, dynamic>
                    ? (state.extra as Map<String, dynamic>)['property']
                    : null,
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Dashboard BackButtonListener - Back button pressed',
                );

                // Show confirmation dialog
                final shouldExit = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Exit App'),
                    content: const Text(
                      'Are you sure you want to exit the app?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                );

                if (shouldExit == true) {
                  SystemNavigator.pop();
                }
                return true; // Prevent default back behavior
              },
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/properties',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Properties BackButtonListener - Back button pressed',
                );

                // Check if we can go back to previous page
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If no previous page, go to dashboard
                  context.go('/dashboard');
                }
                return true; // Prevent default back behavior
              },
              child: PropertyListScreen(),
            ),
          ),
          GoRoute(
            path: '/property-entry',
            builder: (context, state) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Property Entry BackButtonListener - Back button pressed',
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/properties');
                }
                return true;
              },
              child: PropertyEntryScreen(
                property: state.extra as Map<String, dynamic>?,
              ),
            ),
          ),
          GoRoute(
            path: '/tenant-entry',
            builder: (context, state) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Tenant Entry BackButtonListener - Back button pressed',
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/tenants');
                }
                return true;
              },
              child: TenantEntryScreen(
                tenant: state.extra as Map<String, dynamic>?,
              ),
            ),
          ),
          GoRoute(
            path: '/invoice-payment',
            builder: (context, state) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Invoice Payment BackButtonListener - Back button pressed',
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/billing');
                }
                return true;
              },
              child: InvoicePaymentScreen(
                invoice: state.extra as Map<String, dynamic>,
              ),
            ),
          ),

          GoRoute(
            path: '/units',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print('DEBUG: Units BackButtonListener - Back button pressed');
                // Check if we can go back to previous page
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If no previous page, go to dashboard
                  context.go('/dashboard');
                }
                return true;
              },
              child: UnitListScreen(),
            ),
          ),
          GoRoute(
            path: '/tenants',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Tenants BackButtonListener - Back button pressed',
                );
                // Check if we can go back to previous page
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If no previous page, go to dashboard
                  context.go('/dashboard');
                }
                return true;
              },
              child: OwnerTenantListScreen(),
            ),
          ),

          GoRoute(
            path: '/billing',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Billing BackButtonListener - Back button pressed',
                );
                // Check if we can go back to previous page
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If no previous page, go to dashboard
                  context.go('/dashboard');
                }
                return true;
              },
              child: InvoiceListScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Reports BackButtonListener - Back button pressed',
                );
                // Check if we can go back to previous page
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If no previous page, go to dashboard
                  context.go('/dashboard');
                }
                return true;
              },
              child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Profile BackButtonListener - Back button pressed',
                );
                // Check if we can go back to previous page
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If no previous page, go to dashboard
                  context.go('/dashboard');
                }
                return true;
              },
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Profile Edit BackButtonListener - Back button pressed',
                );
                context.go('/profile');
                return true;
              },
              child: const ProfileEditScreen(),
            ),
          ),
          GoRoute(
            path: '/subscription-center',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Subscription Center BackButtonListener - Back button pressed',
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
                return true;
              },
              child: SubscriptionCenterScreen(),
            ),
          ),
          GoRoute(
            path: '/subscription-plans',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Subscription Plans BackButtonListener - Back button pressed',
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
                return true;
              },
              child: SubscriptionPlansScreen(),
            ),
          ),
          GoRoute(
            path: '/subscription-checkout',
            builder: (context, state) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Subscription Checkout Back - redirect to /subscription-center',
                );
                context.go('/subscription-center');
                return true;
              },
              child: SubscriptionCheckoutScreen(
                invoice: state.extra as Map<String, dynamic>,
              ),
            ),
          ),
          GoRoute(
            path: '/subscription-payment',
            builder: (context, state) => BackButtonListener(
              onBackButtonPressed: () async {
                context.go('/subscription-center');
                return true;
              },
              child: SubscriptionPaymentWebView(
                url: (state.extra as Map<String, dynamic>)['url'] as String,
              ),
            ),
          ),
        ],
      ),

      // Tenant Shell
      ShellRoute(
        builder: (_, __, child) => TenantAppShell(child: child),
        routes: [
          GoRoute(
            path: '/tenant/dashboard',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Tenant Dashboard BackButtonListener - Back button pressed',
                );

                // Show confirmation dialog
                final shouldExit = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Exit App'),
                    content: const Text(
                      'Are you sure you want to exit the app?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                );

                if (shouldExit == true) {
                  SystemNavigator.pop();
                }
                return true; // Prevent default back behavior
              },
              child: AuthWrapper(child: TenantDashboardScreen()),
            ),
          ),
          GoRoute(
            path: '/tenant/profile',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/tenant/dashboard');
                }
                return true;
              },
              child: AuthWrapper(child: TenantProfileScreen()),
            ),
          ),
          GoRoute(
            path: '/tenant/billing',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/tenant/dashboard');
                }
                return true;
              },
              child: AuthWrapper(child: TenantBillingScreen()),
            ),
          ),
          GoRoute(
            path: '/tenant/properties',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                print(
                  'DEBUG: Tenant Properties BackButtonListener - Back button pressed',
                );

                // Check if we can go back to previous page
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If no previous page, go to tenant dashboard
                  context.go('/tenant/dashboard');
                }
                return true; // Prevent default back behavior
              },
              child: AuthWrapper(
                child:
                    PropertyListScreen(), // Assuming tenant uses same property list
              ),
            ),
          ),
          GoRoute(
            path: '/tenant/rent-agreement',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/tenant/dashboard');
                }
                return true;
              },
              child: AuthWrapper(child: TenantRentAgreementScreen()),
            ),
          ),
          GoRoute(
            path: '/tenant/more',
            builder: (context, __) => BackButtonListener(
              onBackButtonPressed: () async {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/tenant/dashboard');
                }
                return true;
              },
              child: AuthWrapper(child: TenantMoreScreen()),
            ),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.matchedLocation;
      final userRole = authState.user?.role;

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
      final isGoingToSplash = location == '/';

      if (isLoading) return isGoingToSplash ? null : '/';

      if (isAuthenticated) {
        if (isPublicRoute || isGoingToSplash) {
          return userRole == 'tenant' ? '/tenant/dashboard' : '/dashboard';
        }
      } else {
        if (!isPublicRoute && !isGoingToSplash) return '/login';
        if (isGoingToSplash) return '/login';
      }

      return null;
    },
  );
});

// ... Rest of the file remains unchanged ...
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
    print('DEBUG: SplashScreen initState - Starting navigation logic');

    // Start navigation logic after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });

    // Kick off maintenance check
    Future.microtask(
      () => ref.read(maintenanceStateProvider.notifier).refresh(),
    );
  }

  void _checkAuthAndNavigate() {
    final authState = ref.read(authStateProvider);
    print(
      'DEBUG: SplashScreen - Initial auth check: ${authState.isAuthenticated}, Role: ${authState.user?.role}',
    );

    if (authState.isAuthenticated && authState.user?.role != null) {
      print(
        'DEBUG: SplashScreen - User already authenticated, navigating immediately',
      );
      _handleNavigation();
    } else {
      print(
        'DEBUG: SplashScreen - User not authenticated, navigating to login',
      );
      // Navigate to login if not authenticated
      _handleNavigation();
    }
  }

  void _handleNavigation() {
    final authState = ref.read(authStateProvider);
    print(
      'DEBUG: SplashScreen - Auth state: ${authState.isAuthenticated}, Role: ${authState.user?.role}',
    );

    try {
      if (authState.isAuthenticated && authState.user?.role != null) {
        if (authState.user?.role == 'tenant') {
          print('DEBUG: Navigating to tenant dashboard');
          context.go('/tenant/dashboard');
        } else {
          print('DEBUG: Navigating to owner dashboard');
          context.go('/dashboard');
        }
      } else {
        print('DEBUG: Navigating to login');
        context.go('/login');
      }
    } catch (e) {
      print('DEBUG: Navigation error: $e');
      // Fallback to login
      context.go('/login');
    }
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
