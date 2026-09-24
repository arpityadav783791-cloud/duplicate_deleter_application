import 'dart:io';

import 'duplicate_result.dart';
import 'file_hasher.dart';

class DuplicateDetector {
  final FileHasher _hasher;

  DuplicateDetector({FileHasher? hasher}) : _hasher = hasher ?? FileHasher();

  Future<List<DuplicateGroup>> findDuplicates(List<DuplicateFile> files) async {
    // Stage 1: group by file size.
    final sizeGroups = <int, List<DuplicateFile>>{};

    for (final file in files) {
      sizeGroups.putIfAbsent(file.size, () => []).add(file);
    }

    final duplicateGroups = <DuplicateGroup>[];

    for (final sizeEntry in sizeGroups.entries) {
      final sameSizeFiles = sizeEntry.value;

      if (sameSizeFiles.length < 2) {
        continue;
      }

      // Stage 2: quick hash.
      final quickHashGroups = <String, List<DuplicateFile>>{};

      for (final file in sameSizeFiles) {
        try {
          final hash = await _hasher.calculateQuickHash(file.path);

          quickHashGroups.putIfAbsent(hash, () => []).add(file);
        } on FileSystemException {
          continue;
        }
      }

      // Stage 3: full SHA-256 only for candidates.
      for (final quickEntry in quickHashGroups.entries) {
        final candidates = quickEntry.value;

        if (candidates.length < 2) {
          continue;
        }

        final fullHashGroups = <String, List<DuplicateFile>>{};

        for (final file in candidates) {
          try {
            final hash = await _hasher.calculateSha256(file.path);

            fullHashGroups.putIfAbsent(hash, () => []).add(file);
          } on FileSystemException {
            continue;
          }
        }

        for (final hashEntry in fullHashGroups.entries) {
          if (hashEntry.value.length < 2) {
            continue;
          }

          duplicateGroups.add(
            DuplicateGroup(
              hash: hashEntry.key,
              size: sizeEntry.key,
              files: List.unmodifiable(hashEntry.value),
            ),
          );
        }
      }
    }

    return List.unmodifiable(duplicateGroups);
  }
}
