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

  int _done = 0;
  int _recovered = 0;

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
      onProgress: (done, total, result) {
        if (!mounted) return;

        setState(() {
          _done = done;

          if (result.success) {
            _recovered += result.bytes;
          }

          final fileName = result.path.split('/').last;

          _status = result.success
              ? 'Deleted $fileName'
              : 'Could not delete $fileName';
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
            (sum, r) => sum + (r.success ? r.bytes : 0),
          ),
          failedCount: results.where((r) => !r.success).length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = widget.selectedFiles.length;

    final progress = total == 0 ? 1.0 : (_done / total).clamp(0.0, 1.0);

    final percentage = (progress * 100).round();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: const Text(
            'Deleting Files',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                const Spacer(),

                // Main progress icon
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withAlpha(16),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 108,
                        height: 108,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5,
                          backgroundColor: theme.colorScheme.error.withAlpha(
                            18,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.error,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.delete_sweep_rounded,
                        size: 42,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Deleting files...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Please wait while the selected files are being removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black.withAlpha(125),
                  ),
                ),

                const SizedBox(height: 30),

                // Progress card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.black.withAlpha(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: progress,
                          backgroundColor: theme.colorScheme.primary.withAlpha(
                            18,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: _ProgressStat(
                              icon: Icons.description_rounded,
                              label: 'Files',
                              value: '$_done / $total',
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            color: Colors.black.withAlpha(12),
                          ),
                          Expanded(
                            child: _ProgressStat(
                              icon: Icons.storage_rounded,
                              label: 'Recovered',
                              value: _format(_recovered),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Current status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          _status,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withAlpha(140),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom information
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: Colors.black.withAlpha(90),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Deletion is in progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withAlpha(100),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _format(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _ProgressStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProgressStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.black.withAlpha(110)),
        ),
      ],
    );
  }
}
