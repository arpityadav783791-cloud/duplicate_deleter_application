import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class FileHasher {
  static const int sampleSize = 64 * 1024; // 64 KB

  Future<String> calculateQuickHash(String filePath) async {
    final file = File(filePath);
    final length = await file.length();

    final bytes = <int>[];

    final firstLength = length < sampleSize ? length : sampleSize;

    bytes.addAll(
      await file
          .openRead(0, firstLength)
          .fold<List<int>>([], (previous, chunk) => previous..addAll(chunk)),
    );

    if (length > sampleSize) {
      final start = length - sampleSize;

      bytes.addAll(
        await file
            .openRead(start, length)
            .fold<List<int>>([], (previous, chunk) => previous..addAll(chunk)),
      );
    }

    return sha256.convert(bytes).toString();
  }

  Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    final sink = AccumulatorSink<Digest>();
    final converter = sha256.startChunkedConversion(sink);

    await for (final chunk in file.openRead()) {
      converter.add(chunk);
    }

    converter.close();

    return sink.events.single.toString();
  }
}
