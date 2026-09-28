import 'dart:io';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
class FileHasher {
  static const sampleSize=64*1024;
  Future<String> calculateQuickHash(String path) async {
    final f=File(path); final len=await f.length(); final bytes=<int>[];
    await for(final c in f.openRead(0,len<sampleSize?len:sampleSize)) { bytes.addAll(c); }
    if(len>sampleSize) { await for(final c in f.openRead(len-sampleSize,len)) { bytes.addAll(c); } }
    return sha256.convert(bytes).toString();
  }
  Future<String> calculateSha256(String path) async {
    final sink=AccumulatorSink<Digest>(); final converter=sha256.startChunkedConversion(sink);
    await for(final c in File(path).openRead()) { converter.add(c); }
    converter.close(); return sink.events.single.toString();
  }
}
