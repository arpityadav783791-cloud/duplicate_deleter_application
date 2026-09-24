import 'package:flutter/material.dart';

import '../../core/duplicate/duplicate_result.dart';
import '../../core/services/file_delete_service.dart';

class ResultsScreen extends StatefulWidget {
  final List<DuplicateGroup> duplicateGroups;
  final int scannedFiles;
  final bool autoSelectDuplicates;

  const ResultsScreen({
    super.key,
    required this.duplicateGroups,
    required this.scannedFiles,
    this.autoSelectDuplicates = false,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final Set<String> _selectedFiles = {};
  final FileDeleteService _deleteService = FileDeleteService();

  late List<DuplicateGroup> _groups;

  @override
  void initState() {
    super.initState();

    _groups = List.from(widget.duplicateGroups);

    if (widget.autoSelectDuplicates) {
      for (final group in _groups) {
        for (var i = 1; i < group.files.length; i++) {
          _selectedFiles.add(group.files[i].path);
        }
      }
    }
  }

  int get duplicateFiles {
    return _groups.fold(
      0,
      (total, group) => total + group.files.length,
    );
  }

  int get wastedSpace {
    return _groups.fold(
      0,
      (total, group) =>
          total + group.size * (group.files.length - 1),
    );
  }

  bool get allSelected {
    return duplicateFiles > 0 &&
        _selectedFiles.length == duplicateFiles;
  }

  void _toggleFile(DuplicateFile file) {
    setState(() {
      if (_selectedFiles.contains(file.path)) {
        _selectedFiles.remove(file.path);
      } else {
        _selectedFiles.add(file.path);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (allSelected) {
        _selectedFiles.clear();
      } else {
        _selectedFiles
          ..clear()
          ..addAll(
            _groups.expand(
              (group) => group.files.map((file) => file.path),
            ),
          );
      }
    });
  }

  Future<void> _keepOne(DuplicateGroup group) async {
    final keepFile = await showDialog<DuplicateFile>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Keep which file?'),
          children: group.files.map((file) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, file),
              child: Text(
                file.path,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        );
      },
    );

    if (keepFile == null) return;

    setState(() {
      _selectedFiles.remove(keepFile.path);

      for (final file in group.files) {
        if (file.path != keepFile.path) {
          _selectedFiles.add(file.path);
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedFiles.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete selected files?'),
          content: Text(
            'Are you sure you want to delete '
            '${_selectedFiles.length} selected files?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final filesToDelete = List<String>.from(_selectedFiles);

    for (final path in filesToDelete) {
      await _deleteService.deleteFile(path);
    }

    if (!mounted) return;

    setState(() {
      _groups = _groups
          .map(
            (group) => DuplicateGroup(
              hash: group.hash,
              size: group.size,
              files: group.files
                  .where(
                    (file) => !_selectedFiles.contains(file.path),
                  )
                  .toList(),
            ),
          )
          .where((group) => group.files.length > 1)
          .toList();

      _selectedFiles.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${filesToDelete.length} files deleted.',
        ),
      ),
    );
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duplicate Results'),
      ),
      floatingActionButton: _selectedFiles.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete),
              label: Text(
                'Delete (${_selectedFiles.length})',
              ),
            ),
      body: _groups.isEmpty
          ? const Center(
              child: Text(
                'No duplicate files found.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Scanned',
                        value: '${widget.scannedFiles}',
                        icon: Icons.folder_open,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Duplicates',
                        value: '$duplicateFiles',
                        icon: Icons.copy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Wasted',
                        value: formatBytes(wastedSpace),
                        icon: Icons.storage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_groups.length} Duplicate Groups',
                      style:
                          Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      onPressed: _toggleSelectAll,
                      icon: Icon(
                        allSelected
                            ? Icons.deselect
                            : Icons.select_all,
                      ),
                      label: Text(
                        allSelected
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ),
                  ],
                ),
                if (_selectedFiles.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${_selectedFiles.length} files selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ..._groups.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final group = entry.value;

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading:
                            const Icon(Icons.copy_all),
                        title: Text(
                          'Duplicate Group ${index + 1}',
                        ),
                        subtitle: Text(
                          '${group.files.length} files • '
                          '${formatBytes(group.size)} each',
                        ),
                        trailing: IconButton(
                          tooltip: 'Keep One',
                          icon: const Icon(
                            Icons.check_circle_outline,
                          ),
                          onPressed: () => _keepOne(group),
                        ),
                        children: [
                          ...group.files.map(
                            (file) {
                              final selected =
                                  _selectedFiles.contains(
                                file.path,
                              );

                              return CheckboxListTile(
                                value: selected,
                                onChanged: (_) {
                                  _toggleFile(file);
                                },
                                secondary: const Icon(
                                  Icons
                                      .insert_drive_file_outlined,
                                ),
                                title: Text(file.name),
                                subtitle: Text(
                                  file.path,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity
                                        .trailing,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}