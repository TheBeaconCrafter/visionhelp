import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visionhelp/chatgemini.dart';
import 'main.dart';
import 'settings_page.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatefulWidget {
  final String appName;
  final String version;
  final String creator;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  const AboutPage({
    super.key,
    required this.appName,
    required this.version,
    required this.creator,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  _AboutPageState createState() => _AboutPageState();
}

final _router = AppRouter()._router;

class AppRouter {
  Variables vars = Variables();

  final GoRouter _router = GoRouter(
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return MyHomePage(
            title: Variables().getAppName(), // This was the issue
            currentIndex: 0,
            onTap: (index) {
              // Handle tap on the home page
            },
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) => SettingsPage(
          selectedLanguage: Variables().getSelectedLanguage(),
          onLanguageChanged: (String newLanguage) {
            // Handle language change
          },
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (BuildContext context, GoRouterState state) => AboutPage(
          appName: Variables().getAppName(),
          version: Variables()
              .getVersion(), // Accessing other variables from Variables class
          creator: Variables()
              .getCreator(), // Accessing other variables from Variables class
          selectedLanguage: Variables().getSelectedLanguage(),
          onLanguageChanged: (String newLanguage) {},
        ),
      ),
      GoRoute(
        path: '/chatgemini',
        builder: (BuildContext context, GoRouterState state) => const ChatApp(),
      ),
    ],
  );
}

// Inside _AboutPageState class
class _AboutPageState extends State<AboutPage> {
  // ignore: unused_field
  late String _selectedLanguage;
  int _tapCount = 0;
  int currentPageIndex = 3;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
  }

  void _onVersionNumberTap() {
    setState(() {
      _tapCount++;

      if (_tapCount == 10) {
        // Show Snackbar with funny text
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Du bist aber neugierig!\n🍰🎂'),
          ),
        );

        // Reset tap count after showing the Snackbar
        _tapCount = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Über ${widget.appName}'),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Willkommen zu ${widget.appName}!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _onVersionNumberTap,
                child: Text(
                  'Version: ${widget.version}',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Entwickelt von: ${widget.creator}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });

          if (index == 0) {
            HapticFeedback.lightImpact();
            context.go('/');
          } else if (index == 1) {
            HapticFeedback.lightImpact();
            context.go('/chatgemini');
          } else if (index == 2) {
            HapticFeedback.lightImpact();
            context.go('/settings');
          } else if (index == 3) {
            HapticFeedback.lightImpact();
            context.go('/about');
          }
        },
        indicatorColor: Colors.deepOrangeAccent,
        selectedIndex: currentPageIndex,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
          NavigationDestination(
            icon: Icon(Icons.info),
            label: 'Über',
          ),
        ],
      ),
    );
  }
}
