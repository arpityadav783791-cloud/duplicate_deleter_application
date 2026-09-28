import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/scan_service.dart';
import '../../core/services/storage_service.dart';
import '../results/category_results_screen.dart';

enum ScanSource { device, folder }

class ScanningScreen extends StatefulWidget {
  final ScanSource source;
  final String? selectedFolder;

  const ScanningScreen({super.key, required this.source, this.selectedFolder});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  final ScanService _scanService = ScanService();
  final StorageService _storageService = StorageService();

  StreamSubscription<ScanProgress>? _subscription;

  String _stage = 'Preparing scan...';
  int _filesScanned = 0;
  double? _progress;
  bool _scanning = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  Future<void> _startScan() async {
    String? rootPath;

    if (widget.source == ScanSource.folder) {
      rootPath = widget.selectedFolder;

      if (rootPath == null || rootPath.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          _scanning = false;
          _error = 'No folder was selected.';
        });

        return;
      }
    } else {
      rootPath = _storageService.defaultStoragePath;
    }

    _subscription = _scanService
        .scan(rootPath)
        .listen(
          (progress) {
            if (!mounted) return;

            setState(() {
              _stage = progress.stage;
              _filesScanned = progress.filesScanned;
              _progress = progress.percentage;
            });

            if (progress.done) {
              _openResults(progress);
            }
          },
          onError: (Object error) {
            if (!mounted) return;

            setState(() {
              _scanning = false;
              _error = _cleanError(error);
            });
          },
          onDone: () {
            if (!mounted) return;

            setState(() {
              _scanning = false;
            });
          },
        );
  }

  void _openResults(ScanProgress progress) {
    if (!mounted) return;

    _scanning = false;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryResultsScreen(
          duplicateGroups: progress.groups,
          scannedFiles: progress.filesScanned,
        ),
      ),
    );
  }

  Future<void> _cancelScan() async {
    await _scanService.cancel();

    if (!mounted) return;

    Navigator.pop(context);
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scanService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildError(context);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.source == ScanSource.device ? 'Device Scan' : 'Folder Scan',
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_rounded, size: 44),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Scanning for duplicate files',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 24),

                    LinearProgressIndicator(minHeight: 10, value: _progress),

                    const SizedBox(height: 12),

                    if (_progress != null)
                      Text(
                        '${(_progress! * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      )
                    else
                      const Text(
                        'Scanning...',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),

                    const SizedBox(height: 22),

                    Text(
                      'Files scanned: $_filesScanned',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _stage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),

                    if (widget.selectedFolder != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.selectedFolder!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    OutlinedButton.icon(
                      onPressed: _scanning ? _cancelScan : null,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel Scan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 20),
              const Text(
                'Unable to complete scan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
