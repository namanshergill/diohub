import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/models/events/events_model.dart';
import 'package:diohub/utils/type_cast.dart';

class EventsService {
  static final RESTHandler _restHandler = RESTHandler(
      // apiLogSettings: APILoggingSettings.comprehensive(),
      );

  // Ref: https://docs.github.com/en/rest/reference/activity#list-events-for-the-authenticated-user
  static Future<List<EventsModel>> getUserEvents(
    final String? user, {
    required final bool refresh,
    final int? page,
    final int? perPage,
  }) async {
    final Response<List<dynamic>> response =
        await _restHandler.get<List<dynamic>>(
      '/users/$user/events',
      queryParameters: <String, dynamic>{'per_page': perPage, 'page': page},
      refreshCache: refresh,
    );
    final List<dynamic> unParsedEvents = response.data!;
    final List<EventsModel> parsedEvents = <EventsModel>[];
    for (final TypeMap event in unParsedEvents) {
      parsedEvents.add(EventsModel.fromJson(event));
    }
    return parsedEvents;
  }

  // Ref: https://docs.github.com/en/rest/reference/activity#list-events-received-by-the-authenticated-user
  static Future<List<EventsModel>> getReceivedEvents(
    final String? user, {
    final bool refresh = false,
    final int? perPage,
    final int? page,
  }) async {
    final Map<String, dynamic> parameters = <String, dynamic>{
      'per_page': perPage,
      'page': page,
    };
    final Response<DynamicList> response = await _restHandler.get<DynamicList>(
      '/users/$user/received_events',
      queryParameters: parameters,
      refreshCache: refresh,
    );
    return response.data!
        .map(
          // ignore: unnecessary_lambdas
          (final dynamic e) => EventsModel.fromJson(e),
        )
        .toList();
  }

  // Ref: https://docs.github.com/en/rest/reference/activity#list-public-events
  static Future<List<EventsModel>> getPublicEvents({
    final bool refresh = false,
    final int? perPage,
    final int? page,
  }) async {
    final Map<String, dynamic> parameters = <String, dynamic>{
      'per_page': perPage,
      'page': page,
    };
    final Response<DynamicList> response = await _restHandler.get<DynamicList>(
      '/events',
      queryParameters: parameters,
      refreshCache: refresh,
    );
    return response.data!
        .map(
          // ignore: unnecessary_lambdas
          (final dynamic e) => EventsModel.fromJson(e),
        )
        .toList();
  }
}
