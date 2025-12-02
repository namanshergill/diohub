import 'package:flutter/material.dart';
import 'package:dynamic_sliver_app_bar/dynamic_sliver_app_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Dynamic Sliver App Bar Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  bool _showAllOptions = false;
  late final AnimationController _expandController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          AnimatedDynamicSliverAppBar(
            animationController: _expandController,
            toolbarHeight: 64,
            pinned: true,
            title: const Text('Animated App Bar Demo'),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 80), // Space for toolbar
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                  ),
                  const Text(
                    'John Doe',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.email),
                            label: const Text('Messages'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications),
                            label: const Text('Notifications'),
                          ),
                          if (_showAllOptions) ...[
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.settings),
                              label: const Text('Settings'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.favorite),
                              label: const Text('Favorites'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                          ],
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAllOptions = !_showAllOptions;
                              });
                              if (_showAllOptions) {
                                _expandController.forward();
                              } else {
                                _expandController.reverse();
                              }
                            },
                            icon: AnimatedRotation(
                              duration: const Duration(milliseconds: 300),
                              turns: _showAllOptions ? 0.5 : 0,
                              child: const Icon(Icons.expand_more),
                            ),
                            label: Text(_showAllOptions ? 'Less' : 'More'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
        body: ListView.builder(
          itemCount: 50,
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('Item ${index + 1}'),
            subtitle: Text('This is item number ${index + 1}'),
          ),
        ),
      ),
    );
  }
}
