import 'package:auto_route/auto_route.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/adapters/internet_connectivity.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/api_handler/response_handler.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/app/settings/font.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/providers/search_data_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/style/border_radiuses.dart';
import 'package:diohub/utils/device_display_mode.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<void> debugURLLauncher() async {
  await Future<void>.delayed(const Duration(seconds: 2));
  String? url;
  // https://github.com/flutter/flutter/issues/120732
  // https://github.com/flutter/flutter/issues/128696
  // url = 'https://github.com/firebase/flutterfire/issues/1041';
  if (kDebugMode) {
    await deepLinkNavigate(
      Uri.parse(url ?? ''),
    );
  }
}

void main() async {
  // ChuckerFlutter.showOnRelease = true;
  WidgetsFlutterBinding.ensureInitialized();
  // Error popup stream initialised.
  ResponseHandler.getErrorStream();
  // Success popup stream initialised.
  ResponseHandler.getSuccessStream();
  // Connectivity check stream initialised.
  await InternetConnectivity.networkStatusService();

  await Future.wait(<Future<void>>[
    BaseAPIHandler.setupDioAPICache(),
    setUpSharedPrefs(),
    setHighRefreshRate(),
  ]);

  // final initLink = await initUniLink();
  uniLinkStream();
  final bool auth = await AuthRepository().isAuthenticated;
  // runApp(NewWidget());
  runApp(
    MyApp(
      authenticated: auth,
      // initDeepLink: initLink,
    ),
  );
  await debugURLLauncher();
}

class NewWidget extends StatelessWidget {
  const NewWidget({
    super.key,
  });

