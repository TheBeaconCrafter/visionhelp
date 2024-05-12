import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_gemini/google_gemini.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:visionhelp/about_page.dart';
import 'package:visionhelp/main.dart';
import 'package:visionhelp/settings_page.dart';

const apiKey = "AIzaSyDpZ5mGDmmGyVl1a0rAQqfsVdyY00rM8HI";

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent),
      ),
      home: const ChatHomePage(),
    );
  }
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

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key,});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  int currentPageIndex = 1; // Add this line to manage the current page index

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Google Gemini"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Text Only"),
              Tab(text: "Text with Image"),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            TextOnly(),
            TextWithImage()
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
      ),
    );
  }
}




// ------------------------------ Text with Image ------------------------------

class TextOnly extends StatefulWidget {
  const TextOnly({super.key,});

  @override
  State<TextOnly> createState() => _TextOnlyState();
}

class _TextOnlyState extends State<TextOnly> {

  bool loading = false;
  List textChat = [];
  List textWithImageChat = [];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _controller = ScrollController();


  // Create Gemini Instance 
  final gemini = GoogleGemini(
    apiKey: apiKey,
  );

  // Text only input 
  void fromText({required String query}) {
    setState(() {
      loading = true;
      textChat.add({
        "role": "User",
        "text": query,
      });
      _textController.clear();
    });
    scrollToTheEnd();
   

    gemini.generateFromText(query)
    .then((value){
      setState(() {
        loading = false;
        textChat.add({
          "role": "Gemini",
          "text": value.text,
        });
      });
      scrollToTheEnd();
      
    }).onError((error, stackTrace) {
      setState(() {
        loading = false;
        textChat.add({
          "role": "Gemini",
          "text": error.toString(),
        });
      });
      scrollToTheEnd();
    });
  }

  void scrollToTheEnd(){
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _controller,
              itemCount: textChat.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                return ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    child: Text(textChat[index]["role"].substring(0, 1)),
                  ),
                  title: Text(
                    textChat[index]["role"],
                    style: TextStyle(
                      color: textChat[index]["role"] == "User"
                          ? Colors.white // Customize user text color
                          : Colors.white, // Customize Gemini text color
                    ),
                  ),
                  subtitle: Text(
                    textChat[index]["text"],
                    style: TextStyle(
                      color: textChat[index]["role"] == "User"
                          ? Colors.white // Customize user text color
                          : Colors.white, // Customize Gemini text color
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            alignment: Alignment.bottomRight,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color.fromARGB(255, 255, 235, 235)),
            ),
            child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none
                        ),
                        fillColor: Colors.transparent,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  IconButton(
                    icon: loading 
                      ?  const CircularProgressIndicator()
                      : const Icon(Icons.send),
                    onPressed: () {
                      fromText(query: _textController.text);
                    },
                  ),
                ],
              ),
              
          )
        ],
      )
      
    );
  }
}







// ------------------------------ Text with Image ------------------------------

class TextWithImage extends StatefulWidget {
  const TextWithImage({super.key,});

  @override
  State<TextWithImage> createState() => _TextWithImageState();
}

class _TextWithImageState extends State<TextWithImage> {

  bool loading = false;
  List textAndImageChat = [];
  List textWithImageChat = [];
  File? imageFile;

  final ImagePicker picker = ImagePicker();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _controller = ScrollController();


  // Create Gemini Instance 
  final gemini = GoogleGemini(
    apiKey: apiKey,
  );

  // Text only input 
  void fromTextAndImage({required String query, required File image}) {
    setState(() {
      loading = true;
      textAndImageChat.add({
        "role": "User",
        "text": query,
        "image": image,
      });
      _textController.clear();
      imageFile = null;
    });
    scrollToTheEnd();
   

    gemini.generateFromTextAndImages(query: query, image: image)
    .then((value){
      setState(() {
        loading = false;
        textAndImageChat.add({
          "role": "Gemini",
          "text": value.text,
          "image": ""
        });
      });
      scrollToTheEnd();
      
    }).onError((error, stackTrace) {
      setState(() {
        loading = false;
        textAndImageChat.add({
          "role": "Gemini",
          "text": error.toString(),
          "image": ""
        });
      });
      scrollToTheEnd();
    });
  }

  void scrollToTheEnd(){
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _controller,
              itemCount: textAndImageChat.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                return ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    child: Text(textAndImageChat[index]["role"].substring(0, 1)),
                  ),
                  title: Text(
                    textAndImageChat[index]["role"],
                    style: TextStyle(
                      color: textAndImageChat[index]["role"] == "User"
                          ? Colors.white // Customize user text color
                          : Colors.white, // Customize Gemini text color
                    ),
                  ),
                  subtitle: Text(
                    textAndImageChat[index]["text"],
                    style: TextStyle(
                      color: textAndImageChat[index]["role"] == "User"
                          ? Colors.white // Customize user text color
                          : Colors.white, // Customize Gemini text color
                    ),
                  ),
                  trailing: textAndImageChat[index]["image"] == "" 
                    ? null
                    : Image.file(textAndImageChat[index]["image"], width: 90,),
                );
              },
            ),
          ),

          Container(
            alignment: Alignment.bottomRight,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Write a message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none
                        ),
                        fillColor: Colors.transparent,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  IconButton(
                    icon:const Icon(Icons.add_a_photo),
                    onPressed: () async{
                     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                     setState(() {
                      imageFile = image != null ? File(image.path) : null;
                     });
                    },
                  ),
                  IconButton(
                    icon: loading 
                      ?  const CircularProgressIndicator()
                      : const Icon(Icons.send),
                    onPressed: () {
                      if(imageFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select an image"))
                        );
                        return;
                      }
                      fromTextAndImage(query: _textController.text, image: imageFile!);
                    },
                  ),
                ],
              ),
              
          ),
        ],
      ),
      floatingActionButton: imageFile != null ? Container(
        margin: const EdgeInsets.only(bottom: 80),
        height: 150,
        child: Image.file(imageFile ?? File("")),
      ): null,
      
    );
  }
}