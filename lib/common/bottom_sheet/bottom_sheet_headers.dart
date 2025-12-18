part of 'bottom_sheets.dart';

class BottomSheetHeaderText extends StatelessWidget {
  const BottomSheetHeaderText({
    required this.headerText,
    super.key,
    this.textStyle,
  });
  final String headerText;
  final TextStyle? textStyle;

  @override
  Widget build(final BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          headerText,
          style: textStyle ??
              context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
        ),
      );
}
