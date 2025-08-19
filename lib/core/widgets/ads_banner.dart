import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/ad.dart';
import '../providers/ads_provider.dart';

class AdsBanner extends ConsumerStatefulWidget {
  final String type; // 'tenant' or 'owner'
  final double height;
  final EdgeInsets? margin;
  final bool adsEnabled; // Whether ads are enabled

  const AdsBanner({
    super.key,
    required this.type,
    this.height = 200,
    this.margin,
    this.adsEnabled = true,
  });

  @override
  ConsumerState<AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends ConsumerState<AdsBanner>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    // Don't start auto-scroll if ads are disabled
    if (!widget.adsEnabled) {
      return;
    }

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _nextPage();
      }
    });
  }

  void _nextPage() {
    // Don't auto-scroll if ads are disabled
    if (!widget.adsEnabled) {
      return;
    }

    final adsAsync = ref.read(
      widget.type == 'tenant' ? tenantAdsProvider : ownerAdsProvider,
    );

    adsAsync.whenData((ads) {
      if (ads.isNotEmpty && mounted) {
        final nextPage = (_currentPage + 1) % ads.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  void _onAdTap(Ad ad) async {
    if (ad.isClickable && ad.url != null) {
      try {
        // Show a snackbar indicating the ad was clicked first
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening: ${ad.title ?? 'Ad'}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Record click for analytics (non-blocking)
        try {
          await ref.read(adsProvider.notifier).recordAdClick(ad.id);
          print('✅ Ad click recorded successfully: ${ad.title ?? 'Ad'}');
        } catch (e) {
          // Don't let analytics errors affect user experience
          print('⚠️ Failed to record ad click (non-critical): $e');
        }

        // Note: In a real app, you would use url_launcher package
        // For now, we'll just show the snackbar
        print('Ad clicked: ${ad.title ?? 'Ad'} - URL: ${ad.url}');
      } catch (e) {
        print('Failed to handle ad click: $e');
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open ad: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 [AdsBanner] Building banner for type: ${widget.type}');

    // If ads are disabled, don't show anything
    if (!widget.adsEnabled) {
      print('🔍 [AdsBanner] Ads disabled, hiding banner');
      return const SizedBox.shrink();
    }

    final adsAsync = ref.watch(
      widget.type == 'tenant' ? tenantAdsProvider : ownerAdsProvider,
    );

    print('🔍 [AdsBanner] Ads async state: ${adsAsync.runtimeType}');
    adsAsync.whenData((ads) {
      print('🔍 [AdsBanner] Got ${ads.length} ads');
    });

    return Container(
      height: widget.height,
      margin: widget.margin,
      child: adsAsync.when(
        data: (ads) {
          print('🔍 [AdsBanner] Data state: ${ads.length} ads');
          if (ads.isEmpty) {
            print('🔍 [AdsBanner] No ads, hiding banner');
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              // Ads PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return GestureDetector(
                      onTap: () => _onAdTap(ad),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Ad Image
                              Image.network(
                                ad.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                              // Gradient overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Text overlay removed - image only display
                              // Ads now display as clean image banners without text
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Page indicator below the image
              if (ads.length > 1)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(ads.length, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage
                              ? Colors.blue
                              : Colors.grey.withOpacity(0.5),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          );
        },
        loading: () {
          print('🔍 [AdsBanner] Loading state');
          return Container(
            height: widget.height,
            margin: widget.margin,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        error: (error, stackTrace) {
          print('❌ [AdsBanner] Error state: $error');
          print('❌ [AdsBanner] Stack trace: $stackTrace');
          return Container(
            height: widget.height,
            margin: widget.margin,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load ads',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
