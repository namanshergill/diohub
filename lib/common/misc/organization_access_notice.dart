import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Explains why some organizations or private organization repositories may
/// not be visible and links to GitHub's OAuth app settings.
///
/// GitHub restricts third-party OAuth app access to organizations by default;
/// an organization owner has to approve the app before its private data can be
/// read. There is no API to request that approval from inside the app, so the
/// best we can do is link to the exact settings page.
class OrganizationAccessNotice extends StatelessWidget {
  const OrganizationAccessNotice({
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    super.key,
  });

  final EdgeInsets margin;

  Future<void> _openSettings() async {
    await launchUrl(
      AuthRepository.organizationAccessSettingsUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: theme.surfaceStyle.borderRadiusMedium(),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Octicons.organization,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Missing an organization?',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'GitHub blocks third-party app access to organizations by '
                  'default. Ask an organization owner to approve DioHub, or '
                  'grant access in your GitHub settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _openSettings,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }
}
