import 'dart:io';

import 'duplicate_result.dart';
import 'file_hasher.dart';

class DuplicateDetector {
  final FileHasher _hasher;

  DuplicateDetector({
    FileHasher? hasher,
  }) : _hasher = hasher ?? FileHasher();

  Future<List<DuplicateGroup>> findDuplicates(
    List<DuplicateFile> files,
  ) async {
    final sizeGroups = <int, List<DuplicateFile>>{};

    for (final file in files) {
      sizeGroups.putIfAbsent(file.size, () => []).add(file);
    }

    final duplicateGroups = <DuplicateGroup>[];

    for (final entry in sizeGroups.entries) {
      final sameSizeFiles = entry.value;

      if (sameSizeFiles.length < 2) {
        continue;
      }

      final hashGroups = <String, List<DuplicateFile>>{};

      for (final file in sameSizeFiles) {
        try {
          final hash = await _hasher.calculateSha256(file.path);

          hashGroups.putIfAbsent(hash, () => []).add(file);
        } on FileSystemException {
          continue;
        }
      }

      for (final entry in hashGroups.entries) {
        if (entry.value.length < 2) {
          continue;
        }

        duplicateGroups.add(
          DuplicateGroup(
            hash: entry.key,
            size: entry.value.first.size,
            files: List.unmodifiable(entry.value),
          ),
        );
      }
    }

    return List.unmodifiable(duplicateGroups);
  }
}
