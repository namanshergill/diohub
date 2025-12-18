// import 'package:artemis/artemis.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:diohub/app/api_handler/response_handler.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/models/popup/popup_type.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:ferry/ferry.dart';
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_exec/gql_exec.dart' as gql_exec;
import 'package:path_provider/path_provider.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:uuid/uuid.dart';

part 'cache.dart';

typedef GQLResponse = gql_exec.Response;
typedef GQLRequest = gql_exec.Request;
typedef GQLOperation = gql_exec.Operation;

class RESTHandler extends BaseAPIHandler {
  RESTHandler({
    super.apiLogSettings,
    super.cacheOptions,
  }) : super(
          baseURL: apiBaseURL,
        );

  RESTHandler.external({
    required super.baseURL,
    super.apiLogSettings,
    super.cacheOptions,
  }) : super(
          addAuthHeader: false,
        );

  Future<Response<T>> get<T>(
    final String url, {
    final bool refreshCache = false,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onReceiveProgress,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    try {
      final Response<T> response = await _request(
        requestHeaders: requestHeaders,
        overrideAPICache: activeCacheOptions.copyWith(
          cachePolicy: refreshCache ? CachePolicy.refresh : null,
        ),
      ).get<T>(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on Exception {
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    final String url, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onSendProgress,
    final ProgressCallback? onReceiveProgress,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    try {
      final Response<T> response = await _request(
        requestHeaders: requestHeaders,
      ).post<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on Exception {
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
    final String url, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onSendProgress,
    final ProgressCallback? onReceiveProgress,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    try {
      final Response<T> response = await _request(
        requestHeaders: requestHeaders,
      ).put<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on Exception {
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    final String url, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    try {
      final Response<T> response = await _request(
        requestHeaders: requestHeaders,
      ).delete<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on Exception {
      rethrow;
    }
  }

  Future<Response<T>> patch<T>(
    final String url, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final Map<String, dynamic>? requestHeaders,
    final ProgressCallback? onSendProgress,
    final ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response<T> response = await _request(
        requestHeaders: requestHeaders,
      ).patch<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      );
      return response;
    } on Exception {
      rethrow;
    }
  }

  static const String _githubAPIVersion = '2022-11-28';

  @override
  Future<void> onRequest(
      final RequestOptions options, final RequestInterceptorHandler handler) {
    options.headers['X-GitHub-Api-Version'] = _githubAPIVersion;
    return super.onRequest(options, handler);
  }
}

class GraphqlHandler extends BaseAPIHandler {
  GraphqlHandler({
    super.apiLogSettings,
    super.cacheOptions,
  }) : super(
          baseURL: '$apiBaseURL/graphql',
        );

  Future<GQLResponse> mutation(
    final OperationRequest<dynamic, dynamic> operationRequest,
  ) =>
      _query(
        operationRequest,
        overrideAPICache: APICache.noCache(),
      );

  Future<GQLResponse> query(
    final OperationRequest<dynamic, dynamic> operationRequest, {
    final bool refreshCache = false,
    final Map<String, dynamic>? requestHeaders,
  }) async =>
      _query(
        operationRequest,
        requestHeaders: requestHeaders,
        overrideAPICache: activeCacheOptions.copyWith(
          cachePolicy: refreshCache ? CachePolicy.refresh : null,
        ),
      );

  @override
  APICache get _defaultCacheOptions => APICache.gql();

  Future<GQLResponse> _query(
    final OperationRequest<dynamic, dynamic> operationRequest, {
    final APICache? overrideAPICache,
    final Map<String, dynamic>? requestHeaders,
  }) async =>
      DioLink(
        '$apiBaseURL/graphql',
        client: _request(
          overrideAPICache: overrideAPICache,
          requestHeaders: requestHeaders,
        ),
      )
          .request(
            GQLRequest(
              operation: operationRequest.operation,
              // ignore: avoid_dynamic_calls
              variables: operationRequest.vars.toJson(),
            ),
          )
          .first
          .onError<DioLinkServerException>(
        (final DioLinkServerException error, final StackTrace stackTrace) {
          // If data is from cache the header would be 304, hence the value should
          // be returned.
          if (error.response.statusCode == 304) {
            final gql_exec.Response gqlResponse =
                const ResponseParser().parseResponse(error.response.data);
            return GQLResponse(
              data: gqlResponse.data,
              errors: gqlResponse.errors,
              response: gqlResponse.response,
            );
          } else {
            throw error;
          }
        },
      );

  @override
  Future<void> onResponse(
    final Response<Object?> response,
    final ResponseInterceptorHandler handler,
  ) async {
    final gql_exec.Response gqlResponse = const ResponseParser()
        .parseResponse(response.data! as Map<String, dynamic>);
    if (gqlResponse.errors != null) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          error: gqlResponse.errors,
        ),
      );
    }
  }
}

abstract class BaseAPIHandler {
  BaseAPIHandler({
    required this.baseURL,
    this.cacheOptions,
    this.apiLogSettings,
    this.addAuthHeader = true,
    this.propagateMessagesToUI = true,
  });

  final bool addAuthHeader;
  final APICache? cacheOptions;
  final String baseURL;
  final bool propagateMessagesToUI;

  APICache get _defaultCacheOptions => APICache();

  APICache get activeCacheOptions => cacheOptions ?? _defaultCacheOptions;

  final APILoggingSettings? apiLogSettings;

  APILoggingSettings? get defaultAPILogSettings => APILoggingSettings();

  Future<void> onError(
    final DioException error,
    final ErrorInterceptorHandler handler,
  ) async {}

  Future<void> onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) async {}

  Future<void> onResponse(
    final Response<Object?> response,
    final ResponseInterceptorHandler handler,
  ) async {}

  Dio _request({
    final Map<String, dynamic>? requestHeaders,
    final APICache? overrideAPICache,
  }) {
    final APICache cache =
        overrideAPICache ?? cacheOptions ?? _defaultCacheOptions;

    final Dio dio = Dio();
    // Log the request in the console if `apiLogSettings` is not null.
    final APILoggingSettings? logSettings =
        apiLogSettings ?? defaultAPILogSettings;
    dio.interceptors.add(
      ChuckerDioInterceptor(),
    );
    if (logSettings != null) {
      if (logSettings.cURL) {
        dio.interceptors.add(
          CurlLoggerDioInterceptor(
            printOnSuccess: true,
          ),
        );
      }
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: logSettings.requestHeader,
          requestBody: logSettings.requestBody,
          responseHeader: logSettings.responseHeader,
          error: logSettings.error,
          responseBody: logSettings.responseBody,
          compact: logSettings.compact,
          logPrint: logSettings.logPrint ?? print,
          maxWidth: logSettings.maxWidth,
          request: logSettings.request,
        ),
      );
    }

    if (addAuthHeader) {
      dio.interceptors.add(
        QueuedInterceptorsWrapper(
          onRequest: (
            final RequestOptions options,
            final RequestInterceptorHandler handler,
          ) async {
            try {
              final AuthRepository authRepo = AuthRepository();
              final String? token = await authRepo.getAccessTokenFromDevice();
              options.headers['Authorization'] = 'token $token';
              handler.next(options);
            } on Exception catch (e) {
              log.e('Could not fetch auth token from device.', error: e);
              handler.reject(
                DioException(
                  requestOptions: options,
                  error: e,
                ),
              );
            }
          },
        ),
      );
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          final RequestOptions options,
          final RequestInterceptorHandler handler,
        ) async {
          options.baseUrl = baseURL;
          options.headers['Accept'] = 'application/json';
          options.headers['setContentType'] = 'application/json';
          options.headers['User-Agent'] = 'com.felix.diohub';
          if (requestHeaders != null) {
            options.headers.addAll(requestHeaders);
          }
          await onRequest(options, handler);
          // Proceed with the request.
          handler.next(options);
        },
        onResponse: (
          final Response<Object?> response,
          final ResponseInterceptorHandler handler,
        ) async {
          await onResponse(response, handler);
          handler.next(response);
        },
        onError: (
          final DioException error,
          final ErrorInterceptorHandler handler,
        ) async {
          await onError(error, handler);
          // TODO(namanshergill): Add better exception handling based on response codes.
          if (error.response == null) {
            handler.next(error);
          } else if (error.response?.data.runtimeType is Map &&
              error.response?.data.containsKey('message') &&
              propagateMessagesToUI) {
            ResponseHandler.setErrorMessage(
              AppPopupData(title: error.response!.data['message']),
            );
          }
          handler.next(error);
        },
      ),
    );
    // Check cache first and return cached data if supplied maxAge
    // has not elapsed. Skipped if cacheOptions is null as the default
    // behaviour in that case is to refresh the data.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          final RequestOptions options,
          final RequestInterceptorHandler handler,
        ) async {
          final bool checkCache =
              cache.cacheOptions.policy != CachePolicy.noCache &&
                  cache.cacheOptions.policy != CachePolicy.refresh &&
                  cache.maxAge != null;
          if (checkCache) {
            final String key = cache.cacheOptions
                .keyBuilder(url: options.uri, headers: options.headers.cast());
            final CacheResponse? cacheData = await _cacheStore.get(key);
            final bool cacheIsBeforeExpiry = cacheData != null &&
                DateTime.now().isBefore(
                  cacheData.responseDate.add(
                    cache.maxAge!,
                  ),
                );
            if (cacheIsBeforeExpiry) {
              // Resolve the request and pass cached data as response.
              return handler.resolve(cacheData.toResponse(options));
            }
          }
          handler.next(options);
        },
      ),
    );
    // Add the interceptor to handle caching.
    dio.interceptors.add(
      DioCacheInterceptor(options: cache.cacheOptions),
    );

    return dio;
  }

  static late final CacheStore _cacheStore;

  static Future<void> setupDioAPICache() async {
    String? directoryPath;

    directoryPath = (await getApplicationDocumentsDirectory()).path;
    _cacheStore = MemCacheStore();
  }

  static Future<void> clearCache() async {
    await _cacheStore.clean();
  }

  Map<String, dynamic> acceptHeader(final String header) => <String, dynamic>{
        'Accept': header,
      };
}

