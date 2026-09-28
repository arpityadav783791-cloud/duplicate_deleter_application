import 'dart:io';

import 'package:flutter/services.dart';

import '../models/storage_info.dart';

class StorageService {
  static const MethodChannel _channel = MethodChannel(
    'duplicate_deleter/storage',
  );

  String get defaultStoragePath {
    if (Platform.isAndroid) {
      return '/storage/emulated/0';
    }

    if (Platform.isWindows) {
      return Platform.environment['SystemDrive'] ?? 'C:\\';
    }

    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['HOME'] ?? '/';
    }

    return '/';
  }

  Future<StorageInfo> getStorageInfo(String path) async {
    if (Platform.isAndroid) {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getStorageInfo',
        {'path': path},
      );

      if (result == null) {
        throw Exception('Unable to read storage information.');
      }

      return StorageInfo(
        totalBytes: (result['totalBytes'] as num).toInt(),
        usedBytes: (result['usedBytes'] as num).toInt(),
        freeBytes: (result['freeBytes'] as num).toInt(),
      );
    }

    return _getDesktopStorageInfo(path);
  }

  Future<StorageInfo> _getDesktopStorageInfo(String path) async {
    final result = await Process.run('df', ['-B1', path]);

    if (result.exitCode != 0) {
      throw Exception('Unable to read storage information.');
    }

    final lines = result.stdout.toString().trim().split('\n');

    if (lines.length < 2) {
      throw Exception('Invalid storage information.');
    }

    final values = lines.last.trim().split(RegExp(r'\s+'));

    if (values.length < 5) {
      throw Exception('Invalid storage information.');
    }

    return StorageInfo(
      totalBytes: int.parse(values[1]),
      usedBytes: int.parse(values[2]),
      freeBytes: int.parse(values[3]),
    );
  }
}