  @override
  Widget build(final BuildContext context) => MaterialApp(
        navigatorObservers: <NavigatorObserver>[
          ChuckerFlutter.navigatorObserver,
        ],
        home: Builder(
          builder: (final BuildContext context) => Stack(
            children: <Widget>[
              SafeArea(
                child: Scaffold(
                  body: NestedScrollView(
                    headerSliverBuilder: (final BuildContext context,
                            final bool innerBoxIsScrolled) =>
                        <Widget>[
                      const SliverAppBar(
                        title: Text('ajhs jhads '),
                        expandedHeight: 500,
                      ),
                    ],
                    body: ListView.builder(
                      itemBuilder:
                          (final BuildContext context, final int index) =>
                              ListTile(title: Text(index.toString())),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).padding.top,
                child: GestureDetector(
                  onTap: () {
                    PrimaryScrollController.of(context).animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.bounceIn,
                    );
                  },
                  child: Container(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({required this.authenticated, super.key});

  // final String? initDeepLink;
  final bool authenticated;

  @override
  Widget build(final BuildContext context) => MultiBlocProvider(
        providers: <SingleChildWidget>[
          // Initialise Authentication Bloc and add event to check auth state.
          BlocProvider<AuthenticationBloc>(
            create: (final _) =>
                AuthenticationBloc(authenticated: authenticated),
            lazy: false,
          ),
        ],
        child: Builder(
          builder: (final BuildContext context) => MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<CurrentUserProvider>(
                lazy: false,
                create: (final _) => CurrentUserProvider(
                  authenticationBloc:
                      BlocProvider.of<AuthenticationBloc>(context),
                ),
              ),
              ChangeNotifierProvider<SearchDataProvider>(
                create: (final _) => SearchDataProvider(),
              ),
              ChangeNotifierProvider<FontSettings>(
                create: (final _) => FontSettings(),
              ),
              // ChangeNotifierProvider<PaletteSettings>(
              //   create: (final _) => PaletteSettings(),
              // ),
            ],
            builder: (final BuildContext context, final Widget? child) =>
                const Portal(
              child: RootApp(),
            ),
          ),
        ),
      );
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  // final String? initDeepLink;

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  @override
  void initState() {
    setUpRouter(context);
    super.initState();
  }

  @override
  Widget build(final BuildContext context) => DynamicColorBuilder(
        builder:
            (final ColorScheme? lightDynamic, final ColorScheme? darkDynamic) {
          ColorScheme? lightScheme;
          ColorScheme? darkScheme;
          print('hjbs jhbf s');
          print(lightDynamic);
          print(darkDynamic);
          if (lightDynamic != null && darkDynamic != null) {
            (lightScheme, darkScheme) =
                _generateDynamicColourSchemes(lightDynamic, darkDynamic);
          } else {
            // logic to set standard static themes here
          }
          return riverpod.ProviderScope(
            child: MaterialApp.router(
              theme: getTheme(
                context,
                brightness: Brightness.light,
                colorScheme: lightScheme,
              ),
              darkTheme: getTheme(
                context,
                brightness: Brightness.dark,
                colorScheme: darkScheme,
              ),
              localizationsDelegates: const <LocalizationsDelegate>[
                DefaultMaterialLocalizations.delegate,
                DefaultCupertinoLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
              ],
              // getTheme(context, brightness: Brightness.light),
              // darkTheme: getTheme(context, brightness: Brightness.dark),
              routerDelegate: customRouter.delegate(
                deepLinkBuilder: (final PlatformDeepLink deepLink) =>
                    DeepLink(<PageRouteInfo>[
                  LandingLoadingRoute(
                    initLink: deepLink.configuration.uri,
                  ),
                ]),
                navigatorObservers: () => <NavigatorObserver>[
                  ChuckerFlutter.navigatorObserver,
                ],
                rebuildStackOnDeepLink: true,
              ),
              routeInformationParser: customRouter.defaultRouteParser(),
            ),
          );
        },
      );
}

ThemeData getTheme(
  final BuildContext context, {
  required final Brightness brightness,
  required final ColorScheme? colorScheme,
}) {
  final ColorScheme? cs = colorScheme;
  // cs= cs.copyWith(surfaceTint: Colors.transparent);
  final BorderRadiusTheme borderRadiusTheme = BorderRadiusTheme();
  return ThemeData(
    // useMaterial3: true,
    brightness: brightness,
    // tabBarTheme: TabBarTheme(
    //   labelPadding: EdgeInsets.all(8),
    // indicator: BoxDecoration(
    //   color: context.colorScheme.primary,
    //   borderRadius: bigBorderRadius,
    // ),
    // labelStyle: TextStyle(color: context.colorScheme.onPrimary)
    //     .merge(context.textTheme.titleSmall),
    // ),
    // visualDensity: VisualDensity.compact,
    // unselectedWidgetColor: palette.faded1,
    // cardColor: palette.primary,
    // pageTransitionsTheme: const PageTransitionsTheme(
    //   builders: <TargetPlatform, PageTransitionsBuilder>{
    //     // TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    //     TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    //   },
    // ),
    // appBarTheme: const AppBarTheme(elevation: 0),
    // tabBarTheme: TabBarTheme(
    //   indicator: BoxDecoration(
    //     borderRadius: bigBorderRadius,
    //   ),
    //   unselectedLabelStyle: Theme.of(context)
    //       .textTheme
    //       .titleLarge!
    //       .copyWith( 14, fontWeight: FontWeight.w600),
    //   labelStyle: Theme.of(context)
    //       .textTheme
    //       .titleLarge!
    //       .copyWith( 20, fontWeight: FontWeight.bold),
    //   labelPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
    // ),

    // bottomSheetTheme: BottomSheetThemeData(
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.only(
    //       topRight: Radius.circular(20),
    //       topLeft: Radius.circular(20),
    //     ),
    //   ),
    // ),

    // scrollbarTheme: ScrollbarThemeData(
    //   thumbColor: MaterialStateProperty.all<Color>(grey),
    // ),
    // dialogTheme: DialogTheme(
    //   shape: RoundedRectangleBorder(borderRadius: medBorderRadius),
    // ),
    // listTileTheme: ListTileThemeData(iconColor: context.palette.baseElements),
    // dividerColor: grey.withOpacity(0.7),
    // buttonTheme: ButtonThemeData(
    //   textTheme: ButtonTextTheme.primary,
    //   padding: EdgeInsets.zero,
    //   colorScheme: const ColorScheme.dark(),
    //   shape: RoundedRectangleBorder(borderRadius: medBorderRadius),
    // ),
    fontFamily: Provider.of<FontSettings>(context).currentSetting,
    // cardTheme: CardTheme(
    //   // color: palette.secondary,
    //   shape: RoundedRectangleBorder(borderRadius: medBorderRadius),
    // ),
    bottomSheetTheme: BottomSheetThemeData(
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      // contentPadding: const EdgeInsets.all(16),
      // hintStyle: TextStyle( 12),
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: borderRadiusTheme.medBorderRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusTheme.medBorderRadius,
      ),
      border: OutlineInputBorder(
        borderRadius: borderRadiusTheme.medBorderRadius,
      ),
    ),
    colorScheme: cs,
    extensions: <ThemeExtension<dynamic>>[
      borderRadiusTheme,
    ],
  );
}

const ColorScheme _defaultLightColorScheme = ColorScheme(
  primary: Color(0xff0343ff),
  primaryContainer: Color(0xffdee1ff),
  onPrimaryContainer: Color(0xff001159),
  secondary: Color(0xff5f5a7d),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffe5deff),
  onSecondaryContainer: Color(0xff1c1736),
  tertiary: Color(0xff6b5585),
  onTertiary: Color(0xffffffff),
  tertiaryContainer: Color(0xffeedbff),
  onTertiaryContainer: Color(0xff25113e),
  error: Color(0xffba1a1a),
  errorContainer: Color(0xffffdad6),
  onErrorContainer: Color(0xff410002),
  background: Color(0xfffefbff),
  onBackground: Color(0xff191b25),
  surface: Color(0xfffefbff),
  onSurface: Color(0xff191b25),
  surfaceVariant: Color(0xffe1e1f3),
  onSurfaceVariant: Color(0xff444654),
  outline: Color(0xff747584),
  outlineVariant: Color(0xffc5c5d6),
  inverseSurface: Color(0xff2e303a),
  onInverseSurface: Color(0xfff0effe),
  inversePrimary: Color(0xffbac3ff),
  surfaceTint: Color(0xff0343ff),
  brightness: Brightness.light,
  onPrimary: Color(0xff191b25),
  onError: Color(0xffffdad6),
);

const ColorScheme _defaultDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xffbac3ff),
  onPrimary: Color(0xff00218d),
  primaryContainer: Color(0xff0031c5),
  onPrimaryContainer: Color(0xffdee1ff),
  secondary: Color(0xffc9c1ea),
  onSecondary: Color(0xff312c4c),
  secondaryContainer: Color(0xff484364),
  onSecondaryContainer: Color(0xffe5deff),
  tertiary: Color(0xffd6bcf3),
  onTertiary: Color(0xff3b2754),
  tertiaryContainer: Color(0xff523d6c),
  onTertiaryContainer: Color(0xffeedbff),
  error: Color(0xffffb4ab),
  onError: Color(0xff690005),
  errorContainer: Color(0xff93000a),
  onErrorContainer: Color(0xffffb4ab),
  background: Color(0xff191b25),
  onBackground: Color(0xffe2e1ef),
  surface: Color(0xff191b25),
  onSurface: Color(0xffe2e1ef),
  surfaceVariant: Color(0xff444654),
  onSurfaceVariant: Color(0xffc5c5d6),
  outline: Color(0xff8f909f),
  outlineVariant: Color(0xff444654),
  inverseSurface: Color(0xffe2e1ef),
  onInverseSurface: Color(0xff2e303a),
  inversePrimary: Color(0xff0343ff),
  surfaceTint: Color(0xffbac3ff),
);

// Nice dark cs.
//ColorScheme#b066f(brightness: Brightness.dark, primary: Color(0xffbb86fc), onPrimary: Color(0xff000000), primaryContainer: Color(0xffbb86fc), onPrimaryContainer: Color(0xff000000), error: Color(0xffcf6679), onError: Color(0xff000000), errorContainer: Color(0xffcf6679), onErrorContainer: Color(0xff000000), background: Color(0xff121212), onBackground: Color(0xffffffff), surface: Color(0xff121212), onSurface: Color(0xffffffff), surfaceVariant: Color(0xff121212), onSurfaceVariant: Color(0xffffffff), outline: Color(0xffffffff), outlineVariant: Color(0xffffffff), inverseSurface: Color(0xffffffff), onInverseSurface: Color(0xff121212), inversePrimary: Color(0xff000000), surfaceTint: Color(0xffbb86fc))

// Workaround for https://github.com/material-foundation/flutter-packages/issues/582
(ColorScheme light, ColorScheme dark) _generateDynamicColourSchemes(
    final ColorScheme lightDynamic, final ColorScheme darkDynamic) {
  final ColorScheme lightBase =
      ColorScheme.fromSeed(seedColor: lightDynamic.primary);
  final ColorScheme darkBase = ColorScheme.fromSeed(
      seedColor: darkDynamic.primary, brightness: Brightness.dark);

  final List<Color> lightAdditionalColours =
      _extractAdditionalColours(lightBase);
  final List<Color> darkAdditionalColours = _extractAdditionalColours(darkBase);

  final ColorScheme lightScheme =
      _insertAdditionalColours(lightBase, lightAdditionalColours);
  final ColorScheme darkScheme =
      _insertAdditionalColours(darkBase, darkAdditionalColours);

  return (lightScheme.harmonized(), darkScheme.harmonized());
}

List<Color> _extractAdditionalColours(final ColorScheme scheme) => <Color>[
      scheme.surface,
      scheme.surfaceDim,
      scheme.surfaceBright,
      scheme.surfaceContainerLowest,
      scheme.surfaceContainerLow,
      scheme.surfaceContainer,
      scheme.surfaceContainerHigh,
      scheme.surfaceContainerHighest,
    ];

ColorScheme _insertAdditionalColours(
        final ColorScheme scheme, final List<Color> additionalColours) =>
    scheme.copyWith(
      surface: additionalColours[0],
      surfaceDim: additionalColours[1],
      surfaceBright: additionalColours[2],
      surfaceContainerLowest: additionalColours[3],
      surfaceContainerLow: additionalColours[4],
      surfaceContainer: additionalColours[5],
      surfaceContainerHigh: additionalColours[6],
      surfaceContainerHighest: additionalColours[7],
    );
