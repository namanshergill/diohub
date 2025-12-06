import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef SizeChangedCallback = void Function(Size size);

/// Calls [onChange] whenever the child's size changes.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({
    required this.onChange,
    super.child,
    super.key,
  });

  final SizeChangedCallback onChange;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    final BuildContext context,
    covariant final _RenderMeasureSize renderObject,
  ) =>
      renderObject.onChange = onChange;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  SizeChangedCallback onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) {
      return;
    }
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (attached) {
        onChange(newSize);
      }
    });
  }
}
