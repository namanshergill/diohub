import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile.avatar({
    required this.avatarUrl,
    this.userLogin,
    this.padding = const EdgeInsets.all(8),
    this.size = 25,
    super.key,
    this.wrapperBuilder,
  })  : _type = _UserCardType.photo,
        fullName = null,
        disableTap = false,
        textStyle = null;

  const ProfileTile.login({
    required this.avatarUrl,
    required this.userLogin,
    this.padding = const EdgeInsets.all(8),
    this.size = 25,
    this.disableTap = false,
    this.textStyle,
    super.key,
    this.wrapperBuilder,
  })  : _type = _UserCardType.login,
        fullName = null;

  const ProfileTile.extended({
    required this.avatarUrl,
    required this.userLogin,
    required this.fullName,
    this.padding = const EdgeInsets.all(8),
    this.size = 25,
    this.disableTap = false,
    this.textStyle,
    super.key,
    this.wrapperBuilder,
  }) : _type = _UserCardType.extended;
  final String? avatarUrl;
  final double size;
  final String? userLogin;
  final String? fullName;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final bool disableTap;
  final _UserCardType _type;
  final Widget Function(Widget child)? wrapperBuilder;

  @override
  Widget build(final BuildContext context) => InkPot(
        // borderRadius: smallBorderRadius,
        onTap: userLogin != null && !disableTap
            ? () {
                navigateToProfile(login: userLogin!, context: context);
              }
            : null,
        child: wrapperBuilder?.call(
              _buildChild(context),
            ) ??
            _buildChild(context),
      );

  Padding _buildChild(final BuildContext context) => Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl ?? 'N/A',
                height: size,
                fit: BoxFit.fill,
                placeholder:
                    (final BuildContext context, final String string) =>
                        ShimmerWidget(
                  child: Container(
                    height: size,
                    width: size,
                    color: context.colorScheme.surfaceVariant,
                  ),
                ),
                errorWidget: (final BuildContext context, final _, final __) =>
                    Icon(
                  MdiIcons.ghost,
                  size: size,
                ),
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (fullName != null)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          fullName!,
                          style: (textStyle ??
                                  const TextStyle(
                                      // color: Provider.of<PaletteSettings>(
                                      //   context,
                                      // ).currentSetting.baseElements,
                                      //  15,
                                      ))
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (_type != _UserCardType.photo)
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: size / 3),
                        child: Text(
                          userLogin ?? 'N/A',
                          style: textStyle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

void navigateToProfile({
  required final BuildContext context,
  required final String login,
}) =>
    unawaited(
      context.router.push(
        UserProfileRoute(login: login),
      ),
    );

enum _UserCardType { photo, login, extended }
