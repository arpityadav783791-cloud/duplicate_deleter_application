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
    final theme = Theme.of(context);

    final duplicateFiles = groups.fold<int>(
      0,
      (total, group) => total + group.files.length,
    );

    final duplicateBytes = groups.fold<int>(
      0,
      (total, group) => total + group.size * (group.files.length - 1),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(9),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, size: 29, color: theme.colorScheme.primary),
                ),

                const SizedBox(width: 14),

                // Category information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          Icon(
                            Icons.copy_all_rounded,
                            size: 15,
                            color: Colors.black.withAlpha(115),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$duplicateFiles duplicate '
                            '${duplicateFiles == 1 ? 'file' : 'files'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withAlpha(140),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Icon(
                            Icons.cleaning_services_rounded,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${MockData.formatBytes(duplicateBytes)} reclaimable',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Open indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Colors.black.withAlpha(125),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
