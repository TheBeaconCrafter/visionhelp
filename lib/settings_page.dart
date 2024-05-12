import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';

class SettingsPage extends StatefulWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  const SettingsPage({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedLanguage;

  int currentPageIndex = 2;
  bool isListening = false; // New variable to track listening state

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
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
            const Text(
              'Einstellungen:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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

  void _resetApp(BuildContext context) async {
    // Reset the app by clearing shared preferences or performing other necessary actions
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Restart.restartApp();
  }
}
