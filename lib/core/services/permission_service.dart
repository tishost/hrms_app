import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PermissionService {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    try {
      // For Android 11+ (API 30+), we need to handle storage differently
      if (Platform.isAndroid) {
        print('DEBUG: Android platform detected');
        // Check if we can access external storage
        bool canAccessStorage = await _canAccessExternalStorage();
        print('DEBUG: Can access storage: $canAccessStorage');
        if (canAccessStorage) {
          print('DEBUG: Storage access successful without permission request');
          return true;
        }

        // Show custom permission dialog first
        print('DEBUG: Showing custom permission dialog');
        bool shouldRequestPermission = await _showAndroidPermissionDialog(
          context,
        );
        print(
          'DEBUG: User response to custom dialog: $shouldRequestPermission',
        );
        if (!shouldRequestPermission) {
          return false;
        }

        // Try to request manage external storage permission
        print('DEBUG: Checking MANAGE_EXTERNAL_STORAGE permission');
        PermissionStatus status = await Permission.manageExternalStorage.status;
        print('DEBUG: MANAGE_EXTERNAL_STORAGE status: $status');

        if (status.isGranted) {
          print('DEBUG: MANAGE_EXTERNAL_STORAGE already granted');
          return true;
        }

        if (status.isDenied) {
          print('DEBUG: Requesting MANAGE_EXTERNAL_STORAGE permission');
          status = await Permission.manageExternalStorage.request();
          print('DEBUG: MANAGE_EXTERNAL_STORAGE request result: $status');
          if (status.isGranted) {
            print('DEBUG: MANAGE_EXTERNAL_STORAGE granted');
            return true;
          }
        }

        // Fallback to regular storage permission
        print('DEBUG: Checking regular storage permission');
        status = await Permission.storage.status;
        print('DEBUG: Storage status: $status');

        if (status.isGranted) {
          print('DEBUG: Storage permission already granted');
          return true;
        }

        if (status.isDenied) {
          print('DEBUG: Requesting storage permission');
          status = await Permission.storage.request();
          print('DEBUG: Storage request result: $status');
          if (status.isGranted) {
            print('DEBUG: Storage permission granted');
            return true;
          }
        }

        // If still denied, show settings dialog
        if (status.isPermanentlyDenied || status.isDenied) {
          bool shouldOpenSettings = await _showPermissionDialog(context);
          if (shouldOpenSettings) {
            await openAppSettings();
            return await _canAccessExternalStorage();
          }
        }
      } else {
        // For iOS, use regular storage permission
        PermissionStatus status = await Permission.storage.status;
        if (status.isGranted) {
          return true;
        }

        if (status.isDenied) {
          status = await Permission.storage.request();
          if (status.isGranted) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  static Future<bool> _canAccessExternalStorage() async {
    try {
      // Try to create a test file in external storage
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final testFile = File('${directory.path}/test_permission.txt');
        await testFile.writeAsString('test');
        await testFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Storage access test failed: $e');
      return false;
    }
  }

  static Future<bool> _showAndroidPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.folder_open, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Storage Access Required'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This app needs access to your device storage to:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('• Download invoice PDFs'),
                  Text('• Save files to Downloads folder'),
                  Text('• Access your device storage'),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Please grant "Files and media" or "All files access" permission when prompted.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Grant Permission'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.settings, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Permission Required'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage permission is required but was denied. Please:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('1. Go to App Settings'),
                  Text('2. Find "Files and media" permission'),
                  Text('3. Grant "Allow all the time" access'),
                  Text('4. Return to the app'),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'This will allow the app to download and save invoice PDFs.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

  static Future<bool> checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android, check if we can actually access storage
        return await _canAccessExternalStorage();
      } else {
        // For iOS, check regular storage permission
        PermissionStatus status = await Permission.storage.status;
        return status.isGranted;
      }
    } catch (e) {
      print('Permission check error: $e');
      return false;
    }
  }

  static Future<void> showPermissionDeniedSnackBar(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Storage permission is required to download files'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }
}
