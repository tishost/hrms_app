import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHelper {
  /// Check and request storage permission
  static Future<bool> checkStoragePermission(BuildContext context) async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      final shouldOpenSettings = await _showPermissionDialog(context);
      if (shouldOpenSettings) {
        await openAppSettings();
      }
      return false;
    }

    return false;
  }

  /// Show permission dialog
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Permission Required'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage permission is required for this app to work properly.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Please allow storage permission in app settings to continue.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Open Settings'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.storage.status;
    return status.isPermanentlyDenied;
  }

  /// Request permission with better UX
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // First check current status
    final status = await Permission.storage.status;

    print('Permission status: $status'); // Debug log

    if (status.isGranted) {
      print('Permission already granted');
      return true;
    }

    if (status.isDenied) {
      print('Permission denied, requesting...');
      // Request permission
      final result = await Permission.storage.request();
      print('Permission request result: $result');
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      print('Permission permanently denied, showing dialog');
      // Show settings dialog
      final shouldOpenSettings = await _showPermissionDialog(context);
      if (shouldOpenSettings) {
        await openAppSettings();
        // Check again after settings
        await Future.delayed(Duration(seconds: 1));
        return await Permission.storage.status.isGranted;
      }
      return false;
    }

    // For emulator or other cases, try to request anyway
    print('Unknown status, trying to request permission');
    final result = await Permission.storage.request();
    print('Final permission result: $result');

    // If still not granted, check if we're in emulator
    if (!result.isGranted) {
      print('Permission not granted, checking if emulator...');
      // For emulator, we might need to show dialog anyway
      final shouldShowDialog = await _showPermissionDialog(context);
      if (shouldShowDialog) {
        await openAppSettings();
        await Future.delayed(Duration(seconds: 1));
        return await Permission.storage.status.isGranted;
      }
    }

    return result.isGranted;
  }
}
