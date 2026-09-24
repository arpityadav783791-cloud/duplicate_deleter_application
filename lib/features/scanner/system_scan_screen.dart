import 'dart:isolate';

import 'package:flutter/material.dart';

import '../../core/duplicate/duplicate_detector.dart';
import '../../core/duplicate/duplicate_result.dart';
import '../../core/duplicate/file_scanner.dart';
import '../results/results_screen.dart';

class SystemScanScreen extends StatefulWidget {
  final String scanPath;

  const SystemScanScreen({super.key, required this.scanPath});

  @override
  State<SystemScanScreen> createState() => _SystemScanScreenState();
}

class _SystemScanScreenState extends State<SystemScanScreen> {
  bool _scanning = true;
  String _status = 'Scanning for duplicate files...';

  @override
  void initState() {
    super.initState();
    _startScan(widget.scanPath);
  }

  Future<void> _startScan(String scanPath) async {
    try {
      final result = await _runDuplicateScan(scanPath);

      if (!mounted) return;

      final groups = (result['groups'] as List)
          .map((group) => _groupFromMap(Map<String, dynamic>.from(group)))
          .toList();

      final scannedFiles = result['scannedFiles'] as int;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            duplicateGroups: groups,
            scannedFiles: scannedFiles,
            autoSelectDuplicates: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _scanning = false;
        _status = 'Scan failed: $error';
      });
    }
  }

  Future<Map<String, dynamic>> _runDuplicateScan(String scanPath) async {
    return Isolate.run(() async {
      final scanner = FileScanner();
      final detector = DuplicateDetector();

      final files = await scanner.scan(scanPath);
      final duplicates = await detector.findDuplicates(files);

      return {
        'scannedFiles': files.length,
        'groups': duplicates.map((group) {
          return {
            'hash': group.hash,
            'size': group.size,
            'files': group.files.map((file) {
              return {
                'path': file.path,
                'name': file.name,
                'size': file.size,
                'extension': file.extension,
                'modified': file.modified.millisecondsSinceEpoch,
              };
            }).toList(),
          };
        }).toList(),
      };
    });
  }

  DuplicateGroup _groupFromMap(Map<String, dynamic> data) {
    final files = (data['files'] as List).map((file) {
      final map = Map<String, dynamic>.from(file);

      return DuplicateFile(
        path: map['path'] as String,
        name: map['name'] as String,
        size: map['size'] as int,
        extension: map['extension'] as String,
        modified: DateTime.fromMillisecondsSinceEpoch(map['modified'] as int),
      );
    }).toList();

    return DuplicateGroup(
      hash: data['hash'] as String,
      size: data['size'] as int,
      files: files,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Scan')),
      body: Center(
        child: _scanning
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'Scanning for duplicate files...',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text('Please wait while we scan your files.'),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_status, textAlign: TextAlign.center),
              ),
      ),
    );
  }
}
