import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AndroidStorageService {
  static const MethodChannel _channel = MethodChannel(
    'duplicate_deleter/storage',
  );

  Future<bool> requestScanAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }

    // Android 11+ broad shared-storage access.
    final manage = await Permission.manageExternalStorage.status;

    if (manage.isGranted) {
      return true;
    }

    final requested = await Permission.manageExternalStorage.request();

    if (requested.isGranted) {
      return true;
    }

    return false;
  }

  Future<void> openStorageSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod('openManageExternalStorage');
    } catch (_) {
      // Fallback to normal app settings if the dedicated
      // Android settings screen cannot be opened.
      await openAppSettings();
    }
  }
}
