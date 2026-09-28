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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final info = await _storageService.getStorageInfo(
        _storageService.defaultStoragePath,
      );

      if (!mounted) return;

      setState(() {
        _storageInfo = info;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to read storage information.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return _LoadingCard(theme: theme);
    }

    if (_storageInfo == null) {
      return _ErrorCard(
        message: _error ?? 'Unable to read storage information.',
        onRetry: _loadStorage,
      );
    }

    final info = _storageInfo!;
    final percentage = info.usagePercentage.clamp(0.0, 1.0);
    final percentageText = '${(percentage * 100).round()}%';

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.storage_rounded,
                  color: theme.colorScheme.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage overview',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Current device storage',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  percentageText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 11,
              value: percentage,
              backgroundColor: theme.colorScheme.primary.withAlpha(14),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Storage stats
          Row(
            children: [
              Expanded(
                child: _StorageStat(
                  label: 'Used',
                  value: _formatBytes(info.usedBytes),
                  icon: Icons.folder_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _StorageStat(
                  label: 'Free',
                  value: _formatBytes(info.freeBytes),
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: _StorageStat(
                  label: 'Total',
                  value: _formatBytes(info.totalBytes),
                  icon: Icons.storage_rounded,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
        ],
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
  final IconData icon;
  final Color color;

  const _StorageStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withAlpha(115),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final ThemeData theme;

  const _LoadingCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withAlpha(12)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.redAccent.withAlpha(30)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storage_rounded, color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          const Text(
            'Storage unavailable',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black.withAlpha(115)),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
