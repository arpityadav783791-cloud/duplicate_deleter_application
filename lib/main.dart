import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const DuplicateCleanerApp());

class DuplicateCleanerApp extends StatelessWidget {
  const DuplicateCleanerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Duplicate File Cleaner',
    theme: AppTheme.light,
    home: const HomeScreen(),
  );
}
