import 'dart:io';

import 'duplicate_result.dart';

class FileScanner {
  static const excludedDirectories = {
    '.git',
    '.dart_tool',
    'build',
    'node_modules',
    '__pycache__',
    '.venv',
    'venv',
  };

  Future<List<DuplicateFile>> scan(String folderPath) async {
    final directory = Directory(folderPath);

    if (!await directory.exists()) {
      throw Exception('Folder not found: $folderPath');
    }

    final files = <DuplicateFile>[];

    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      try {
        final parts = entity.path.split(Platform.pathSeparator);

        if (parts.any(excludedDirectories.contains)) {
          continue;
        }

        final stat = await entity.stat();

        files.add(
          DuplicateFile(
            path: entity.path,
            name: entity.uri.pathSegments.last,
            size: stat.size,
            extension: _extension(entity.path),
            modified: stat.modified,
          ),
        );
      } on FileSystemException {
        continue;
      }
    }

    return files;
  }

  String _extension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final index = name.lastIndexOf('.');

    if (index <= 0) return '';

    return name.substring(index).toLowerCase();
  }
}