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
    _keepOneController.enabled.value = !_keepOneController.enabled.value;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _groupByCategory();

    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate results')),
      body: widget.duplicateGroups.isEmpty
          ? const _EmptyResults()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  '${widget.scannedFiles} files scanned',
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------
                // GLOBAL KEEP ONE TOGGLE
                // ------------------------------------------
                ValueListenableBuilder<bool>(
                  valueListenable: _keepOneController.enabled,
                  builder: (context, enabled, _) {
                    return Card(
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _toggleGlobalKeepOne,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                enabled
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 28,
                                color: enabled
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Keep One for All',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      enabled
                                          ? 'One copy kept from every duplicate group'
                                          : 'Keep one copy from every duplicate group',
                                      style: TextStyle(
                                        color: enabled
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

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
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ------------------------------------------
                // CATEGORIES
                // ------------------------------------------
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 72),
            SizedBox(height: 20),
            Text(
              'No duplicate files found',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
