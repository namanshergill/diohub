import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// flutter packages pub run build_runner watch --delete-conflicting-outputs

StackRouter autoRoute(final BuildContext context) => AutoRouter.of(context);

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(final BuildContext context) : authGuard = AuthGuard(context);
  final AuthGuard authGuard;

  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => <AutoRoute>[
        AutoRoute(page: AuthRoute.page),
        AutoRoute(
          page: LandingLoadingRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
          initial: true,
        ),
        AutoRoute(
          page: HomeRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: PlaceHolderRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        CustomRoute(
          page: SearchOverlayRoute.page,
          transitionsBuilder: TransitionsBuilders.fadeIn,
          guards: <AutoRouteGuard>[authGuard],
        ),
        AutoRoute(
          page: IssuePullRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: RepositoryRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: FileViewerAPI.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: CommitInfoRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: WikiViewer.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: ChangesViewer.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: UserProfileRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: NewIssueRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: PRReviewRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
        AutoRoute(
          page: SearchRoute.page,
          guards: <AutoRouteGuard>[
            authGuard,
          ],
        ),
      ];
}

// class $AppRouter {}

class AuthGuard extends AutoRouteGuard {
  AuthGuard(this.context);

  final BuildContext context;

  @override
  void onNavigation(
    final NavigationResolver resolver,
    final StackRouter router,
  ) {
    if (!BlocProvider.of<AuthenticationBloc>(context).state.authenticated) {
      unawaited(
        router.replaceAll(
          <PageRouteInfo>[
            AuthRoute(
              onAuthenticated: () {
                router.removeLast();
                resolver.next();
              },
            ),
          ],
        ),
      );
    } else {
      resolver.next();
    }
  }
}

// Widget fadeThroughTransition(BuildContext context, Animation<double> animation,
//     Animation<double> secondaryAnimation, Widget child) {
//   return FadeThroughTransition(
//     animation: animation,
//     secondaryAnimation: secondaryAnimation,
//     fillColor: secondary(context),
//     child: child,
//   );
// }

T getRoute<T extends PageRouteInfo>(
  final PathData path, {
  required final T Function(PathData path) onDeepLink,
  final T Function(PathData path)? onAPILink,
}) {
  if (path.isAPIPath && onAPILink != null) {
    return onAPILink(path);
  }
  return onDeepLink(path);
}
