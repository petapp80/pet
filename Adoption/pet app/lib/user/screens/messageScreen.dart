import 'package:flutter/material.dart';
import 'chatDetailScreen.dart'; // Import the ChatDetailScreen

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

  // Simulate a refresh action
  Future<void> _refreshMessages() async {
    // Simulate a delay for refreshing data
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      // Optionally, shuffle messages to simulate new data
      _filteredMessages = List.from(_messages)..shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use theme-dependent colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: isDark
            ? Colors.black
            : Colors.blue, // Dark theme for dark mode, light for light mode
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
                filled: true,
                fillColor: isDark
                    ? Colors.grey[800] // Dark background for search bar
                    : Colors.grey[200], // Light background
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 20),

            // List of message boxes with pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMessages, // Trigger refresh
                child: ListView.builder(
                  itemCount: _filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = _filteredMessages[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      color: isDark
                          ? Colors.grey[900] // Dark mode background
                          : Colors.white, // Light mode background
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          message["message"]!,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey[400] // Lighter text in dark mode
                                : Colors.grey[800], // Darker text in light mode
                          ),
                        ),
                        onTap: () {
                          // Navigate to the chat detail screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                name: message["name"]!,
                                image: message["image"]!,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
