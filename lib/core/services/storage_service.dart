import 'dart:convert';
import 'dart:io';

import '../models/storage_info.dart';

class StorageService {
  static StorageInfo? _cachedStorage;

  StorageInfo? get cachedStorage => _cachedStorage;

  Future<StorageInfo> getStorageInfo(String path) async {
    if (_cachedStorage != null) {
      return _cachedStorage!;
    }

    final result = await Process.run('df', ['-B1', path]);

    if (result.exitCode != 0) {
      throw Exception('Unable to read storage information.');
    }

    final output = const Utf8Decoder().convert(
      result.stdout is List<int>
          ? result.stdout
          : utf8.encode(result.stdout.toString()),
    );

    final lines = output.trim().split('\n');

    if (lines.length < 2) {
      throw Exception('Invalid storage information.');
    }

    final values = lines.last.trim().split(RegExp(r'\s+'));

    final storage = StorageInfo(
      totalBytes: int.parse(values[1]),
      usedBytes: int.parse(values[2]),
      freeBytes: int.parse(values[3]),
    );

    _cachedStorage = storage;

    return storage;
  }

  void clearCache() {
    _cachedStorage = null;
  }
}
