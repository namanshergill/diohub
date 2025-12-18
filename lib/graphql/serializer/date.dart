import 'package:built_value/serializer.dart';

class DateSerializer implements PrimitiveSerializer<DateTime> {
  @override
  DateTime deserialize(
    final Serializers serializers,
    final Object serialized, {
    final FullType specifiedType = FullType.unspecified,
  }) {
    assert(serialized is String,
        "DateSerializer expected 'String' but got ${serialized.runtimeType}",);
    return DateTime.parse(serialized as String);
  }

  @override
  Object serialize(
    final Serializers serializers,
    final DateTime date, {
    final FullType specifiedType = FullType.unspecified,
  }) =>
      date.toIso8601String();

  @override
  Iterable<Type> get types => <Type>[DateTime];

  @override
  String get wireName => 'Date';
}

class DateTimeSerializer implements PrimitiveSerializer<DateTime> {
  @override
  DateTime deserialize(
      final Serializers serializers,
      final Object serialized, {
        final FullType specifiedType = FullType.unspecified,
      }) {
    assert(serialized is String,
    "DateSerializer expected 'String' but got ${serialized.runtimeType}",);
    return DateTime.parse(serialized as String);
  }

  @override
  Object serialize(
      final Serializers serializers,
      final DateTime date, {
        final FullType specifiedType = FullType.unspecified,
      }) =>
      date.toIso8601String();

  @override
  Iterable<Type> get types => <Type>[DateTime];

  @override
  String get wireName => 'DateTime';
}
