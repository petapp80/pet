import 'package:flutter/material.dart';

// Dummy UserEdit screen for navigation
import 'userEdit.dart'; // Make sure to import the UserEdit implementation here.

class UserSearch extends StatefulWidget {
  const UserSearch({super.key});

  @override
  State<UserSearch> createState() => _UserSearchState();
}

class _UserSearchState extends State<UserSearch> {
  String searchQuery = '';
  bool isSearchingUsers = true; // Toggle between searching users and pets

  final List<Map<String, String>> users = [
    {'name': 'John Doe', 'description': 'A regular user'},
    {'name': 'Jane Smith', 'description': 'An avid traveler'},
  ];

  final List<Map<String, String>> pets = [
    {'name': 'Buddy', 'description': 'A friendly dog', 'type': 'Dog'},
    {'name': 'Whiskers', 'description': 'A curious cat', 'type': 'Cat'},
  ];

  List<Map<String, String>> get searchResults {
    final items = isSearchingUsers ? users : pets;
    return items
        .where((item) =>
            item['name']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  void _navigateToUserEdit(Map<String, String> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserEdit(
          name: item['name']!,
          description: item['description']!,
          isUser: isSearchingUsers,
          petData: isSearchingUsers ? null : item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search ${isSearchingUsers ? 'Users' : 'Pets'}',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Toggle between Users and Pets
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Users'),
                selected: isSearchingUsers,
                onSelected: (selected) {
                  setState(() {
                    isSearchingUsers = true;
                    searchQuery = ''; // Clear search when switching
                  });
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Pets'),
                selected: !isSearchingUsers,
                onSelected: (selected) {
                  setState(() {
                    isSearchingUsers = false;
                    searchQuery = ''; // Clear search when switching
                  });
                },
              ),
            ],
          ),
          const Divider(),

          // Search Results
          Expanded(
            child: searchResults.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final item = searchResults[index];
                      return ListTile(
                        title: Text(item['name']!),
                        subtitle: Text(item['description']!),
                        onTap: () => _navigateToUserEdit(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
