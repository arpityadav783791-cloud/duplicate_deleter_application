import 'dart:io';

import 'package:duplicate_deleter_application/core/duplicate/duplicate_detector.dart';
import 'package:duplicate_deleter_application/core/duplicate/file_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects duplicate files', () async {
    final scanner = FileScanner();
    final detector = DuplicateDetector();

    final files = await scanner.scan('test_duplicate_files');

    final duplicates = await detector.findDuplicates(files);

    expect(files.length, 4);
    expect(duplicates.length, 1);
    expect(duplicates.first.files.length, 2);

    expect(
      duplicates.first.files.map((file) => file.name),
      containsAll(['file1.txt', 'file1_copy.txt']),
    );

    final directory = Directory('test_duplicate_files');

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
}
