import 'dart:io';

import 'package:duplicate_deleter_application/features/results/results_screen.dart';
import 'package:duplicate_deleter_application/features/scanner/system_scan_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/duplicate/duplicate_detector.dart';
import '../../core/duplicate/file_scanner.dart';
import '../../core/models/storage_category.dart';
import '../../core/models/storage_info.dart';
import '../../core/services/storage_analyzer_service.dart';
import '../../core/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScanning = false;
  String? _selectedFolder;
  int? _fileCount;
  StorageInfo? _storageInfo;
  bool _loadingStorage = true;
  List<StorageCategory> _storageCategories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();

    _loadStorage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyzeStorage();
    });
  }

  void _openSystemScan() {
    String? scanPath;

    if (Platform.isLinux || Platform.isMacOS) {
      scanPath = Platform.environment['HOME'];
    } else if (Platform.isWindows) {
      scanPath = Platform.environment['USERPROFILE'];
    } else if (Platform.isAndroid) {
      scanPath = '/storage/emulated/0';
    }

    if (scanPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System scanning is not supported on this platform.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SystemScanScreen(scanPath: scanPath!)),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    return statuses.values.any((status) => status.isGranted);
  }

  Future<void> _analyzeStorage() async {
    try {
      if (Platform.isAndroid) {
        final allowed = await _requestStoragePermission();

        if (!allowed) {
          return;
        }
      }
      final categories = await StorageAnalyzerService().analyze();
      if (!mounted) return;
      setState(() {
        _storageCategories = categories;
        _loadingCategories = false;
      });
    } catch (error) {
      debugPrint('Storage analyzer error: $error');
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  Future<void> _loadStorage() async {
    final service = StorageService();
    final cached = service.cachedStorage;
    if (cached != null) {
      setState(() {
        _storageInfo = cached;
        _loadingStorage = false;
      });
      return;
    }
    try {
      final storage = await service.getStorageInfo('/');

      if (!mounted) return;

      setState(() {
        _storageInfo = storage;
        _loadingStorage = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingStorage = false;
      });
    }
  }

  Future<void> _selectFolder() async {
    final folderPath = await FilePicker.getDirectoryPath();

    if (folderPath == null) {
      return;
    }

    setState(() {
      _selectedFolder = folderPath;
      _isScanning = true;
      _fileCount = null;
    });

    try {
      final scanner = FileScanner();
      final detector = DuplicateDetector();

      final files = await scanner.scan(folderPath);
      final duplicateGroups = await detector.findDuplicates(files);

      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _fileCount = files.length;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            duplicateGroups: duplicateGroups,
            scannedFiles: files.length,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Scan failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate Cleaner'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.find_in_page_outlined, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Find Duplicate Files',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan your files and find duplicates safely.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _selectFolder,
                  icon: const Icon(Icons.folder_open),
                  label: Text(_isScanning ? 'Scanning...' : 'Select Folder'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: 250,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _openSystemScan,
                  icon: const Icon(Icons.search),
                  label: const Text('Scan System'),
                ),
              ),

              const SizedBox(height: 30),
              if (_loadingStorage)
                const CircularProgressIndicator()
              else if (_storageInfo != null)
                _StorageCard(storageInfo: _storageInfo!),

              const SizedBox(height: 20),

              if (_loadingCategories)
                const CircularProgressIndicator()
              else if (_storageCategories.isNotEmpty)
                _StorageAnalyzerCard(
                  categories: _storageCategories,
                  totalBytes: _storageInfo?.totalBytes ?? 0,
                ),

              if (_selectedFolder != null) ...[
                const SizedBox(height: 30),
                Text(
                  'Selected folder:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(_selectedFolder!, textAlign: TextAlign.center),
              ],

              if (_fileCount != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Files found: $_fileCount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  final StorageInfo storageInfo;

  const _StorageCard({required this.storageInfo});

  String formatBytes(int bytes) {
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = storageInfo.usagePercentage.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage),
                const SizedBox(width: 10),
                Text('Storage', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),

            const SizedBox(height: 16),

            LinearProgressIndicator(value: percentage),

            const SizedBox(height: 12),

            Text(
              '${(percentage * 100).toStringAsFixed(1)}% used',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text('Used: ${formatBytes(storageInfo.usedBytes)}'),
            Text('Free: ${formatBytes(storageInfo.freeBytes)}'),
            Text('Total: ${formatBytes(storageInfo.totalBytes)}'),
          ],
        ),
      ),
    );
  }
}

class _StorageAnalyzerCard extends StatelessWidget {
  final List<StorageCategory> categories;
  final int totalBytes;

  const _StorageAnalyzerCard({
    required this.categories,
    required this.totalBytes,
  });

  String formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Analyzer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            ...categories.map((category) {
              final percentage = category.percentageOf(totalBytes);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(formatBytes(category.sizeBytes)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: percentage.clamp(0.0, 1.0)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
