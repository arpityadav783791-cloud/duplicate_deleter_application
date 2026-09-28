import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/models/duplicate_file.dart';
import 'deletion_progress_screen.dart';

class DeleteConfirmationScreen extends StatelessWidget {
  final List<DuplicateFile> selectedFiles;

  const DeleteConfirmationScreen({
    super.key,
    required this.selectedFiles,
  });

  int get totalBytes {
    return selectedFiles.fold(
      0,
      (sum, file) => sum + file.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = selectedFiles.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Warning icon
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withAlpha(18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_forever_rounded,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Delete selected files?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'This will permanently remove the selected '
                        'duplicate files from your storage.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.black.withAlpha(133),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Deletion summary
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black.withAlpha(13),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryItem(
                                icon: Icons.description_rounded,
                                label: 'Files',
                                value: '${selectedFiles.length}',
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 46,
                              color: Colors.black.withAlpha(12),
                            ),
                            Expanded(
                              child: _SummaryItem(
                                icon: Icons.storage_rounded,
                                label: 'Storage',
                                value: MockData.formatBytes(totalBytes),
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Warning card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withAlpha(10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.colorScheme.error.withAlpha(30),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                              size: 23,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'These files will be permanently deleted. '
                                'This action cannot be undone.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!isEmpty) ...[
                        const SizedBox(height: 24),

                        // Selected files preview
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selected files',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        ...selectedFiles.take(3).map(
                          (file) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withAlpha(11),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withAlpha(18),
                                    borderRadius:
                                        BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    Icons.insert_drive_file_rounded,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  MockData.formatBytes(file.size),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black.withAlpha(115),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (selectedFiles.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '+ ${selectedFiles.length - 3} more files',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withAlpha(115),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(
                            color: Colors.black.withAlpha(25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: isEmpty
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DeletionProgressScreen(
                                      selectedFiles: selectedFiles,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(
                          Icons.delete_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'Delete Files',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.black.withAlpha(18),
                          disabledForegroundColor:
                              Colors.black.withAlpha(70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withAlpha(115),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}