import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../folder_selection/folder_selection_screen.dart';
import '../scanner/scanning_screen.dart';
import 'widgets/scan_action_card.dart';
import 'widgets/storage_overview_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showExitDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Leaving so soon?\n'
            '😢',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text('Are you sure you want to exit the application?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    ).then((shouldExit) {
      if (shouldExit == true) {
        SystemNavigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: ((didPop, result) {
        if (didPop) {
          return;
        }
        _showExitDialog(context);
      }),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(31),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.cleaning_services_rounded,
                  color: theme.colorScheme.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Duplicate Cleaner',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              // Hero section
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withAlpha(209),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(46),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Clean up your storage',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Find duplicate files and reclaim your valuable storage space.',
                            style: TextStyle(
                              color: Colors.white.withAlpha(224),
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(36),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Storage section
              const Text(
                'Storage',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              const StorageOverviewCard(),

              const SizedBox(height: 28),

              // Scan section
              const Text(
                'Scan your storage',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Choose how you want to find duplicate files.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              ScanActionCard(
                icon: Icons.phone_android_rounded,
                title: 'Complete Device Scan',
                subtitle:
                    'Scan accessible shared storage for exact duplicates.',
                primary: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ScanningScreen(source: ScanSource.device),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              ScanActionCard(
                icon: Icons.folder_rounded,
                title: 'Scan Specific Folder',
                subtitle: 'Choose a folder and scan only that folder and its subfolders.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FolderSelectionScreen(),
                    ),
                  );
                },
              ),

              if (Platform.isAndroid) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withAlpha(15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.black.withAlpha(115),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'A complete device scan may require shared-storage access from Android settings.',
                          style: TextStyle(
                            color: Colors.black.withAlpha(133),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
