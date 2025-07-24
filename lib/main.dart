import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// Core
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/services/api_service.dart';
import 'core/services/security_service.dart';
import 'core/models/user_model.dart';

// Features
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/owner/presentation/screens/dashboard_screen.dart';
import 'features/owner/presentation/screens/property_list_screen.dart';
import 'features/owner/presentation/screens/unit_list_screen.dart';
import 'features/tenant/presentation/screens/tenant_list_screen.dart';
import 'features/owner/presentation/screens/invoice_list_screen.dart';
import 'features/owner/presentation/screens/reports_screen.dart';
import 'features/owner/presentation/screens/profile_screen.dart';
import 'features/owner/presentation/screens/property_entry_screen.dart';
import 'features/tenant/presentation/screens/tenant_dashboard_screen.dart';
import 'features/tenant/presentation/screens/tenant_entry_screen.dart';
import 'features/tenant/presentation/screens/tenant_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity state
  final initialConnectivity = await Connectivity().checkConnectivity();
  final hasInternet = await InternetConnectionChecker().hasConnection;

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
            return Stack(
              children: [
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

// ================== ROUTER CONFIGURATION ==================
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardScreen(),
      ),
      GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
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
        builder: (context, state) => PropertyEntryScreen(),
      ),
      GoRoute(path: '/units', builder: (context, state) => UnitListScreen()),
      GoRoute(
        path: '/tenants',
        builder: (context, state) => TenantListScreen(),
      ),
      GoRoute(
        path: '/tenant-entry',
        builder: (context, state) => TenantEntryScreen(),
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
    ],
    redirect: (context, state) {
      final isAuthLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.user?.role;

      print(
        'DEBUG: Redirect check - isAuthenticated: $isAuthenticated, location: ${state.matchedLocation}, user: ${authState.user?.role}',
      );

      // If on splash screen, redirect based on auth status
      if (state.matchedLocation == '/') {
        if (isAuthenticated) {
          final role = userRole ?? 'owner';
          print(
            'DEBUG: User authenticated, redirecting to dashboard for role: $role',
          );
          if (role == 'tenant') {
            return '/tenant-dashboard';
          } else {
            return '/dashboard';
          }
        } else {
          print('DEBUG: User not authenticated, redirecting to login');
          return '/login';
        }
      }

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated &&
          state.matchedLocation != '/login' &&
          state.matchedLocation != '/') {
        print('DEBUG: Redirecting to login');
        return '/login';
      }

      // If authenticated and on login page, redirect to dashboard
      if (isAuthenticated && state.matchedLocation == '/login') {
        print('DEBUG: Redirecting to dashboard');
        return '/dashboard';
      }

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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('DEBUG: Splash screen starting initialization...');

    try {
      // Check authentication status
      await ref.read(authStateProvider.notifier).checkAuthStatus();
      print('DEBUG: Auth status checked');

      // Initialize connectivity monitoring
      _setupConnectivityListener();

      // Add a small delay to show splash screen
      await Future.delayed(Duration(milliseconds: 1500));

      print('DEBUG: Splash screen initialization complete');
    } catch (e) {
      print('DEBUG: Error in splash initialization: $e');
    }
  }

  void _setupConnectivityListener() {
    // Monitor connectivity
    Connectivity().onConnectivityChanged.listen((result) {
      ref
          .read(networkStateProvider.notifier)
          .updateConnectionStatus(
            result != ConnectivityResult.none,
            result.name,
          );
    });

    // Check internet connection
    InternetConnectionChecker().onStatusChange.listen((status) {
      final isConnected = status == InternetConnectionStatus.connected;
      ref
          .read(networkStateProvider.notifier)
          .updateConnectionStatus(isConnected, 'internet');
    });
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
