import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const DuplicateCleanerApp());
}

class DuplicateCleanerApp extends StatelessWidget {
  const DuplicateCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Duplicate Cleaner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}