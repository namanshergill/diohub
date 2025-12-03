import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_stack/image_stack.dart';

/// Base content widget for DetailTile with consistent styling
class DetailTileContent extends StatelessWidget {
  const DetailTileContent({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseStyle = context.textTheme.bodyMedium ?? const TextStyle();
    // Use onSurface with reduced opacity for darker gray that fits the darker card
    final textColor = context.colorScheme.onSurface.withOpacity(0.85);
    return DefaultTextStyle(
      style: baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: textColor, // Explicitly override any theme color
        fontSize: baseStyle.fontSize ?? 14,
      ),
      child: child,
    );
  }
}

/// Simple text content for DetailTile
class DetailTileText extends StatelessWidget {
  const DetailTileText(
    this.text, {
    this.color,
    super.key,
  });

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final themeStyle = context.textTheme.bodyMedium ?? const TextStyle();
    // Use onSurfaceVariant with higher opacity for better contrast on darker card
    final textColor = context.colorScheme.onSurfaceVariant.withOpacity(0.9);
    final baseStyle = themeStyle.copyWith(
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: textColor, // Explicitly override any theme color
      fontSize: themeStyle.fontSize ?? 14,
    );
    
    return DetailTileContent(
      child: Text(
        text,
        style: color != null
            ? baseStyle.copyWith(color: color)
            : baseStyle,
      ),
    );
  }
}

/// Count display for DetailTile (e.g., "5 commits", "3 files")
class DetailTileCount extends StatelessWidget {
  const DetailTileCount(
    this.count,
    this.singularLabel,
    this.pluralLabel, {
    super.key,
  });

  final int count;
  final String singularLabel;
  final String pluralLabel;

  @override
  Widget build(BuildContext context) {
    return DetailTileContent(
      child: Text(
        '$count ${count == 1 ? singularLabel : pluralLabel}',
      ),
    );
  }
}

/// Single user display for DetailTile
class DetailTileUser extends StatelessWidget {
  const DetailTileUser({
    required this.avatarUrl,
    required this.login,
    this.size = 16,
    super.key,
  });

  final String avatarUrl;
  final String login;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DetailTileContent(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Icon(
                Icons.person,
                size: size,
                color: context.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              login,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Multiple users display with avatar stack for DetailTile
class DetailTileUserStack extends StatelessWidget {
  const DetailTileUserStack({
    required this.avatars,
    required this.totalCount,
    this.avatarSize = 18,
    super.key,
  });

  final List<String> avatars;
  final int totalCount;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) {
      return DetailTileContent(
        child: Text(
          'None',
          style: (context.textTheme.bodyMedium ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: context.colorScheme.onSurface.withOpacity(0.6), // Explicitly override
            fontStyle: FontStyle.italic,
            fontSize: context.textTheme.bodyMedium?.fontSize ?? 14,
          ),
        ),
      );
    }

    return DetailTileContent(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageStack.widgets(
            totalCount: totalCount,
            widgetBorderColor: Colors.transparent,
            widgetBorderWidth: 0,
            children: avatars.take(3).map((avatarUrl) {
              return ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    size: avatarSize,
                    color: context.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              );
            }).toList(),
          ),
          if (totalCount > 3) ...[
            const SizedBox(width: 6),
            Text(
              '+${totalCount - 3}',
              style: (context.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: context.colorScheme.onSurface.withOpacity(0.7), // Explicitly override
                fontSize: context.textTheme.bodyMedium?.fontSize ?? 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Repository display for DetailTile
class DetailTileRepository extends StatelessWidget {
  const DetailTileRepository({
    required this.ownerAvatarUrl,
    required this.ownerLogin,
    required this.repoName,
    this.avatarSize = 16,
    super.key,
  });

  final String ownerAvatarUrl;
  final String ownerLogin;
  final String repoName;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return DetailTileContent(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: ownerAvatarUrl,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Icon(
                Icons.folder,
                size: avatarSize,
                color: context.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$ownerLogin/$repoName',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

