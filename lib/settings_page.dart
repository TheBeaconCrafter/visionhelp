import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';

class SettingsPage extends StatefulWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final String appName;
  final String version;
  final String creator;

  const SettingsPage({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged, required this.appName, required this.version, required this.creator,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedLanguage;

  int _tapCount = 0;
  int currentPageIndex = 2;
  bool isListening = false; // New variable to track listening state

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
        title: const Text('Einstellungen'),
        centerTitle: true,
      ),
      body: Padding(
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
            ListTile(
              title: const Text('Primäre Sprache zur Erkennung'),
              subtitle: DropdownButton<String>(
                value: _selectedLanguage,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                  });
                  widget.onLanguageChanged(newValue!);
                },
                items: <String>['Deutsch', 'English', 'Español', 'Français']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              textColor: Colors.deepOrangeAccent,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _resetApp(context);
              },
              child: const Text('Reset App and Start Onboarding'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the onboarding page without resetting
                context.go('/onboarding');
              },
              child: const Text('Go to Onboarding Page'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Reset shared preferences
                SharedPreferences.getInstance().then((prefs) {
                  prefs.clear();
                  print("Prefs cleared");
                });
              },
              child: const Text('Reset shared preferences'),
            ),
          ],
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
            context.go('/contacts');
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
            icon: Icon(Icons.contacts),
            label: 'Kontakte',
          ),
        ],
      ),
    );
  }

  void _resetApp(BuildContext context) async {
    // Reset the app by clearing shared preferences or performing other necessary actions
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Restart.restartApp();
  }
}
