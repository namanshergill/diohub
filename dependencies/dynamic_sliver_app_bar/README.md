# Animated Dynamic Sliver App Bar

A Flutter package that provides a `SliverAppBar` with automatic height adjustment and smooth animations when content size changes.

## Features

- 🎯 **Automatic Height Calculation**: Measures content and sets `expandedHeight` automatically
- 🎨 **Smooth Animations**: Seamlessly animates height changes when content expands/collapses
- 🔄 **Real-time Updates**: Continuously measures content during animations for smooth transitions
- 🎭 **Overflow Prevention**: Uses `OverflowBox` during animations to allow natural content growth
- 🛠️ **Highly Customizable**: Supports all standard `SliverAppBar` properties

## Usage

### Basic Example

```dart
import 'package:dynamic_sliver_app_bar/animated_dynamic_sliver_app_bar.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        AnimatedDynamicSliverAppBar(
          flexibleSpace: Column(
            children: [
              // Your dynamic content here
              Text('This content determines the app bar height'),
            ],
          ),
          title: Text('My App'),
          pinned: true,
        ),
      ],
      body: YourBodyContent(),
    );
  }
}
```

### With Animation Controller

For smooth animations when content size changes:

```dart
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        AnimatedDynamicSliverAppBar(
          animationController: _animationController,
          flexibleSpace: Column(
            children: [
              Text('My Profile'),
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: _isExpanded 
                    ? ExpandedContent() 
                    : CollapsedContent(),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                  if (_isExpanded) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                },
                child: Text(_isExpanded ? 'Show Less' : 'Show More'),
              ),
            ],
          ),
          title: Text('My App'),
          pinned: true,
        ),
      ],
      body: YourBodyContent(),
    );
  }
}
```

## Parameters

### Core Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `flexibleSpace` | `Widget?` | The content to display in the flexible space. Height is measured from this. |
| `animationController` | `AnimationController?` | Controller for smooth height animations. When animating, uses `OverflowBox` for natural content growth. |
| `heightBuffer` | `double` | Additional pixels to add to measured height (default: 1.0). Prevents tiny overflow errors. |

### Standard SliverAppBar Parameters

All standard `SliverAppBar` parameters are supported:
- `title`, `leading`, `actions`
- `pinned`, `floating`, `snap`
- `backgroundColor`, `elevation`, `shadowColor`
- `toolbarHeight`, `expandedHeight`, `collapsedHeight`
- And more...

## How It Works

1. **Initial Measurement**: On first build, measures the `flexibleSpace` content to determine height
2. **Animation Detection**: When `animationController.isAnimating` is true:
   - Wraps content in `OverflowBox` to allow natural growth
   - Schedules continuous measurements on each frame
   - Updates `expandedHeight` in real-time
3. **Animation Complete**: Switches back to normal container and performs final measurement
4. **Smooth Transition**: `SliverAppBar` automatically animates `expandedHeight` changes

## Tips

- Wrap your dynamic content in `AnimatedSize` for smooth content transitions
- Match the `AnimationController` duration with your content animation duration
- Use `ClipRect` around content if you want to hide any temporary overflow during animation
- The `heightBuffer` parameter helps prevent floating-point precision overflow errors

## Example: Collapsible Buttons

```dart
AnimatedDynamicSliverAppBar(
  animationController: _expandController,
  flexibleSpace: Column(
    children: [
      ProfileHeader(),
      AnimatedSize(
        duration: Duration(milliseconds: 300),
        child: Wrap(
          children: [
            Button('Always Visible'),
            if (_showAll) ...[
              Button('Hidden 1'),
              Button('Hidden 2'),
              Button('Hidden 3'),
            ],
            Button('Toggle', onTap: () {
              setState(() => _showAll = !_showAll);
              _showAll 
                  ? _expandController.forward() 
                  : _expandController.reverse();
            }),
          ],
        ),
      ),
    ],
  ),
  title: Text('Profile'),
  pinned: true,
)
```

## License

MIT License - feel free to use in your projects!
