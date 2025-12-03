import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class DetailTile extends StatelessWidget {
  const DetailTile({
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with icon
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: context.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  child,
                ],
              ),
            ),
            // Trailing icon
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
