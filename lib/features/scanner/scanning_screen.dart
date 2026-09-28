import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/android_storage_service.dart';
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
  final AndroidStorageService _androidStorageService = AndroidStorageService();

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
    try {
      if (widget.source == ScanSource.device && Platform.isAndroid) {
        if (!mounted) return;

        setState(() {
          _stage = 'Requesting storage access...';
        });

        final granted = await _androidStorageService.requestScanAccess();

        if (!granted) {
          if (!mounted) return;

          setState(() {
            _scanning = false;
            _error = 'Storage access is required to scan your device.';
          });

          return;
        }
      }

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

      if (!mounted) return;

      setState(() {
        _stage = 'Scanning files...';
        _filesScanned = 0;
        _progress = null;
        _scanning = true;
        _error = null;
      });

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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _scanning = false;
        _error = _cleanError(error);
      });
    }
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

    final theme = Theme.of(context);
    final isFolderScan = widget.source == ScanSource.folder;

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
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(31),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFolderScan
                      ? Icons.folder_rounded
                      : Icons.phone_android_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isFolderScan ? 'Folder Scan' : 'Device Scan',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Scan illustration
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(31),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Scanning for duplicates',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isFolderScan
                          ? 'Checking the selected folder for exact duplicate files.'
                          : 'Checking your accessible storage for exact duplicate files.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.black.withAlpha(133),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Progress card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withAlpha(13)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.radar_rounded,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _stage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _progress != null
                                    ? '${(_progress! * 100).round()}%'
                                    : '...',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              minHeight: 9,
                              value: _progress,
                              backgroundColor: theme.colorScheme.primary
                                  .withAlpha(20),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Icon(
                                Icons.insert_drive_file_outlined,
                                size: 18,
                                color: Colors.black.withAlpha(115),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Files scanned',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withAlpha(133),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$_filesScanned',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (widget.selectedFolder != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 18,
                              color: Colors.black.withAlpha(115),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                widget.selectedFolder!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black.withAlpha(133),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _scanning ? _cancelScan : null,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text(
                          'Cancel Scan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.black.withAlpha(31)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'You can cancel the scan at any time.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withAlpha(100),
                      ),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Scan Error',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Unable to complete scan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black.withAlpha(133),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _androidStorageService.openStorageSettings,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Open Storage Settings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
