import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';

class Utils {
  Utils._();

  static Map<String, dynamic>? parseJwt(final String token) {
    final List<String> parts = token.split('&');
    if (parts.length != 2) {
      return null;
    }

    final String payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String resp = utf8.decode(base64Url.decode(normalized));
    final dynamic payloadMap = json.decode(resp);
    if (payloadMap is! Map<String, dynamic>) {
      return null;
    }
    return payloadMap;
  }

  static String hexToInt(final String fullString) {
    final String string = fullString.replaceAll('-', '');
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i <= string.length - 8; i += 8) {
      final String hex = string.substring(i, i + 8);

      final int number = int.parse(hex, radix: 16);
      buffer.write(number);
    }
    return buffer.toString();
  }
}

extension ThemeExtension on BuildContext {
  ThemeData get themeData => Theme.of(this);
  ColorScheme get colorScheme => themeData.colorScheme;

  TextTheme get textTheme => themeData.textTheme;
}

extension TextStyles on TextStyle {
  TextStyle asHint() => copyWith(
        color: color?.withOpacity(0.60),
      );

  TextStyle asBold() => copyWith(
        fontWeight: FontWeight.bold,
      );
  TextStyle asDisabled() => copyWith(
        color: color?.withOpacity(0.38),
      );
}

extension OpacityColors on Color {
  Color asHint() => Color(value).fadeBrightness(-0.15);

  Color asDisabled() => Color(value).fadeBrightness(-0.25);
}

extension IconSize on TextStyle {
  double getIconSize(final BuildContext context, {final double scale = 0.7}) {
    // Get the current text scale factor from the MediaQuery
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // You can adjust the scale factor based on your preferences
    // You can remove this line if you want to use the raw textScaleFactor
    final double adjustedScaleFactor = textScaleFactor * scale;

    // Calculate the scaled icon size
    final double scaledSize =
        fontSize != null ? fontSize! * adjustedScaleFactor : 25;

    return scaledSize;
  }
}

extension ColorFader on Color {
  Color fadeBrightness(final double factor) {
    assert(
      factor >= -1.0 && factor <= 1.0,
      'Factor value must be between -1.0 and 1.0',
    );

    final HSLColor hslColor = HSLColor.fromColor(this);
    final HSLColor newHslColor = hslColor.withLightness(
      (hslColor.lightness + factor).clamp(0.0, 1.0),
    );
    return newHslColor.toColor();
  }
}

T unimplemented<T>() => throw UnimplementedError();

String unimplementedString() => 'Unimplemented';

extension BuiltListExtn<T> on Future<BuiltList<T>> {
  Future<List<T>> toAsyncList() async {
    final BuiltList<T> list = await this;
    return list.toList();
  }
}

T returnItself<T>(final T data) => data;

extension StringIntp on int {
  String toShortenedStr() {
    if (this >= 1000000) {
      final double millions = this / 1000000;
      // If it's a whole number, show without decimal
      if (millions == millions.truncateToDouble()) {
        return '${millions.toInt()}M';
      }
      // Otherwise show one decimal place
      return '${millions.toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      final double thousands = this / 1000;
      // If it's a whole number, show without decimal
      if (thousands == thousands.truncateToDouble()) {
        return '${thousands.toInt()}k';
      }
      // Otherwise show one decimal place
      return '${thousands.toStringAsFixed(1)}k';
    }
    return toString();
  }
}
