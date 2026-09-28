import 'package:flutter/material.dart';

import '../../core/models/duplicate_group.dart';
import 'category_files_screen.dart';
import 'widgets/category_result_card.dart';

class KeepOneController {
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  void dispose() {
    enabled.dispose();
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
  State<CategoryResultsScreen> createState() =>
      _CategoryResultsScreenState();
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
    _keepOneController.enabled.value =
        !_keepOneController.enabled.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _groupByCategory();

    final duplicateFileCount = widget.duplicateGroups.fold<int>(
      0,
      (total, group) => total + group.files.length,
    );

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
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
                              '${widget.duplicateGroups.length} groups • '
                              '$duplicateFileCount duplicate files',
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

                // Keep One for All
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
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              15,
                              12,
                              15,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: enabled
                                        ? theme.colorScheme.primary
                                            .withAlpha(25)
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
                                      const SizedBox(height: 4),
                                      Text(
                                        enabled
                                            ? 'One copy will be kept from every group.'
                                            : 'Automatically keep one copy from every group.',
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

                // Category heading
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
                  (entry) => CategoryResultCard(
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
                            keepOneController: _keepOneController,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
    const images = {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
      '.svg',
    };

    const videos = {
      '.mp4',
      '.mkv',
      '.avi',
      '.mov',
      '.webm',
      '.flv',
    };

    const audio = {
      '.mp3',
      '.wav',
      '.aac',
      '.flac',
      '.ogg',
      '.m4a',
    };

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

    if (images.contains(extension)) {
      return 'Images';
    }

    if (videos.contains(extension)) {
      return 'Videos';
    }

    if (audio.contains(extension)) {
      return 'Audio';
    }

    if (documents.contains(extension)) {
      return 'Documents';
    }

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
        padding: const EdgeInsets.all(28),
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

            const SizedBox(height: 22),

            const Text(
              'No duplicate files found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              'Your scanned storage does not contain any exact duplicate files.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.black.withAlpha(133),
              ),
            ),
          ],
        ),
      ),
    );
  }
}