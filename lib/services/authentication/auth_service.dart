import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/app/keys.dart';
import 'package:diohub/models/authentication/access_token_model.dart';
import 'package:diohub/models/authentication/device_code_model.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/type_cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final RESTHandler _restHandler = RESTHandler.external(
    baseURL: 'https://github.com/login/',
    cacheOptions: APICache.noCache(),
    apiLogSettings: APILoggingSettings.comprehensive(),
  );

  Future<bool> get isAuthenticated async {
    final String? token = await getAccessTokenFromDevice();
    debugPrint('Auth token ${token ?? 'not found.'}');
    if (token != null) {
      return true;
    }
    return false;
  }

  Future<void> storeAccessToken(final AccessTokenModel accessTokenModel) async {
    await _storage.write(
      key: 'accessToken',
      value: accessTokenModel.accessToken,
    );
    await _storage.write(key: 'scope', value: accessTokenModel.scope);
  }

  Future<String?> getAccessTokenFromDevice() async {
    try {
      final String? accessToken = await _storage.read(key: 'accessToken');
      return accessToken;
    } on PlatformException {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await logOut(sendToAuthScreen: false);
    }
    return null;
  }

  Future<TypeMap> getDeviceToken() async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'client_id': PrivateKeys.clientID,
      'scope': scopeString,
    });
    final Response<TypeMap> response =
        await _restHandler.post<TypeMap>('device/code', data: formData);
    return response.data!;
  }

  String get scopeString => scopes.join(' ');
  List<String> get scopes => const <String>[
        'repo',
        'public_repo',
        'repo:invite',
        // `read:org` is the least-privileged scope that still lets us list
        // organizations, their members and their repositories. GitHub asks
        // organization owners to approve OAuth apps separately, so keeping
        // this narrow makes that approval much more likely.
        'read:org',
        'gist',
        'notifications',
        'user',
        'delete_repo',
        'write:discussion',
        'read:packages',
        'delete:packages',
      ];

  /// GitHub's OAuth app settings page. Users can grant or revoke this app's
  /// access to individual organizations here when an organization restricts
  /// third-party applications.
  static Uri get organizationAccessSettingsUri => Uri.parse(
        'https://github.com/settings/connections/applications/'
        '${PrivateKeys.clientID}',
      );

  Future<TypeMap> getAccessToken({final String? deviceCode}) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'client_id': PrivateKeys.clientID,
      'device_code': deviceCode,
      'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
    });
    try {
      final Response<TypeMap> response = await _restHandler
          .post<TypeMap>('oauth/access_token', data: formData);
      if (response.data!['access_token'] != null) {
        return response.data!;
      } else if (response.data!['error'] != null &&
          response.data!['error'] != 'authorization_pending' &&
          response.data!['error'] != 'slow_down') {
        throw Exception(response.data!['error_description']);
      }
      return response.data!;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<DeviceCodeModel> getDeviceCode() async {
    final TypeMap data = await getDeviceToken();
    if (data['device_code'] != null) {
      return DeviceCodeModel.fromJson(data);
    }
    //Exception is thrown if the response does not contain device_code.
    throw Exception('Some error occurred.');
  }

  Future<void> logOut({final bool sendToAuthScreen = true}) async {
    await BaseAPIHandler.clearCache();
    await _storage.deleteAll();
    if (sendToAuthScreen) {
      if (currentContext.mounted) {
        await AutoRouter.of(currentContext).replaceAll(
          <PageRouteInfo>[
            AuthRoute(),
          ],
        );
      }
    }
  }

  Future<AccessTokenModel> oauth2() async {
    const FlutterAppAuth appAuth = FlutterAppAuth();
    final AuthorizationTokenResponse? result =
        await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        PrivateKeys.clientID,
        'auth.felix.diohub://login-callback',
        clientSecret: PrivateKeys.clientSecret,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          tokenEndpoint: 'https://github.com/login/oauth/access_token',
          authorizationEndpoint: 'https://github.com/login/oauth/authorize',
        ),
        scopes: scopes,
      ),
    );
    return AccessTokenModel(
      accessToken: result!.accessToken,
      scope: scopeString,
    );
  }
}
