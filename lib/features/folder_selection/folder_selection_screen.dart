import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../scanner/scanning_screen.dart';

class FolderSelectionScreen extends StatefulWidget {
  const FolderSelectionScreen({super.key});
  @override
  State<FolderSelectionScreen> createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  bool _opening = false;
  String? _error;

  Future<void> _chooseFolder() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final path = await FilePicker.getDirectoryPath();
      if (!mounted) return;
      if (path == null || path.isEmpty) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ScanningScreen(source: ScanSource.folder, selectedFolder: path),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to open the folder picker.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose folder')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded, size: 54),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan a specific folder',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose a folder. Only that folder and its subfolders will be scanned.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _opening ? null : _chooseFolder,
                icon: _opening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_rounded),
                label: Text(_opening ? 'Opening...' : 'Choose Folder'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
