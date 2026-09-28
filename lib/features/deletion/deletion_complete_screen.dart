import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/models/duplicate_group.dart';
import '../home/home_screen.dart';
import '../results/category_results_screen.dart';
import 'deletion_mode.dart';

class DeletionCompleteScreen extends StatelessWidget {
  final int deletedCount;
  final int recoveredBytes;
  final int failedCount;

  final DeletionMode deletionMode;
  final List<DuplicateGroup>? sourceGroups;
  final int? scannedFiles;
  final Set<String> successfullyDeletedPaths;

  const DeletionCompleteScreen({
    super.key,
    required this.deletedCount,
    required this.recoveredBytes,
    required this.failedCount,
    required this.deletionMode,
    this.sourceGroups,
    this.scannedFiles,
    this.successfullyDeletedPaths = const {},
  });

  List<DuplicateGroup> _remainingGroups() {
    if (sourceGroups == null) {
      return [];
    }

    final remainingGroups = <DuplicateGroup>[];

    for (final group in sourceGroups!) {
      final remainingFiles = group.files
          .where((file) => !successfullyDeletedPaths.contains(file.path))
          .toList();

      if (remainingFiles.length >= 2) {
        remainingGroups.add(
          DuplicateGroup(
            hash: group.hash,
            size: group.size,
            files: remainingFiles,
          ),
        );
      }
    }

    return remainingGroups;
  }

  void _finish(BuildContext context) {
    if (deletionMode == DeletionMode.global) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );

      return;
    }

    final remainingGroups = _remainingGroups();

    // No duplicate groups remain anywhere.
    if (remainingGroups.isEmpty) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );

      return;
    }

    // Other duplicate categories/groups still remain.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryResultsScreen(
          duplicateGroups: remainingGroups,
          scannedFiles: scannedFiles ?? 0,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partial = failedCount > 0;

    final remainingGroups = deletionMode == DeletionMode.category
        ? _remainingGroups()
        : <DuplicateGroup>[];

    final goesHome =
        deletionMode == DeletionMode.global || remainingGroups.isEmpty;

    final Color statusColor = partial
        ? Colors.orange.shade700
        : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Result icon
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    partial
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    size: 62,
                    color: statusColor,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  partial ? 'Deletion completed' : 'Files deleted successfully',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  partial
                      ? 'Some files could not be removed.'
                      : 'Your selected duplicate files have been removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.black.withAlpha(125),
                  ),
                ),

                const SizedBox(height: 30),

                // Summary card
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
                      _ResultRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Files deleted',
                        value: '$deletedCount',
                        color: theme.colorScheme.primary,
                      ),

                      const SizedBox(height: 18),

                      Divider(height: 1, color: Colors.black.withAlpha(10)),

                      const SizedBox(height: 18),

                      _ResultRow(
                        icon: Icons.storage_rounded,
                        label: 'Storage recovered',
                        value: MockData.formatBytes(recoveredBytes),
                        color: theme.colorScheme.primary,
                      ),

                      if (partial) ...[
                        const SizedBox(height: 18),

                        Divider(height: 1, color: Colors.black.withAlpha(10)),

                        const SizedBox(height: 18),

                        _ResultRow(
                          icon: Icons.warning_amber_rounded,
                          label: 'Files not deleted',
                          value: '$failedCount',
                          color: Colors.orange.shade700,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Partial deletion notice
                if (partial)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withAlpha(35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$failedCount selected '
                            '${failedCount == 1 ? 'file was' : 'files were'} '
                            'not deleted. They may be inaccessible or '
                            'protected by the system.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Back to Home
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _finish(context),
                    icon: Icon(
                      goesHome
                          ? Icons.home_rounded
                          : Icons.cleaning_services_rounded,
                    ),
                    label: Text(
                      goesHome ? 'Back to Home' : 'Continue Cleaning',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Storage information will refresh on the home screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withAlpha(95),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 21, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withAlpha(125),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
