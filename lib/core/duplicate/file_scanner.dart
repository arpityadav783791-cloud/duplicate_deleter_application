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
    '.gradle',
  };
  Future<List<DuplicateFile>> scan(
    String folderPath, {
    void Function(int count)? onFile,
  }) async {
    final dir = Directory(folderPath);
    if (!await dir.exists())
      throw Exception('Folder not accessible: $folderPath');
    final files = <DuplicateFile>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        final parts = entity.path.split(Platform.pathSeparator);
        if (parts.any(excludedDirectories.contains)) continue;
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
        onFile?.call(files.length);
      } on FileSystemException {
        // skip the file that cannot be accessed.
      }
    }
    return files;
  }

  String _extension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final i = name.lastIndexOf('.');
    return i <= 0 ? '' : name.substring(i).toLowerCase();
  }
}
