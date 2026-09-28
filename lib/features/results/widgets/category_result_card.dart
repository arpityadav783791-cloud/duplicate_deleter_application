import 'package:flutter/material.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/models/duplicate_group.dart';

class CategoryResultCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final List<DuplicateGroup> groups;
  final VoidCallback onTap;

  const CategoryResultCard({
    super.key,
    required this.name,
    required this.icon,
    required this.groups,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duplicateFiles = groups.fold<int>(
      0,
      (total, group) => total + group.files.length,
    );

    final duplicateBytes = groups.fold<int>(
      0,
      (total, group) =>
          total + group.size * (group.files.length - 1),
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$duplicateFiles duplicate files'),
                    const SizedBox(height: 2),
                    Text(
                      MockData.formatBytes(duplicateBytes),
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}