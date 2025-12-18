/// A widget that displays the profile card of a user.
///
/// This widget displays the user's avatar, name, bio, and number of followers.
/// It also allows the user to navigate to the profile page of the user when tapped.
///
/// The [ProfileCard] widget requires a [UserInfoModel] object and an optional
/// boolean value to indicate whether the card should be compact or not.
///
/// The [ProfileCardLoading] widget is a loading state for the [ProfileCard]
/// widget. It requires a [String] login and an optional boolean value to
/// indicate whether the card should be compact or not.
///
/// The [actorLogin], [actorAvatarUri], and [actorAvatarStringUri] functions
/// are utility functions that extract the login and avatar URL of a [Gactor]
/// object from the `timeline.data.gql.dart` file.
import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard(
    this.user, {
    this.compact = false,
    super.key,
  });

  final UserInfoModel user;
  final bool compact;

  @override
  Widget build(final BuildContext context) => InkPot(
        onTap: () async {
          await AutoRouter.of(context)
              .push(UserProfileRoute(login: user.login!));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IgnorePointer(
                    child: ProfileTile.extended(
                      avatarUrl: user.avatarUrl,
                      fullName: user.name,
                      size: 30,
                      userLogin: user.login,
                    ),
                  ),
                  if (user.bio != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Flexible(
                        child: Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                user.bio!,
                                overflow: TextOverflow.ellipsis,
                                // style: AppThemeTextStyles
                                //     .eventCardChildSubtitle(
                                //   context,
                                // ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!compact)
                    Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              MdiIcons.accountGroup,
                              size: 12,
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Text(
                              user.followers != null
                                  ? user.followers.toString()
                                  : 'None',
                              // style:
                              // AppThemeTextStyles.eventCardChildFooter(
                              // context,
                              // ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              // if (user.login !=
              //     Provider.of<CurrentUserProvider>(context).data.login)
              //   UserFollow(user.login!),
            ],
          ),
        ),
      );
}

class ProfileCardLoading extends StatelessWidget {
  const ProfileCardLoading(
    this.login, {
    super.key,
    this.compact = false,
  });

  final String login;
  final bool compact;

  @override
  Widget build(final BuildContext context) =>
      APIWrapper<UserInfoModel>.deferred(
        apiCall: ({required final bool refresh}) async =>
            UserInfoService.getUserInfo(login),
        builder: (final BuildContext context, final UserInfoModel data) =>
            SizeExpandedSection(
          child: Row(
            children: <Widget>[
              Expanded(
                child: ProfileCard(
                  data,
                  compact: compact,
                ),
              ),
            ],
          ),
        ),
        loadingBuilder: (final BuildContext context) => const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingIndicator(),
        ),
      );
}

String actorLogin(final Gactor actor) => actor.login;

Uri actorAvatarUri(final Gactor actor) => actor.avatarUrl;

String actorAvatarStringUri(final Gactor actor) => actor.avatarUrl.toString();
