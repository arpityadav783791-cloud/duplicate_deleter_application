import 'package:flutter/material.dart';

import '../../../core/models/storage_info.dart';
import '../../../core/services/storage_service.dart';

class StorageOverviewCard extends StatefulWidget {
  const StorageOverviewCard({super.key});

  @override
  State<StorageOverviewCard> createState() => _StorageOverviewCardState();
}

class _StorageOverviewCardState extends State<StorageOverviewCard> {
  final StorageService _storageService = StorageService();

  StorageInfo? _storageInfo;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    try {
      final info = await _storageService.getStorageInfo(
        _storageService.defaultStoragePath,
      );

      if (!mounted) return;

      setState(() {
        _storageInfo = info;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to read storage information.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_storageInfo == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    child: Icon(Icons.storage_rounded),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Storage overview',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Unable to read storage information.',
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadStorage,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final info = _storageInfo!;
    final percentage = info.usagePercentage.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.storage_rounded),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Storage overview',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(percentage * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: percentage,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _StorageStat(
                  label: 'Used',
                  value: _formatBytes(info.usedBytes),
                ),
                _StorageStat(
                  label: 'Free',
                  value: _formatBytes(info.freeBytes),
                ),
                _StorageStat(
                  label: 'Total',
                  value: _formatBytes(info.totalBytes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
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

class _StorageStat extends StatelessWidget {
  final String label;
  final String value;

  const _StorageStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}