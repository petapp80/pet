import 'package:flutter/material.dart';

class Messagescreen extends StatefulWidget {
  const Messagescreen({super.key});

  @override
  State<Messagescreen> createState() => _MessagescreenState();
}

class _MessagescreenState extends State<Messagescreen> {
  // Sample list of messages
  final List<Map<String, String>> _messages = [
    {
      "name": "John",
      "message": "Hey! How are you?",
      "image": "asset/image/dog1.png"
    },
    {
      "name": "Sara",
      "message": "Let’s meet tomorrow.",
      "image": "asset/image/dog1.png"
    },
    {
      "name": "David",
      "message": "Call me when you're free.",
      "image": "asset/image/dog1.png"
    },
    {
      "name": "Emma",
      "message": "Got the package today!",
      "image": "asset/image/dog1.png"
    },
  ];

  // Filtered list of messages
  List<Map<String, String>> _filteredMessages = [];

  // Controller for the search bar
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initially, the filtered list is the same as the original messages
    _filteredMessages = List.from(_messages);
  }

  // Filter the messages based on the search query
  void _filterMessages(String query) {
    setState(() {
      _filteredMessages = _messages.where((message) {
        return message['name']!.toLowerCase().contains(query.toLowerCase()) ||
            message['message']!.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar at the top
            TextField(
              controller: _searchController,
              onChanged: (query) =>
                  _filterMessages(query), // Filter on text change
              decoration: InputDecoration(
                labelText: 'Search users',
                hintText: 'Type to search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),

            // List of message boxes
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMessages.length,
                itemBuilder: (context, index) {
                  final message = _filteredMessages[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(message["image"]!),
                        radius: 30,
                      ),
                      title: Text(
                        message["name"]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(message["message"]!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
