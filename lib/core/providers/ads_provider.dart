import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ad.dart';
import '../services/ads_service.dart';
import '../services/api_service.dart';

class AdsNotifier extends StateNotifier<AsyncValue<List<Ad>>> {
  final AdsService _adsService;

  AdsNotifier(this._adsService) : super(const AsyncValue.loading());

  /// Load ads for dashboard
  Future<void> loadDashboardAds({required String type}) async {
    try {
      state = const AsyncValue.loading();
      final ads = await _adsService.getDashboardAds(type: type);
      state = AsyncValue.data(ads);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Record ad click
  Future<void> recordAdClick(int adId) async {
    try {
      await _adsService.recordAdClick(adId);
    } catch (e) {
      // Silently handle click tracking errors
      print('Failed to record ad click: $e');
    }
  }

  /// Refresh ads
  Future<void> refreshAds({required String type}) async {
    await loadDashboardAds(type: type);
  }

  /// Force invalidate cache and refresh ads
  Future<void> forceRefreshAds({required String type}) async {
    print('🔄 [AdsNotifier] Force refreshing ads for type: $type');
    // Clear current state
    state = const AsyncValue.loading();
    // Load fresh data
    await loadDashboardAds(type: type);
  }

  /// Clear ads cache and set empty state
  void clearAdsCache() {
    print('🗑️ [AdsNotifier] Clearing ads cache');
    state = const AsyncValue.data([]);
  }

  /// Check if ads are enabled and clear cache if disabled
  Future<void> checkAdsStatus({required String type}) async {
    try {
      print('🔍 [AdsNotifier] Checking ads status for type: $type');
      final ads = await _adsService.getDashboardAds(type: type);

      // If no ads returned, clear the cache
      if (ads.isEmpty) {
        print('🔍 [AdsNotifier] No ads returned, clearing cache');
        clearAdsCache();
      } else {
        print('🔍 [AdsNotifier] ${ads.length} ads returned, updating state');
        state = AsyncValue.data(ads);
      }
    } catch (error, stackTrace) {
      print('❌ [AdsNotifier] Error checking ads status: $error');
      // Don't update state on error, keep existing data
    }
  }

  /// Clear ads
  void clearAds() {
    state = const AsyncValue.data([]);
  }

  /// Force invalidate cache for all ads providers
  static void invalidateCache() {
    print('🔄 [AdsProvider] Invalidating ads cache');
    // This will be called from the provider notifier
  }
}

// Providers
final adsServiceProvider = Provider<AdsService>((ref) {
  print('🔍 [AdsProvider] Creating AdsService');

  final apiService = ref.read(apiServiceProvider);
  print('🔍 [AdsProvider] Got ApiService: ${apiService.runtimeType}');

  final adsService = AdsService(apiService);
  print('🔍 [AdsProvider] Created AdsService: ${adsService.runtimeType}');
  return adsService;
});

final adsProvider = StateNotifierProvider<AdsNotifier, AsyncValue<List<Ad>>>(
  (ref) => AdsNotifier(ref.read(adsServiceProvider)),
);

// Provider for tenant dashboard ads
final tenantAdsProvider = FutureProvider<List<Ad>>((ref) async {
  print('🔍 [AdsProvider] tenantAdsProvider called');
  final adsService = ref.read(adsServiceProvider);
  print('🔍 [AdsProvider] Got adsService: ${adsService.runtimeType}');
  final ads = await adsService.getDashboardAds(type: 'tenant');
  print('🔍 [AdsProvider] Got ${ads.length} ads from service');
  return ads;
});

// Provider for owner dashboard ads
final ownerAdsProvider = FutureProvider<List<Ad>>((ref) async {
  final adsService = ref.read(adsServiceProvider);
  return await adsService.getDashboardAds(type: 'owner');
});

// Cache invalidation provider - use this to force refresh ads
final adsCacheInvalidatorProvider = StateProvider<int>((ref) => 0);

// Enhanced tenant ads provider with cache invalidation
final tenantAdsProviderWithCache = FutureProvider<List<Ad>>((ref) async {
  // Watch the cache invalidator to force refresh
  ref.watch(adsCacheInvalidatorProvider);

  print(
    '🔍 [AdsProvider] tenantAdsProviderWithCache called (cache invalidated)',
  );
  final adsService = ref.read(adsServiceProvider);
  final ads = await adsService.getDashboardAds(type: 'tenant');
  print(
    '🔍 [AdsProvider] Got ${ads.length} ads from service (cache invalidated)',
  );
  return ads;
});

// Enhanced owner ads provider with cache invalidation
final ownerAdsProviderWithCache = FutureProvider<List<Ad>>((ref) async {
  // Watch the cache invalidator to force refresh
  ref.watch(adsCacheInvalidatorProvider);

  final adsService = ref.read(adsServiceProvider);
  return await adsService.getDashboardAds(type: 'owner');
});
