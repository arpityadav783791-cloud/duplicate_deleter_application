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
    final root = Directory(folderPath);

    if (!await root.exists()) {
      throw Exception('Folder not accessible: $folderPath');
    }

    final files = <DuplicateFile>[];

    await _scanDirectory(
      root,
      files,
      onFile,
    );

    return files;
  }

  Future<void> _scanDirectory(
    Directory directory,
    List<DuplicateFile> files,
    void Function(int count)? onFile,
  ) async {
    final directoryName = _directoryName(directory.path);

    // Skip known unwanted directories.
    if (excludedDirectories.contains(directoryName)) {
      return;
    }

    List<FileSystemEntity> entities;

    try {
      entities = await directory.list(
        followLinks: false,
      ).toList();
    } on FileSystemException {
      // Directory cannot be accessed.
      // Skip it and continue with the rest of the scan.
      return;
    } on PathAccessException {
      // Android/Linux denied access to this directory.
      return;
    }

    for (final entity in entities) {
      try {
        if (entity is File) {
          await _processFile(
            entity,
            files,
            onFile,
          );
        } else if (entity is Directory) {
          await _scanDirectory(
            entity,
            files,
            onFile,
          );
        }
      } on FileSystemException {
        // Skip this entity and continue scanning.
        continue;
      } on PathAccessException {
        // Skip this entity and continue scanning.
        continue;
      }
    }
  }

  Future<void> _processFile(
    File file,
    List<DuplicateFile> files,
    void Function(int count)? onFile,
  ) async {
    final parts = file.path.split(
      Platform.pathSeparator,
    );

    if (parts.any(excludedDirectories.contains)) {
      return;
    }

    final stat = await file.stat();

    files.add(
      DuplicateFile(
        path: file.path,
        name: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : file.path.split(Platform.pathSeparator).last,
        size: stat.size,
        extension: _extension(file.path),
        modified: stat.modified,
      ),
    );

    onFile?.call(files.length);
  }

  String _directoryName(String path) {
    final normalized = path.replaceAll(
      Platform.pathSeparator,
      '/',
    );

    final trimmed = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;

    final index = trimmed.lastIndexOf('/');

    if (index == -1) {
      return trimmed;
    }

    return trimmed.substring(index + 1);
  }

  String _extension(String path) {
    final name = path.split(
      Platform.pathSeparator,
    ).last;

    final i = name.lastIndexOf('.');

    return i <= 0
        ? ''
        : name.substring(i).toLowerCase();
  }
}