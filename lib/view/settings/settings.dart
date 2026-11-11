import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/const/version_info.dart';
import 'package:diohub/common/misc/app_scroll_view.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/utils/http_to_api.dart';
import 'package:diohub/view/settings/widgets/color_setting_card.dart';
import 'package:diohub/view/settings/widgets/language_setting_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    controller = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(final BuildContext context) => AppScrollView(
        scrollViewAppBar: ScrollViewAppBar(
          expandedHeight: 180,
          collapsedHeight: 60,
          appBarWidget: AppInfoWidget(
            axis: Axis.horizontal,
            logoSize: 30,
            nameSize: Theme.of(context).textTheme.titleLarge!.fontSize!,
          ),
          flexibleBackgroundWidget: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppInfoWidget(
                axis: Axis.horizontal,
                logoSize: 45,
                nameSize: 30,
              ),
              VersionInfoWidget(),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 8),
              //   child: Text(
              //     'App Settings',
              //     style: Theme.of(context).textTheme.headlineSmall,
              //   ),
              // ),
              // Row(
              //   children: const [
              //     VersionInfoWidget(),
              //   ],
              // ),
            ],
          ),
          bottomPadding: 60,
          tabController: controller,
          tabs: const <String>[
            'General',
            'About',
          ],
        ),
        tabController: controller,
        // childrenColor:
        //     Provider.of<PaletteSettings>(context).currentSetting.primary,
        tabViews: const <Widget>[
          _GeneralSettings(),
          _About(),
        ],
      );
}

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings();

  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 8,
            ),
            const FontSettingCard(),
            const ColorSettingCard(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: InfoCard.children(
                title: 'GitHub Connection',
                leading: InfoCard.leadingIcon(icon: Icons.link_rounded),
                children: <Widget>[
                  ListTile(
                    dense: true,
                    title: Text('Connected as @${context.viewer.login}'),
                    subtitle: const Text(
                      'DioHub reads organizations and repositories that this '
                      'account can access.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.business_rounded,
                      size: 20,
                    ),
                    title: const Text('Manage organization access'),
                    subtitle: const Text(
                      'Organization owners must approve third-party apps '
                      'before their private repositories become visible.',
                    ),
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                    ),
                    onTap: () async {
                      await launchUrl(
                        AuthRepository.organizationAccessSettingsUri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: StringButton(
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (final BuildContext context) => AlertDialog(
                      title: Text(
                        'Log Out?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      actions: <Widget>[
                        MaterialButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        MaterialButton(
                          onPressed: () {
                            BlocProvider.of<AuthenticationBloc>(context)
                                .add(LogOut());
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Confirm',
                          ),
                        ),
                      ],
                    ),
                  );
                },
                title: 'Log Out',
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: StringButton(
                // color: Provider.of<PaletteSettings>(context)
                //     .currentSetting
                //     .secondary,
                onTap: BaseAPIHandler.clearCache,
                title: 'Clear Cache',
              ),
            ),
          ],
        ),
      );
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
        child: Column(
          children: <Widget>[
            InfoCard(
              title: 'Repository',
              child: RepoCardLoading(
                toRepoAPIResource('https://github.com/NamanShergill/diohub'),
                'diohub',
              ),
            ),
            InfoCard(
              title: 'Maintained By',
              child: const ProfileCardLoading(
                'NamanShergill',
                compact: true,
              ),
            ),
            MenuInfoCard(
              title: 'Bugs or Suggestions?',
              menuBuilder: (final BuildContext context) => URLActions(
                uri: Uri.parse(
                  'https://github.com/NamanShergill/diohub/issues',
                ),
              ).menuItems,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Let me know at'),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            'https://github.com/NamanShergill/diohub/issues',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: StringButton(
                // color: Provider.of<PaletteSettings>(context)
                //     .currentSetting
                //     .secondary,
                onTap: () async {
                  final PackageInfo packageInfo =
                      await PackageInfo.fromPlatform();
                  if (context.mounted) {
                    showLicensePage(
                      context: context,
                      applicationIcon: const AppLogoWidget(
                        size: 50,
                      ),
                      applicationName: 'DioHub',
                      applicationVersion: packageInfo.version,
                    );
                  }
                  // AutoRouter.of(context).push(const DependenciesScreenRoute());
                },
                title: 'Licenses',
              ),
            ),
          ],
        ),
      );
}
