import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class AndroidStorageService {
  Future<bool> requestScanAccess() async {
    if (!Platform.isAndroid) return true;

    // Complete shared-storage scanning needs broad file access on Android 11+.
    // Android may send the user to system settings for this special permission.
    if (Platform.isAndroid) {
      final manage = await Permission.manageExternalStorage.status;
      if (manage.isGranted) return true;

      final requested = await Permission.manageExternalStorage.request();
      if (requested.isGranted) return true;
    }

    // Fallback for older Android versions.
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<bool> openStorageSettings() => openAppSettings();
}
