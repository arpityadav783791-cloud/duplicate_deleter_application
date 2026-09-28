import 'dart:async';
import 'dart:isolate';

import '../duplicate/duplicate_detector.dart';
import '../duplicate/duplicate_result.dart' as engine;
import '../duplicate/file_scanner.dart';
import '../models/duplicate_file.dart';
import '../models/duplicate_group.dart';

class ScanProgress {
  final String stage;
  final int filesScanned;
  final int? current;
  final int? total;
  final bool done;
  final List<DuplicateGroup> groups;

  const ScanProgress({
    required this.stage,
    required this.filesScanned,
    this.current,
    this.total,
    this.done = false,
    this.groups = const [],
  });

  double? get percentage {
    if (current == null || total == null || total! <= 0) return null;
    return current! / total!;
  }
}

class ScanService {
  Isolate? _isolate;
  SendPort? _commandPort;
  StreamController<ScanProgress>? _controller;

  Stream<ScanProgress> scan(String rootPath) {
    _controller?.close();
    final controller = StreamController<ScanProgress>();
    _controller = controller;

    _start(rootPath, controller);
    return controller.stream;
  }

  Future<void> _start(
    String rootPath,
    StreamController<ScanProgress> controller,
  ) async {
    final events = ReceivePort();
    final ready = Completer<SendPort>();

    late StreamSubscription subscription;
    subscription = events.listen((message) {
      if (message is SendPort) {
        if (!ready.isCompleted) ready.complete(message);
        return;
      }

      if (message is! Map) return;
      final type = message['type'];

      if (type == 'progress') {
        controller.add(
          ScanProgress(
            stage: message['stage'] as String,
            filesScanned: message['filesScanned'] as int,
            current: message['current'] as int?,
            total: message['total'] as int?,
          ),
        );
      } else if (type == 'result') {
        controller.add(
          ScanProgress(
            stage: 'Scan complete',
            filesScanned: message['filesScanned'] as int,
            done: true,
            groups: _decodeGroups(
              List<Map<String, dynamic>>.from(message['groups'] as List),
            ),
          ),
        );
        controller.close();
      } else if (type == 'error') {
        controller.addError(Exception(message['message'] as String));
        controller.close();
      }
    });

    try {
      _isolate = await Isolate.spawn(_worker, {
        'path': rootPath,
        'port': events.sendPort,
      });
      _commandPort = await ready.future;
    } catch (e, st) {
      controller.addError(e, st);
      await controller.close();
    }

    await controller.done;
    _commandPort?.send('cancel');
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _commandPort = null;
    await subscription.cancel();
    events.close();
  }

  Future<void> cancel() async {
    _commandPort?.send('cancel');
  }

  static Future<void> _worker(Map<String, dynamic> args) async {
    final port = args['port'] as SendPort;
    final commands = ReceivePort();
    var cancelled = false;
    commands.listen((message) {
      if (message == 'cancel') cancelled = true;
    });
    port.send(commands.sendPort);

    try {
      final scanner = FileScanner();
      final files = await scanner.scan(
        args['path'] as String,
        onFile: (count) {
          if (cancelled) throw const _Cancelled();
          if (count % 25 == 0) {
            port.send({
              'type': 'progress',
              'stage': 'Discovering files...',
              'filesScanned': count,
              'current': null,
              'total': null,
            });
          }
        },
      );

      if (cancelled) throw const _Cancelled();

      port.send({
        'type': 'progress',
        'stage': 'Grouping files by size...',
        'filesScanned': files.length,
        'current': 0,
        'total': 1,
      });

      final detector = DuplicateDetector();
      final groups = await detector.findDuplicates(
        files,
        onProgress: (stage, current, total) {
          if (cancelled) throw const _Cancelled();
          port.send({
            'type': 'progress',
            'stage': stage,
            'filesScanned': files.length,
            'current': current,
            'total': total,
          });
        },
      );

      port.send({
        'type': 'result',
        'filesScanned': files.length,
        'groups': groups.map(_encodeGroup).toList(),
      });
    } catch (error) {
      port.send({
        'type': 'error',
        'message': error is _Cancelled ? 'Scan cancelled.' : error.toString(),
      });
    } finally {
      commands.close();
    }
  }

  static Map<String, dynamic> _encodeGroup(engine.DuplicateGroup group) => {
    'hash': group.hash,
    'size': group.size,
    'files': group.files
        .map(
          (file) => {
            'path': file.path,
            'name': file.name,
            'size': file.size,
            'extension': file.extension,
            'modified': file.modified.millisecondsSinceEpoch,
          },
        )
        .toList(),
  };

  static List<DuplicateGroup> _decodeGroups(List<Map<String, dynamic>> data) {
    return data
        .map(
          (group) => DuplicateGroup(
            hash: group['hash'] as String,
            size: group['size'] as int,
            files: (group['files'] as List)
                .map(
                  (file) => DuplicateFile(
                    path: file['path'] as String,
                    name: file['name'] as String,
                    size: file['size'] as int,
                    extension: file['extension'] as String,
                    modified: DateTime.fromMillisecondsSinceEpoch(
                      file['modified'] as int,
                    ),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}
