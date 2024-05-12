// ignore_for_file: avoid_print, use_key_in_widget_constructors

/*
Copyright (C) 2024 Vincent Wackler

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:io';
import 'package:visionhelp/contacts_page.dart';

import 'secrets.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'chatgemini.dart';
import 'onboarding_screen.dart';
import 'dart:async'; // Needed for StreamSubscription!!!!
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notifications/notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine.dart';

StreamSubscription<NotificationEvent>?
    _subscription; // Declare _subscription at the top-level
FlutterTts flutterTts = FlutterTts();

void checkMicrophonePermission() async {
  PermissionStatus permission = await Permission.microphone.status;

  if (!permission.isGranted) {
    await Permission.microphone.request();
  }
}

var botToken = '6919577665:AAFRZrB4L5vdRbiT9bDOqpItvU2JjmAJvsE';

Future<void> fetchMessagesPeriodically() async {
  Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
    await fetchNewMessages();
  });
}

DateTime lastReadTime = DateTime.now(); // Initialize with the current time

Future<void> fetchNewMessages() async {
  final apiUrl = 'https://api.telegram.org/bot$botToken/getUpdates';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null && data['result'] is List<dynamic>) {
        final messages = data['result'] as List<dynamic>;

        for (var message in messages) {
          if (message['message'] != null &&
              message['message']['date'] != null) {
            final messageTime = DateTime.fromMillisecondsSinceEpoch(
                (message['message']['date'] as int) * 1000);

            // Check if the message is newer than the last read time
            if (messageTime.isAfter(lastReadTime)) {
              final senderName = message['message']['from']['first_name'] as String;

              // Check if the message contains an image
              if (message['message']['photo'] != null) {
                // Download the image
                final List<dynamic> photos = message['message']['photo'] as List<dynamic>;
                final photoId = photos.last['file_id'];
                
                // Analyze the image using Google Gemini
                final geminiResponse = await analyzeImageWithGemini(photoId);

                // Do something with the geminiResponse, e.g., speak it
                flutterTts.setLanguage("de-DE");
                flutterTts.speak("Neues Bild von $senderName: $geminiResponse");
                updateNotificationHistory("START - Bild um $_now.hour:$_now.minute von $senderName: $geminiResponse + ENDE - ");

                // Delete the downloaded image
                //await deleteImage(photoUrl); //TODO: Add this function
              } else if (message['message']['text'] != null) {
                // The message contains text
                final text = message['message']['text'] as String;
                
                // Do something with the text, e.g., display it in your app
                print('New Message from $senderName: $text');
                updateNotificationHistory("START - Benachrichtigung um $_now.hour:$_now.minute von $senderName: $text + ENDE - ");
                flutterTts.setLanguage("de-DE");
                flutterTts.speak("Neue Nachricht von $senderName: $text");
              }

              // Update the last read time to the current message's timestamp
              lastReadTime = messageTime;
            }
          }
        }
      } else {
        print('Invalid response format from Telegram API');
      }
    } else {
      print('Failed to fetch messages. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching messages: $e');
  }
}

Future<String> analyzeImageWithGemini(String imageUrl) async {
  try {
    // Download the image and get its path
    File? imageFile = await downloadImage(imageUrl);

    var response = "";

    if (imageFile != null) {
      print("We are generating!!!!");
      // Use Gemini to analyze the image with text
      await gemini.generateFromTextAndImages(
        query: "Beschreibe dieses Bild.",
        image: imageFile,
      ).then((value){
      response = value.text;
    });

      // Return the generated text from Gemini
      return response;
    }
  } catch (e) {
    print('Error analyzing image with Gemini: $e');
  }

  return '';
}

Future<File?> downloadImage(String fileId) async {
  try {
    //Why does Telegram have this bullshit download process? Why can't they just give me the image URL in the first place?
    final response = await http.get(Uri.parse('https://api.telegram.org/bot$botToken/getFile?file_id=$fileId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final filePath = data['result']['file_path'] as String;

      final downloadLink = 'https://api.telegram.org/file/bot$botToken/$filePath'; //Took me way too long to figure this out, please dont break or I'll cry

      final fileResponse = await http.get(Uri.parse(downloadLink));

      if (fileResponse.statusCode == 200) {
        final appDir = await getTemporaryDirectory();
        final fileExtension = filePath.split('.').last;
        final fileName = "${appDir.path}/temp_image.$fileExtension";

        // Write the image to a file
        await File(fileName).writeAsBytes(fileResponse.bodyBytes);

        // Return the File object
        return File(fileName);
      } else {
        print('Error downloading image: ${fileResponse.statusCode}');
        return null;
      }
    } else {
      print('Error getting file information: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error downloading image: $e');
    return null;
  }
}


Future<void> deleteImage(String imagePath) async {
  try {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    print('Error deleting image: $e');
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(Duration.zero);
  bool isFirstTime = await isFirstTimeOpening();

  runApp(
    MaterialApp(
      home: isFirstTime ? OnboardingScreen() : const MyApp(),
    ),
  );
  checkMicrophonePermission();
  startListeningNotifications();
  fetchMessagesPeriodically();
}

Future<bool> isFirstTimeOpening() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('firstTime') ?? true;

  if (isFirstTime) {
    // If it's the first time, set the flag to false
    prefs.setBool('firstTime', false);
  }

  return isFirstTime;
}

List<String> blockedPhrases = [
  "Tap to see your song history",
  "Your messages are available on the device",
  //TODO: Add more phrases
];

bool containsBlockedPhrase(String text) {
  for (String phrase in blockedPhrases) {
    if (text.contains(phrase)) {
      return true; // Found a blocked phrase
    }
  }
  return false; // No blocked phrases found
}

String notificationHistory = "";

void updateNotificationHistory(String newText) {
    notificationHistory += newText;

    //Check if notifications are too many
    if (notificationHistory.length > 1000) {
      print("Trimming notification history");
      print("History before: $notificationHistory");
      // Trim the conversation to the last 500 or so characters
      //Stick with 500
      notificationHistory =
          notificationHistory.substring(notificationHistory.length - 50);
      print("History after: $notificationHistory");
    }
  }

DateTime _now = DateTime.now();

void onData(NotificationEvent event) {
  String notificationText = "${event.title}: ${event.message}";
  // Check if the notificationText contains any blocked phrases
  if (containsBlockedPhrase(notificationText)) {
    print("Not read, because on blocklist: $notificationText");
  } else {
    print(notificationText);
    updateNotificationHistory("START - Benachrichtigung um ${_now.hour}:${_now.minute}: $notificationText ENDE - ");
    print("Notification history: $notificationHistory");
    AudioPlayer().play(AssetSource('audio/notification.mp3'));
    flutterTts.setSilence(1500);
    flutterTts.setLanguage("de-DE"); // TODO: Make this dynamic??? Or not
    flutterTts.speak(notificationText);
  }
}

void startListeningNotifications() {
  Notifications notifications = Notifications();
  try {
    _subscription = notifications.notificationStream?.listen(onData);
    print("Listening for notifications");
  } on NotificationException catch (exception) {
    print(exception);
  }
}

void stopListeningNotifications() {
  _subscription?.cancel();
  print("Stopped listening for notifications");
}

//////////////
//VARIABLES//
/////////////
final gemini = GoogleGemini(
  apiKey: geminiApiKey,
);

String _appname = Variables().getAppName();
String _magicWord = Variables().getMagicWord();
String _version = Variables().getVersion();
String _creator = Variables().getCreator();

class MyApp extends StatefulWidget {
  const MyApp({Key? key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: _appname,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent),
      ),
      routerConfig: _router,
    );
  }
}

final _router = AppRouter()._router;

class Variables {
  final _appName = 'Vision Help';
  final _magicWord = 'Assistant';
  final _version = '0.0.8 Alpha';
  final _creator = 'vncntwww';
  final _selectedLanguage = 'Deutsch';

  String getAppName() {
    return _appName;
  }

  String getMagicWord() {
    return _magicWord;
  }

  String getVersion() {
    return _version;
  }

  String getCreator() {
    return _creator;
  }

  String getSelectedLanguage() {
    return _selectedLanguage;
  }
}

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
          appName: Variables().getAppName(),
          version: Variables()
              .getVersion(), // Accessing other variables from Variables class
          creator: Variables()
              .getCreator(), // Accessing other variables from Variables class
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
        path: '/contacts',
        builder: (BuildContext context, GoRouterState state) => ContactsPage(
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) => OnboardingScreen(),
      ),
      GoRoute(
        path: '/chatgemini',
        builder: (BuildContext context, GoRouterState state) => const ChatApp(),
      ),
    ],
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {Key? key,
      required this.title,
      required this.currentIndex,
      required this.onTap});

  final String title;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  int currentPageIndex = 0;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  // ignore: unused_field, prefer_final_fields
  String _geminiResponse = "";
  String _askGeminiResponse = "";
  double _confidenceLevel = 0;
  String _selectedLanguage = 'Deutsch'; // Default language
  String conversation = ""; //NOTODO: Improve this! Fix crash after too many chars EDIT: SEEMS FIXED
  PorcupineManager? _porcupineManager;
  String _userName = "NICHT ANGEGEBEN";

  void updateConversation(String newText) {
  // Update the conversation with the new text
  conversation += newText;

  // Check if the conversation exceeds the character limit of 200
  if (conversation.length > 200) {
    print("Trimming conversation");
    print("Convo before: $conversation");
    // Trim the conversation to the last 200 characters
    conversation = conversation.substring(conversation.length - 50);
    print("Convo after: $conversation");
  }
}

var usedVoiceButton = false;

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
    print("Before Init");
    //_listenForMagicWord();
    print("After Init");
  }

  Future<void> askGemini(String asktext) async {
    try {
      var value = await gemini.generateFromText(asktext);
      _askGeminiResponse =
          value.text; // Assuming _askGeminiResponse is a global variable
      print(_askGeminiResponse);
      if(_askGeminiResponse.toLowerCase().contains("showmessages")) {
        speakMessagesGeminiContent();
      } else if(_askGeminiResponse.toLowerCase().contains("sendmessage(")) {
        print("Send Message detected");
        var message = _askGeminiResponse.split("(")[1].split(";")[0];
        var receiver = _askGeminiResponse.split(";")[1].split(")")[0];
        print("Message: $message - Receiver: $receiver");
        await sendTelegramMessage(message, receiver);
      }
      updateConversation(" - KI: $_askGeminiResponse");
    } catch (e) {
      print(e);
    }
  }

Future<void> sendTelegramMessage(String message, String receiverName) async {
  try {
    // Get the chat ID from the address book based on the receiver's name
    var chatID = addressBook[receiverName.toLowerCase().replaceAll(' ', '')];

    if (chatID == null) {
      print('Receiver not found in the address book');
      flutterTts.setLanguage("de-DE");
      flutterTts.speak("Dieser Kontakt wurde nicht gefunden.");
      return;
    }

    // Use the retrieved chat ID to construct the API URL
    var apiUrl = 'https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatID&text=$message';

    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      print('Message sent successfully');
      flutterTts.setLanguage("de-DE");
      flutterTts.speak("Die Nachricht wurde erfolgreich gesendet.");
    } else {
      print('Failed to send message. Status code: ${response.statusCode}');
      flutterTts.setLanguage("de-DE");
      flutterTts.speak("Die Nachricht konnte nicht gesendet werden.");
    }
  } catch (e) {
    print('Error sending message: $e');
  }
}

  Future<void> speakMessagesGeminiContent() async {
    AudioPlayer().play(AssetSource('audio/accept.mp3'));
    flutterTts.setSilence(1500);
    print("Speak gemini Messages");
    await askGemini("Du bist ab jetzt Omega, eine künstliche Intelligenz die Menschen in ihrem Alltag hilft. Du bist integriert in eine App mit dem Namen Vision Help. Dein Nutzer hat nach seinen Benachrichtigungen gefragt. Im folgenden siehst du den Verlauf der Benachrichtigungen. Anfang: - $notificationHistory - ENDE Benachrichtigungen. Wenn der Nutzer danach gefragt hat, die Nachrichten zusammenzufassen gib diese bitte in wenigen Worten wieder. Wenn nicht nach einer Zusammenfassung gefragt wurde oder keine extra Argumente gegeben wurden, lies die Benachrichtigung komplett vor. Verwende keine Sachen wie 'Anfrage:' und 'Antwort:' da dies den Nutzer verwirrt. Nach dem Doppelpunkt beginnt die Anfrage deines Nutzers, bitte beantworte sie nach den genannten Kriterien: $_wordsSpoken");
    flutterTts.setLanguage("de-DE"); // TODO: Make this dynamic
    flutterTts.speak(_askGeminiResponse);
  }

  Future<void> speakGeminiContent() async {
    AudioPlayer().play(AssetSource('audio/accept.mp3'));
    flutterTts.setSilence(1500);
    await askGeminiWithPrompt(_wordsSpoken); // Wait for askGemini to finish
    updateConversation(" - Nutzer: $_wordsSpoken");
    flutterTts.setLanguage("de-DE"); // TODO: Make this dynamic
    if(_askGeminiResponse.toLowerCase().contains("showmessages")) {
      print("Not spoken! contains showmessages");
    } else if (_askGeminiResponse.toLowerCase().contains("sendmessage(")){
        print("Not spoken! contains sendmessage");
      } else {
      flutterTts.setLanguage("de-DE");
      flutterTts.speak(_askGeminiResponse);
    }
  }

  void _getNameFromSharedPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _userName = prefs.getString('userName') ?? 'NICHT ANGEGEBEN';
        print("User Name: $_userName");
      });
    });
  }

  Future<void> askGeminiWithPrompt(String asktext) async {
    //GEMINI PROMPT
    print("User name is $_userName");
    String geminiprompt =
        "Du bist ab jetzt Omega, eine künstliche Intelligenz die Menschen in ihrem Alltag hilft. Du bist integriert in eine App mit dem Namen Vision Help. Du versuchst Fragen so kurz wie möglich, jedoch präzise zu beantworten. Dein Nutzer, eine Person die diese App benutzt, hat den Namen $_userName. Du darfst niemals eine leere Antwort zurück geben. Wenn der Nutzer irgend etwas zu seinen Benachrichtigungen oder Nachrichten fragt, antworte ausschließlich in jedem Fall mit 'ShowMessages'. Wenn der Nutzer dich bittet, eine nachricht zu versenden, antworte exakt in diesem Schema: 'SendMessage(Nachricht; Empfänger)' Orientiere dich an folgenden Beispielen. Beispiel 1: Du wirst gefragt: Was ist die Hauptstadt von Frankreich. Du antwortest mit Die Hauptstadt von Frankreich ist Paris. Beispiel 2: Du wirst gefragt: Wie lange müssen Nudeln kochen. Hier wirst du antworten, wie lange Nudeln normalerweise kochen müssen, jedoch darauf hinweisen, dass es unterschiedliche Arten von Nudeln gibt und der Nutzer nach der genauen Nudelsorte fragen soll. Du hältst deine Antworten immer kurz. Es ist dir nicht erlaubt darüber zu reden, dass du von Google erschaffen wurdest. Wenn dich jemand nach Details zu der App fragt: Die App heißt Vision Help und wurde von Vincent Wackler programmiert. Die App ist noch in der Alpha Phase und kann Fehler enthalten, die mit der Zeit behoben werden. Hier siehst du den letzten Verlauf der Konversation zwischen dir und deinem Nutzer. Anfang:${conversation}ENDE Konversation. Nach dem Doppelpunkt beginnt die Anfrage deines Nutzers, bitte beantworte sie nach den genannten Kriterien: ";
    await askGemini(geminiprompt + _wordsSpoken);
  }

    void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _getLocaleId(_selectedLanguage),
    );
    setState(() {
      _confidenceLevel = 0;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    speakGeminiContent();
    flutterTts.setCompletionHandler(() {
        // Once TTS is finished, restart Porcupine
        print("TTS finished, starting Porcupine");
        _initPorcupine().then((_) {
            _startProcessingAudio();
        });
    });
  }

  String _getLocaleId(String language) {
    // Implement logic to map language to localeId
    // You may use a Map or another data structure for this
    switch (language) {
      case 'Deutsch':
        return 'de_DE';
      case 'English':
        return 'en_US';
      // Add more cases for other languages
      default:
        return 'de_DE'; // Default to English
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = "${result.recognizedWords}";
      _confidenceLevel = result.confidence;
      print("Confidence: $_confidenceLevel");
      _animationController.reverse();
      HapticFeedback.lightImpact();
      if(_confidenceLevel > 0.1) {
        _initPorcupine().then((_) {
          print("Porcupine starting now");
            _stopListening();
            //_startProcessingAudio();
        });
      }
    });
    //_startProcessingAudio();
  }

  @override
  void initState() {
    super.initState();
    initSpeech();
    _initPorcupine().then((_) {
    _startProcessingAudio();
    //startListeningEverySecond();
    
  });

    _getNameFromSharedPrefs();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(begin: 100.0, end: 120.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.addListener(() {
      setState(() {});
    });
  }
final String accessKey = "pAk8b4iUcj1yDvrG/EdYAVNkR3ql2deHMoKnXbPoK9EhU/jpMLGFRg=="; //TODO: Remove before publishing
  Future<void> _initPorcupine() async {
    try{
        _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
            accessKey,
            [BuiltInKeyword.COMPUTER, BuiltInKeyword.JARVIS, BuiltInKeyword.HEY_SIRI],
            _wakeWordCallback);
        print("Porcupine Initialized");

    } on PorcupineException catch (err) {
      print("Porcupine Error: $err");
        // handle porcupine init error
    } catch (err) {
        print("Porcupine Init Error: $err");
        // handle other errors
    }
    print("How did we get here?");
  }

  void wakeWordFunction() {
    _porcupineManager?.stop();
      _porcupineManager?.delete();
      print("Should have deleted porcupine manager");
      _animationController.forward();
      HapticFeedback.lightImpact();
      _startListening();
  }

  Future<void> _wakeWordCallback(int keywordIndex) async {
    if(keywordIndex == 0) {
      print("Computer detected");
      wakeWordFunction();
    }
    else if (keywordIndex == 1) {
      print("Jarvis detected");
      wakeWordFunction();
    }
    else if (keywordIndex == 2) {
      print("Hey Siri detected");
      wakeWordFunction();
    }
}

void _startProcessingAudio() async {
  try{
    await _porcupineManager?.start();
    print("Porcupine started");
} on PorcupineException catch (ex) {
    print("There was an exception: $ex");
}
}

  void _navigateToAboutPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AboutPage(
          appName: _appname,
          version: _version,
          creator: _creator,
          selectedLanguage: _selectedLanguage,
          onLanguageChanged: (String newLanguage) {
            setState(() {
              _selectedLanguage = newLanguage;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin:
                const EdgeInsets.only(top: 20.0), // Adjust the top margin as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Halte das Mikrofon gedrückt oder sage das magische Wort ($_magicWord):',
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _speechToText.isListening
                      ? "listening..."
                      : _speechEnabled
                          ? "Halte das Mikrofon, um zu starten"
                          : "Ein Fehler ist aufgetreten",
                  style: const TextStyle(fontSize: 20),
                ),
                Expanded(
                  child: Text(_wordsSpoken),
                ),
                if (_speechToText.isNotListening && _confidenceLevel > 0)
                  Text(
                    "Confidence: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          GestureDetector(
            onLongPressStart: (details) {
              usedVoiceButton = true;
              _porcupineManager?.stop();
              _porcupineManager?.delete();
              _animationController.forward();
              _speechToText.isListening ? _stopListening : _startListening;
              HapticFeedback.lightImpact();
              _startListening();
            },
            onLongPressEnd: (details) {
              usedVoiceButton = false;
              _animationController.reverse();
              _speechToText.stop();
              HapticFeedback.lightImpact();
              _stopListening();
              _initPorcupine().then((_) {
                _startProcessingAudio();
              });
            },
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepOrange,
                  ),
                  child: Icon(
                    Icons.mic,
                    size: _animation.value,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
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
}
