import 'package:flutter/material.dart';

import '../../core/mock/mock_data.dart';
import '../../core/models/duplicate_file.dart';
import '../../core/models/duplicate_group.dart';
import '../deletion/delete_confirmation.dart';
import '../deletion/deletion_mode.dart';
import '../preview/file_preview_screen.dart';
import 'category_results_screen.dart';

class CategoryFilesScreen extends StatefulWidget {
  final String categoryName;
  final List<DuplicateGroup> groups;
  final List<DuplicateGroup>? allDuplicateGroups;
  final int? scannedFiles;
  final KeepOneController? keepOneController;

  const CategoryFilesScreen({
    super.key,
    required this.categoryName,
    required this.groups,
    this.allDuplicateGroups,
    this.scannedFiles,
    this.keepOneController,
  });

  @override
  State<CategoryFilesScreen> createState() => _CategoryFilesScreenState();
}

class _CategoryFilesScreenState extends State<CategoryFilesScreen> {
  final Set<String> _selected = <String>{};
  final Map<String, String> _keepers = <String, String>{};

  @override
  void initState() {
    super.initState();

    widget.keepOneController?.enabled.addListener(_onGlobalKeepOneChanged);

    if (widget.keepOneController?.enabled.value == true) {
      _applyKeepOneToAll();
    }
  }

  @override
  void dispose() {
    widget.keepOneController?.enabled.removeListener(_onGlobalKeepOneChanged);

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

  void _toggleFile(DuplicateFile file, DuplicateGroup group) {
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

  Future<void> _toggleKeepOne(DuplicateGroup group) async {
    final existingKeeper = _keepers[group.hash];

    // KEEP ONE -> OFF
    if (existingKeeper != null) {
      setState(() {
        _keepers.remove(group.hash);

        for (final file in group.files) {
          _selected.remove(file.path);
        }
      });

      return;
    }

    // KEEP ONE -> ON
    final selected = await showModalBottomSheet<DuplicateFile>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  // Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keep One Copy',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Choose the file that should remain on your device.',
                          style: TextStyle(
                            color: Colors.black.withAlpha(133),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Scrollable file list
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: group.files.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final file = group.files[index];
                        final isImage = _isImage(file.extension);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withAlpha(15),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isImage
                                    ? Icons.image_rounded
                                    : Icons.insert_drive_file_rounded,
                                color: theme.colorScheme.primary,
                                size: 21,
                              ),
                            ),
                            title: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                file.path,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black.withAlpha(115),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.black.withAlpha(100),
                            ),
                            onTap: () {
                              Navigator.pop(context, file);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
          deletionMode: DeletionMode.category,
          sourceGroups: widget.allDuplicateGroups ?? widget.groups,
          scannedFiles: widget.scannedFiles ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedCount = _selected.length;
    final groupCount = widget.groups.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Selection options',
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
                child: Row(
                  children: [
                    Icon(Icons.select_all_rounded),
                    SizedBox(width: 10),
                    Text('Select all'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.deselect_rounded),
                    SizedBox(width: 10),
                    Text('Deselect all'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: selectedCount == 0
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.black.withAlpha(13)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openDeleteConfirmation,
                    icon: const Icon(Icons.delete_outline_rounded, size: 21),
                    label: Text(
                      'Delete $selectedCount • '
                      '${MockData.formatBytes(_selectedBytes)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: widget.groups.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Header summary
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.copy_all_rounded,
                          color: theme.colorScheme.primary,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$groupCount duplicate '
                              '${groupCount == 1 ? 'group' : 'groups'}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Review the files and choose what to remove.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withAlpha(133),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ...widget.groups.map(
                  (group) => _buildDuplicateGroup(context, group),
                ),
              ],
            ),
    );
  }

  Widget _buildDuplicateGroup(BuildContext context, DuplicateGroup group) {
    final theme = Theme.of(context);
    final hasKeeper = _keepers.containsKey(group.hash);

    final selectedInGroup = group.files
        .where((file) => _selected.contains(file.path))
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasKeeper
              ? theme.colorScheme.primary.withAlpha(45)
              : Colors.black.withAlpha(13),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 10, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.copy_all_rounded,
                    color: theme.colorScheme.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duplicate group',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.files.length} copies • '
                        '${MockData.formatBytes(group.size)} each',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withAlpha(125),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _toggleKeepOne(group),
                  tooltip: hasKeeper ? 'Turn off Keep One' : 'Keep one copy',
                  style: IconButton.styleFrom(
                    backgroundColor: hasKeeper
                        ? theme.colorScheme.primary.withAlpha(20)
                        : Colors.black.withAlpha(7),
                  ),
                  icon: Icon(
                    hasKeeper ? Icons.check_rounded : Icons.shield_outlined,
                    color: hasKeeper
                        ? theme.colorScheme.primary
                        : Colors.black.withAlpha(140),
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Keep One status
            if (hasKeeper)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 17,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'One copy is protected. '
                        '$selectedInGroup ${selectedInGroup == 1 ? 'file' : 'files'} '
                        'selected for deletion.',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Divider(color: Colors.black.withAlpha(13), height: 1),

            const SizedBox(height: 4),

            ...group.files.map((file) => _buildFileTile(context, file, group)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTile(
    BuildContext context,
    DuplicateFile file,
    DuplicateGroup group,
  ) {
    final theme = Theme.of(context);

    final isKeeper = _keepers[group.hash] == file.path;
    final isSelected = _selected.contains(file.path);
    final isImage = _isImage(file.extension);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: isKeeper
            ? theme.colorScheme.primary.withAlpha(10)
            : isSelected
            ? theme.colorScheme.error.withAlpha(8)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isKeeper
                ? theme.colorScheme.primary.withAlpha(20)
                : Colors.black.withAlpha(7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
            color: isKeeper
                ? theme.colorScheme.primary
                : Colors.black.withAlpha(125),
            size: 21,
          ),
        ),
        title: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${MockData.formatBytes(file.size)} • '
            '${file.modified.day}/'
            '${file.modified.month}/'
            '${file.modified.year}\n'
            '${file.path}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Colors.black.withAlpha(115),
            ),
          ),
        ),
        isThreeLine: true,
        trailing: isKeeper
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'KEEP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              )
            : Checkbox(
                value: isSelected,
                onChanged: (_) {
                  _toggleFile(file, group);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FilePreviewScreen(file: file)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No duplicate files',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            Text(
              'There are no duplicate groups in this category.',
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
