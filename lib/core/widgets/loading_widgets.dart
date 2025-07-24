import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

class LoadingWidgets {
  // Shimmer Loading Card
  static Widget shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 120.h,
        margin: AppTheme.paddingMedium,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
      ),
    );
  }

  // Shimmer Loading List
  static Widget shimmerList({int itemCount = 5}) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => shimmerCard(),
    );
  }

  // Shimmer Loading Text
  static Widget shimmerText({double? width, double? height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 16.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }

  // Circular Progress with Message
  static Widget circularProgress({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3.w,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(message, style: AppTheme.body2, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  // Lottie Animation Loading
  static Widget lottieLoading({String? assetPath}) {
    return Center(
      child: Lottie.asset(
        assetPath ?? 'assets/animations/loading.json',
        width: 200.w,
        height: 200.h,
        fit: BoxFit.contain,
      ),
    );
  }

  // Skeleton Loading for Different Components
  static Widget skeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Padding(
          padding: AppTheme.paddingMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title skeleton
              Container(
                width: double.infinity,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 12.h),
              // Description skeleton
              Container(
                width: double.infinity,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 200.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Button Loading State
  static Widget loadingButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(text),
      ),
    );
  }

  // Overlay Loading
  static Widget overlayLoading({
    required bool isLoading,
    required Widget child,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: AppTheme.paddingLarge,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      Text('Loading...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Pull to Refresh Loading
  static Widget pullToRefreshLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, size: AppTheme.iconSizeLarge, color: Colors.grey),
          SizedBox(height: 8.h),
          Text(
            'Pull to refresh',
            style: AppTheme.caption.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Empty State with Loading
  static Widget emptyStateWithLoading({
    required String message,
    required IconData icon,
    bool isLoading = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            CircularProgressIndicator()
          else ...[
            Icon(icon, size: AppTheme.iconSizeLarge, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              message,
              style: AppTheme.body1.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
