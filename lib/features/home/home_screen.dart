import 'dart:io';
import 'package:flutter/material.dart';
import '../folder_selection/folder_selection_screen.dart';
import '../scanner/scanning_screen.dart';
import 'widgets/scan_action_card.dart';
import 'widgets/storage_overview_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duplicate Cleaner', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text('Find and review duplicate files on your accessible storage.', style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 20),
            const StorageOverviewCard(),
            const SizedBox(height: 24),
            const Text('Scan your storage', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ScanActionCard(
              icon: Icons.phone_android_rounded,
              title: 'Complete Device Scan',
              subtitle: 'Scan accessible shared storage for exact duplicates.',
              primary: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanningScreen(source: ScanSource.device))),
            ),
            const SizedBox(height: 12),
            ScanActionCard(
              icon: Icons.folder_rounded,
              title: 'Scan Specific Folder',
              subtitle: 'Choose a folder and scan only that folder and its subfolders.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FolderSelectionScreen())),
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 14),
              const Text('Android may open system settings to grant broad shared-storage access for a complete scan.', style: TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
