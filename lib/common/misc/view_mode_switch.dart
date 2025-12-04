import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// A sleek switch component for toggling between two view modes.
///
/// Displays icons on both sides with a Material switch in the center.
class ViewModeSwitch extends StatelessWidget {
  const ViewModeSwitch({
    required this.value,
    required this.onChanged,
    this.leftIcon = Icons.list,
    this.rightIcon = Icons.account_tree,
    this.iconSize = 16,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData leftIcon;
  final IconData rightIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconButton(
            icon: leftIcon,
            size: iconSize,
            isActive: !value,
            onTap: () => onChanged(false),
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            height: 20,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _IconButton(
            icon: rightIcon,
            size: iconSize,
            isActive: value,
            onTap: () => onChanged(true),
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.size,
    required this.isActive,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final double size;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: size,
            color: isActive
                ? context.colorScheme.primary
                : color.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