class APILoggingSettings {
  APILoggingSettings({
    this.request = false,
    this.cURL = true,
    this.requestHeader = false,
    this.requestBody = false,
    this.responseHeader = false,
    this.responseBody = false,
    this.error = true,
    this.maxWidth = 90,
    this.compact = true,
    this.logPrint,
  });

  APILoggingSettings.comprehensive({
    this.maxWidth = 90,
    this.compact = true,
    this.logPrint,
    this.cURL = true,
  })  : request = true,
        requestHeader = true,
        requestBody = true,
        responseHeader = true,
        responseBody = true,
        error = true;

  /// Print request [Options]
  final bool request;
  final bool cURL;

  /// Print request header [Options.headers]
  final bool requestHeader;

  /// Print request data [Options.data]
  final bool requestBody;

  /// Print [Response.data]
  final bool responseBody;

  /// Print [Response.headers]
  final bool responseHeader;

  /// Print error message
  final bool error;

  /// InitialTab count to logPrint json response
  static const int initialTab = 1;

  /// 1 tab length
  static const String tabStep = '    ';

  /// Print compact json response
  final bool compact;

  /// Width size per logPrint
  final int maxWidth;

  /// Log printer; defaults logPrint log to console.
  /// In flutter, you'd better use debugPrint.
  /// you can also write log in a file.
  void Function(Object object)? logPrint;
}
