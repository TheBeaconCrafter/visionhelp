import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        primaryColor: Colors.deepOrangeAccent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.deepOrangeAccent,
            elevation: 3,
          ),
        ),
        textTheme: const TextTheme(
          headline4: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyText1: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildNamePage(),
            _buildPermissionPage(
              icon: Icons.mic,
              permission: Permission.microphone,
              explanation: 'We need access to your microphone for voice commands.',
            ),
            _buildPermissionPage(
              icon: Icons.bluetooth,
              permission: Permission.bluetooth,
              explanation: 'Bluetooth access is required for device connectivity.',
            ),
            _buildPermissionPage(
              icon: Icons.bluetooth_connected,
              permission: Permission.bluetoothConnect,
              explanation: 'Bluetooth connection permission is needed for device communication.',
            ),
            _buildPermissionPage(
              icon: Icons.notifications,
              permission: Permission.notification,
              explanation: 'Notification access is required for important updates.',
            ),
            _buildWelcomePage(),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Vision Help!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Enter Your Name',
              labelStyle: TextStyle(color: Colors.deepOrangeAccent),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.deepOrangeAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.deepOrangeAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _saveName();  // Save the name before transitioning
              _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            child: const Text('Next', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionPage({
    required IconData icon,
    required Permission permission,
    required String explanation,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center( // Wrap the content with Center widget
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 100,
              color: Colors.deepOrangeAccent,
            ),
            const SizedBox(height: 20),
            Text(
              explanation,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center, // Center the text
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await permission.request();
                setState(() {}); // Trigger a rebuild
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Grant', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center( // Wrap the content with Center widget
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome ${_nameController.text}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyApp()),
                );
              },
              child: const Text('Finish', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
  }
}
