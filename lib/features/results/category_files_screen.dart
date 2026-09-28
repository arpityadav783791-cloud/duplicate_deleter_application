import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/models/duplicate_file.dart';
import '../../core/models/duplicate_group.dart';
import '../deletion/delete_confirmation.dart';
import '../preview/file_preview_screen.dart';
import 'category_results_screen.dart';

class CategoryFilesScreen extends StatefulWidget {
  final String categoryName;
  final List<DuplicateGroup> groups;
  final KeepOneController? keepOneController;

  const CategoryFilesScreen({
    super.key,
    required this.categoryName,
    required this.groups,
    this.keepOneController,
  });

  @override
  State<CategoryFilesScreen> createState() =>
      _CategoryFilesScreenState();
}

class _CategoryFilesScreenState extends State<CategoryFilesScreen> {
  final Set<String> _selected = <String>{};
  final Map<String, String> _keepers = <String, String>{};

  @override
  void initState() {
    super.initState();

    widget.keepOneController?.enabled.addListener(
      _onGlobalKeepOneChanged,
    );

    if (widget.keepOneController?.enabled.value == true) {
      _applyKeepOneToAll();
    }
  }

  @override
  void dispose() {
    widget.keepOneController?.enabled.removeListener(
      _onGlobalKeepOneChanged,
    );

    super.dispose();
  }

  void _onGlobalKeepOneChanged() {
    if (!mounted) {
      return;
    }

    if (widget.keepOneController?.enabled.value == true) {
      _applyKeepOneToAll();
    } else {
      _clearAllKeepers();
    }
  }

  void _applyKeepOneToAll() {
    setState(() {
      _selected.clear();
      _keepers.clear();

      for (final group in widget.groups) {
        if (group.files.isEmpty) {
          continue;
        }

        final keeper = group.files.first;

        _keepers[group.hash] = keeper.path;

        for (final file in group.files) {
          if (file.path != keeper.path) {
            _selected.add(file.path);
          }
        }
      }
    });
  }

  void _clearAllKeepers() {
    setState(() {
      _selected.clear();
      _keepers.clear();
    });
  }

  Iterable<DuplicateFile> get _allFiles {
    return widget.groups.expand((group) => group.files);
  }

  int get _selectedBytes {
    return _allFiles
        .where((file) => _selected.contains(file.path))
        .fold(0, (sum, file) => sum + file.size);
  }

  void _toggleFile(
    DuplicateFile file,
    DuplicateGroup group,
  ) {
    // Keeper can never be selected for deletion.
    if (_keepers[group.hash] == file.path) {
      return;
    }

    setState(() {
      if (_selected.contains(file.path)) {
        _selected.remove(file.path);
      } else {
        _selected.add(file.path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selected.clear();

      for (final group in widget.groups) {
        final keeper = _keepers[group.hash];

        for (final file in group.files) {
          if (file.path != keeper) {
            _selected.add(file.path);
          }
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selected.clear();
    });
  }

  Future<void> _toggleKeepOne(
    DuplicateGroup group,
  ) async {
    final existingKeeper = _keepers[group.hash];

    // ----------------------------------------
    // KEEP ONE -> OFF
    // ----------------------------------------
    if (existingKeeper != null) {
      setState(() {
        _keepers.remove(group.hash);

        for (final file in group.files) {
          _selected.remove(file.path);
        }
      });

      return;
    }

    // ----------------------------------------
    // KEEP ONE -> ON
    // ----------------------------------------
    final selected = await showModalBottomSheet<DuplicateFile>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Keep One Copy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the file that should remain on your device.',
              ),
              const SizedBox(height: 12),
              ...group.files.map(
                (file) => ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline_rounded,
                  ),
                  title: Text(file.name),
                  subtitle: Text(
                    file.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context, file);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _keepers[group.hash] = selected.path;

      for (final file in group.files) {
        if (file.path == selected.path) {
          _selected.remove(file.path);
        } else {
          _selected.add(file.path);
        }
      }
    });
  }

  Future<void> _openDeleteConfirmation() async {
    if (_selected.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeleteConfirmationScreen(
          selectedFiles: _allFiles
              .where((file) => _selected.contains(file.path))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'select') {
                _selectAll();
              } else {
                _deselectAll();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'select',
                child: Text('Select all'),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Text('Deselect all'),
              ),
            ],
          ),
        ],
      ),

      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16,
                ),
                child: FilledButton.icon(
                  onPressed: _openDeleteConfirmation,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                  ),
                  label: Text(
                    'Delete ${_selected.length} • '
                    '${MockData.formatBytes(_selectedBytes)}',
                  ),
                ),
              ),
            ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        children: widget.groups.map((group) {
          final hasKeeper = _keepers.containsKey(group.hash);

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.copy_all_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duplicate group • '
                          '${MockData.formatBytes(group.size)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (hasKeeper)
                        FilledButton.icon(
                          onPressed: () => _toggleKeepOne(group),
                          icon: const Icon(
                            Icons.check_rounded,
                            size: 18,
                          ),
                          label: const Text('Keep One'),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _toggleKeepOne(group),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Keep One'),
                        ),
                    ],
                  ),

                  const Divider(),

                  ...group.files.map((file) {
                    final isKeeper =
                        _keepers[group.hash] == file.path;

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical: 2,
                      ),

                      leading: Icon(
                        _isImage(file.extension)
                            ? Icons.image_rounded
                            : Icons.insert_drive_file_rounded,
                      ),

                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      subtitle: Text(
                        '${file.path}\n'
                        '${MockData.formatBytes(file.size)} • '
                        '${file.modified.day}/'
                        '${file.modified.month}/'
                        '${file.modified.year}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      isThreeLine: true,

                      trailing: isKeeper
                          ? const Chip(
                              avatar: Icon(
                                Icons.check,
                                size: 16,
                              ),
                              label: Text('KEEP'),
                            )
                          : Checkbox(
                              value: _selected.contains(
                                file.path,
                              ),
                              onChanged: (_) {
                                _toggleFile(file, group);
                              },
                            ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FilePreviewScreen(
                              file: file,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isImage(String extension) {
    return const {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
    }.contains(extension);
  }
}