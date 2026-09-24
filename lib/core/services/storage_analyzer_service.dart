import 'dart:io';

import '../models/storage_category.dart';

class StorageAnalyzerService {
  static const _categories = {
    'Documents': {
      '.pdf',
      '.doc',
      '.docx',
      '.txt',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.csv',
    },
    'Images': {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'},
    'Videos': {'.mp4', '.mkv', '.avi', '.mov', '.webm', '.flv'},
    'Audio': {'.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a'},
  };

  static const _excludedDirectories = {
    '.cache',
    '.config',
    '.local',
    '.git',
    '.dart_tool',
    'build',
    'node_modules',
    '__pycache__',
    '.gradle',
  };

  Future<List<StorageCategory>> analyze() async {
    final folders = _getUserFolders();

    final sizes = <String, int>{
      'Documents': 0,
      'Images': 0,
      'Videos': 0,
      'Audio': 0,
      'Other': 0,
    };

    for (final folder in folders) {
      if (!await Directory(folder).exists()) {
        continue;
      }

      await _scanDirectory(Directory(folder), sizes);
    }

    return sizes.entries
        .map(
          (entry) => StorageCategory(name: entry.key, sizeBytes: entry.value),
        )
        .toList();
  }

  List<String> _getUserFolders() {
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home == null) return [];

      return [
        '$home/Documents',
        '$home/Downloads',
        '$home/Pictures',
        '$home/Videos',
        '$home/Music',
        '$home/Desktop',
      ];
    }

    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) return [];

      return [
        '$userProfile\\Documents',
        '$userProfile\\Downloads',
        '$userProfile\\Pictures',
        '$userProfile\\Videos',
        '$userProfile\\Music',
        '$userProfile\\Desktop',
      ];
    }

    if (Platform.isAndroid) {
      return [
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Music',
      ];
    }

    return [];
  }

  Future<void> _scanDirectory(
    Directory directory,
    Map<String, int> sizes,
  ) async {
    try {
      await for (final entity in directory.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;

          if (_excludedDirectories.contains(name)) {
            continue;
          }

          await _scanDirectory(entity, sizes);
          continue;
        }

        if (entity is! File) continue;

        try {
          final extension = _getExtension(entity.path);
          final size = await entity.length();

          final category = _getCategory(extension);

          sizes[category] = sizes[category]! + size;
        } on FileSystemException {
          continue;
        }
      }
    } on FileSystemException {
      // Ignore inaccessible directories.
    }
  }

  String _getCategory(String extension) {
    for (final entry in _categories.entries) {
      if (entry.value.contains(extension)) {
        return entry.key;
      }
    }

    return 'Other';
  }

  String _getExtension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final index = name.lastIndexOf('.');

    if (index <= 0) return '';

    return name.substring(index).toLowerCase();
  }
}
