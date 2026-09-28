import 'package:duplicate_deleter_application/features/deletion/delete_confirmation.dart';
import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/models/duplicate_file.dart';
import '../../core/models/duplicate_group.dart';
import '../deletion/deletion_mode.dart';
import 'category_files_screen.dart';
import 'widgets/category_result_card.dart';

class KeepOneController {
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  final ValueNotifier<List<DuplicateFile>> selectedFiles =
      ValueNotifier<List<DuplicateFile>>([]);

  void dispose() {
    enabled.dispose();
    selectedFiles.dispose();
  }
}

class CategoryResultsScreen extends StatefulWidget {
  final List<DuplicateGroup> duplicateGroups;
  final int scannedFiles;

  const CategoryResultsScreen({
    super.key,
    required this.duplicateGroups,
    required this.scannedFiles,
  });

  @override
  State<CategoryResultsScreen> createState() => _CategoryResultsScreenState();
}

class _CategoryResultsScreenState extends State<CategoryResultsScreen> {
  late final KeepOneController _keepOneController;

  @override
  void initState() {
    super.initState();
    _keepOneController = KeepOneController();
  }

  @override
  void dispose() {
    _keepOneController.dispose();
    super.dispose();
  }

  void _toggleGlobalKeepOne() {
    final nextValue = !_keepOneController.enabled.value;

    _keepOneController.enabled.value = nextValue;

    if (nextValue) {
      _applyGlobalKeepOne();
    } else {
      _keepOneController.selectedFiles.value = [];
    }
  }

  void _openGlobalDelete() {
    final selected = _keepOneController.selectedFiles.value;

    if (selected.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeleteConfirmationScreen(
          selectedFiles: selected,
          deletionMode: DeletionMode.global,
        ),
      ),
    );
  }

  void _applyGlobalKeepOne() {
    final filesToDelete = <DuplicateFile>[];

    for (final group in widget.duplicateGroups) {
      if (group.files.length <= 1) {
        continue;
      }

      // Keep the first file from every duplicate group.
      for (var index = 1; index < group.files.length; index++) {
        filesToDelete.add(group.files[index]);
      }
    }

    _keepOneController.selectedFiles.value = filesToDelete;
  }

  int _totalSelectedBytes(List<DuplicateFile> files) {
    return files.fold(0, (sum, file) => sum + file.size);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _groupByCategory();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Duplicate Results',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: widget.duplicateGroups.isEmpty
          ? const _EmptyResults()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                // Results summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withAlpha(209),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(40),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(36),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.copy_all_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duplicates found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.duplicateGroups.length} groups',
                              style: TextStyle(
                                color: Colors.white.withAlpha(224),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.scannedFiles} files scanned',
                              style: TextStyle(
                                color: Colors.white.withAlpha(190),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // GLOBAL KEEP ONE
                ValueListenableBuilder<bool>(
                  valueListenable: _keepOneController.enabled,
                  builder: (context, enabled, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: enabled
                            ? theme.colorScheme.primary.withAlpha(12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: enabled
                              ? theme.colorScheme.primary.withAlpha(45)
                              : Colors.black.withAlpha(13),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _toggleGlobalKeepOne,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: enabled
                                        ? theme.colorScheme.primary.withAlpha(
                                            25,
                                          )
                                        : Colors.black.withAlpha(7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    enabled
                                        ? Icons.verified_rounded
                                        : Icons.shield_outlined,
                                    color: enabled
                                        ? theme.colorScheme.primary
                                        : Colors.black.withAlpha(125),
                                    size: 23,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Keep One for All',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      ValueListenableBuilder<
                                        List<DuplicateFile>
                                      >(
                                        valueListenable:
                                            _keepOneController.selectedFiles,
                                        builder: (context, selectedFiles, _) {
                                          if (!_keepOneController
                                                  .enabled
                                                  .value ||
                                              selectedFiles.isEmpty) {
                                            return const SizedBox.shrink();
                                          }

                                          final totalBytes = selectedFiles
                                              .fold<int>(
                                                0,
                                                (sum, file) => sum + file.size,
                                              );

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              height: 54,
                                              child: FilledButton.icon(
                                                onPressed: _openGlobalDelete,
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                ),
                                                label: Text(
                                                  'Delete All • ${MockData.formatBytes(totalBytes)}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        enabled
                                            ? 'One copy kept from every duplicate group.'
                                            : 'Keep one copy from every duplicate group.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.35,
                                          color: enabled
                                              ? theme.colorScheme.primary
                                              : Colors.black.withAlpha(133),
                                          fontWeight: enabled
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Switch(
                                  value: enabled,
                                  onChanged: (_) {
                                    _toggleGlobalKeepOne();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  'Duplicate categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Choose a category to review its duplicate files.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withAlpha(133),
                  ),
                ),

                const SizedBox(height: 14),

                ...categories.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CategoryResultCard(
                      name: entry.key,
                      icon: _iconFor(entry.key),
                      groups: entry.value,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryFilesScreen(
                              categoryName: entry.key,
                              groups: entry.value,
                              allDuplicateGroups: widget.duplicateGroups,
                              scannedFiles: widget.scannedFiles,
                              keepOneController: _keepOneController,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

      // GLOBAL DELETE ACTION
      bottomNavigationBar: ValueListenableBuilder<List<DuplicateFile>>(
        valueListenable: _keepOneController.selectedFiles,
        builder: (context, selectedFiles, _) {
          if (!_keepOneController.enabled.value || selectedFiles.isEmpty) {
            return const SizedBox.shrink();
          }

          final totalBytes = _totalSelectedBytes(selectedFiles);

          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black.withAlpha(12)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(14),
                    blurRadius: 16,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openGlobalDelete,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 22),
                  label: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete ${selectedFiles.length} files',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Recover ${MockData.formatBytes(totalBytes)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(205),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, List<DuplicateGroup>> _groupByCategory() {
    final result = <String, List<DuplicateGroup>>{};

    for (final group in widget.duplicateGroups) {
      for (final file in group.files) {
        final category = _category(file.extension);

        result.putIfAbsent(category, () => []);

        if (!result[category]!.contains(group)) {
          result[category]!.add(group);
        }

        break;
      }
    }

    return result;
  }

  String _category(String extension) {
    const images = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'};

    const videos = {'.mp4', '.mkv', '.avi', '.mov', '.webm', '.flv'};

    const audio = {'.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a'};

    const documents = {
      '.pdf',
      '.doc',
      '.docx',
      '.txt',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.csv',
    };

    if (images.contains(extension)) return 'Images';
    if (videos.contains(extension)) return 'Videos';
    if (audio.contains(extension)) return 'Audio';
    if (documents.contains(extension)) return 'Documents';

    return 'Other Files';
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'Images':
        return Icons.image_rounded;
      case 'Videos':
        return Icons.video_library_rounded;
      case 'Audio':
        return Icons.audiotrack_rounded;
      case 'Documents':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No duplicate files found',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your scanned storage does not contain any exact duplicate files.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.black.withAlpha(125),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
