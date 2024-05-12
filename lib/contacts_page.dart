import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<String> contacts = []; // List to store contacts

  TextEditingController _telegramIdController = TextEditingController();

  int currentPageIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> loadedContactsJson = prefs.getStringList('contacts') ?? [];
    List<String> loadedContacts = loadedContactsJson.map((json) {
      Map<String, dynamic> contactInfo = jsonDecode(json);
      return contactInfo['name'] as String; // Display only the name
    }).toList();
    setState(() {
      contacts = loadedContacts;
    });
    print("All contacts: $contacts");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: _buildContactsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddContactDialog(context);
        },
        child: Icon(Icons.add),
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

  Widget _buildContactsList() {
  // Check if contacts are loaded
  if (contacts.isEmpty) {
    // If no contacts, display a message
    return Center(
      child: Text(
        'No contacts available',
        style: TextStyle(fontSize: 18),
      ),
    );
  } else {
    // If contacts are loaded, show the ListView.builder
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => _showContactDetails(context, index),
          child: ListTile(
            title: Text(contacts[index]), // Display only the contact name
            textColor: Colors.white,
          ),
        );
      },
    );
  }
}

void _showContactDetails(BuildContext context, int index) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? contactJson = prefs.getStringList('contacts')?[index];
  if (contactJson != null) {
    Map<String, dynamic>? contactInfo = jsonDecode(contactJson) as Map<String, dynamic>?;
    if (contactInfo != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Contact Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${contactInfo['name'] ?? 'N/A'}'),
                Text('Relationship: ${contactInfo['relationship'] ?? 'N/A'}'),
                Text('Birthdate: ${contactInfo['birthdate'] ?? 'N/A'}'),
                Text('Telegram ID: ${contactInfo['telegram_id'] ?? 'N/A'}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _deleteContact(index);
                  Navigator.of(context).pop();
                },
                child: Text('Delete'),
              ),
            ],
          );
        },
      );
    }
  }
}



// Function to delete contact
void _deleteContact(int index) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> updatedContacts = List.from(contacts)..removeAt(index);
  await prefs.setStringList('contacts', updatedContacts);
  setState(() {
    contacts = updatedContacts;
  });
}


// Helper function to get contact detail by index and field name
String _getContactDetail(int index, String field) {
  Map<String, dynamic> contactInfo = jsonDecode(contacts[index]);
  return contactInfo[field] as String;
}


  // Function to show dialog for adding contact
  Future<void> _showAddContactDialog(BuildContext context) async {
    // Controllers for the additional fields
    TextEditingController _nameController = TextEditingController();
    TextEditingController _relationshipController = TextEditingController();
    TextEditingController _birthdateController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _relationshipController,
                decoration: InputDecoration(labelText: 'Relationship'),
              ),
              TextField(
                controller: _birthdateController,
                decoration: InputDecoration(labelText: 'Birthdate'),
                keyboardType: TextInputType.datetime,
              ),
              TextField(
                controller: _telegramIdController,
                decoration: InputDecoration(labelText: 'Telegram ID'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                print('Adding contact...');
                _addContact(
                  name: _nameController.text,
                  relationship: _relationshipController.text,
                  birthdate: _birthdateController.text,
                  telegram_id: _telegramIdController.text,
                );
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to add contact
  void _addContact(
      {String? name,
      String? relationship,
      String? birthdate,
      String? telegram_id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> contactsList = prefs.getStringList('contacts') ?? [];
    String contactInfoJson = jsonEncode({
      'name': name,
      'relationship': relationship,
      'birthdate': birthdate,
      'telegram_id': telegram_id,
    });
    contactsList.add(contactInfoJson);
    await prefs.setStringList('contacts', contactsList);

    setState(() {
      contacts = contactsList;
      _telegramIdController.clear(); // Clear text field after adding contact
    });

    print("Added contact with these details: $contactInfoJson");
    _loadContacts();
  }
}
