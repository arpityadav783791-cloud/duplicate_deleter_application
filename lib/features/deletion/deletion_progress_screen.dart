import 'package:flutter/material.dart';

import '../../core/models/duplicate_file.dart';
import '../../core/services/file_delete_service.dart';
import 'deletion_complete_screen.dart';

class DeletionProgressScreen extends StatefulWidget {
  final List<DuplicateFile> selectedFiles;
  const DeletionProgressScreen({super.key, required this.selectedFiles});
  @override
  State<DeletionProgressScreen> createState() => _DeletionProgressScreenState();
}

class _DeletionProgressScreenState extends State<DeletionProgressScreen> {
  final _service = FileDeleteService();
  int _done = 0, _recovered = 0;
  String _status = 'Preparing deletion...';
  bool _started = false;
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    final results = await _service.deleteFiles(
      widget.selectedFiles.map((f) => f.path).toList(),
      onProgress: (done, total, r) {
        if (!mounted) return;
        setState(() {
          _done = done;
          if (r.success) {
            _recovered += r.bytes;
          }
          _status = r.success
              ? 'Deleted ${r.path.split('/').last}'
              : 'Could not delete ${r.path.split('/').last}';
        });
      },
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeletionCompleteScreen(
          deletedCount: results.where((r) => r.success).length,
          recoveredBytes: results.fold(
            0,
            (s, r) => s + (r.success ? r.bytes : 0),
          ),
          failedCount: results.where((r) => !r.success).length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final total = widget.selectedFiles.length;
    final p = total == 0 ? 1.0 : _done / total;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deleting files'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_sweep_rounded, size: 68),
                const SizedBox(height: 24),
                const Text(
                  'Deleting files...',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(minHeight: 10, value: p),
                const SizedBox(height: 12),
                Text('${(p * 100).round()}%'),
                const SizedBox(height: 18),
                Text('$_done / $total files'),
                const SizedBox(height: 6),
                Text(
                  '${_format(_recovered)} recovered',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  _status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _format(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) {
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
