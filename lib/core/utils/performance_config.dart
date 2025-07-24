import 'package:flutter/foundation.dart';

class PerformanceConfig {
  // Performance optimization settings
  static const bool enableDebugPrints = kDebugMode;
  static const bool enablePerformanceOverlay = false;
  static const bool enableWidgetRebuildLogs = false;

  // Debug print wrapper for conditional logging
  static void debugPrint(String message) {
    if (enableDebugPrints) {
      print('DEBUG: $message');
    }
  }

  // Performance monitoring
  static void logPerformance(String operation, {Duration? duration}) {
    if (enableDebugPrints) {
      if (duration != null) {
        print('PERF: $operation took ${duration.inMilliseconds}ms');
      } else {
        print('PERF: $operation');
      }
    }
  }

  // Memory usage logging
  static void logMemoryUsage(String context) {
    if (enableDebugPrints) {
      // This would be implemented with actual memory monitoring
      print('MEMORY: $context');
    }
  }
}
