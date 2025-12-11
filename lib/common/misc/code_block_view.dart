import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
import 'package:flutter_highlighting/themes/atom-one-light.dart';
import 'package:flutter_highlighting/themes/monokai-sublime.dart';

class CodeBlockView extends StatelessWidget {
  const CodeBlockView(
    this.data, {
    this.language,
    super.key,
  });
  final String data;
  final String? language;
  @override
  Widget build(final BuildContext context) {
    final String currentLanguage =
        switch (allLanguages.containsKey(language ?? '')) {
      true => language!,
      false => 'plaintext',
    };

    return HighlightView(
      data,
      backgroundColor: Colors.transparent,
      theme: _getTheme(context),
      languageId: currentLanguage,
      selectable: true,
    );
  }

  Map<String, TextStyle> _getTheme(final BuildContext context) =>
      switch (context.colorScheme.brightness) {
        Brightness.dark => monokaiSublimeTheme,
        Brightness.light => atomOneLightTheme,
      };
}
