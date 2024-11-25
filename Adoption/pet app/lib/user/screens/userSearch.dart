import 'package:flutter/material.dart';
import 'userEdit.dart'; // Import your UserEdit screen here.

class UserSearch extends StatefulWidget {
  const UserSearch({super.key});

  @override
  State<UserSearch> createState() => _UserSearchState();
}

class _UserSearchState extends State<UserSearch> {
  String searchQuery = '';
  String selectedCategory = 'Users'; // Default category

  final List<Map<String, String>> users = [
    {'name': 'John Doe', 'description': 'A regular user'},
    {'name': 'Jane Smith', 'description': 'An avid traveler'},
  ];

  final List<Map<String, String>> pets = [
    {'name': 'Buddy', 'description': 'A friendly dog', 'type': 'Dog'},
    {'name': 'Whiskers', 'description': 'A curious cat', 'type': 'Cat'},
  ];

  final List<Map<String, String>> products = [
    {'name': 'Dog Toy', 'description': 'A squeaky toy for playful puppies'},
    {'name': 'Cat Bed', 'description': 'A soft, cozy bed for your cat'},
  ];

  final List<Map<String, String>> veterinary = [
    {'name': 'Dr. Smith', 'description': 'Specialist in small animals'},
    {'name': 'Dr. Brown', 'description': 'Experienced in exotic pets'},
  ];

  // Get search results based on the selected category
  List<Map<String, String>> get searchResults {
    List<Map<String, String>> items;
    switch (selectedCategory) {
      case 'Users':
        items = users;
        break;
      case 'Pets':
        items = pets;
        break;
      case 'Products':
        items = products;
        break;
      case 'Veterinary':
        items = veterinary;
        break;
      default:
        items = [];
    }
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
          isUser: selectedCategory == 'Users',
          petData: selectedCategory == 'Pets' ? item : null,
        ),
      ),
    );
  }

  void _addNewItem() {
    // Replace this with your logic to add a new item
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserEdit(
          name: '',
          description: '',
          isUser: selectedCategory == 'Users',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search $selectedCategory'),
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
                hintText: 'Search $selectedCategory',
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
          // Toggle between Users, Pets, Products, and Veterinary
          Wrap(
            spacing: 10.0,
            alignment: WrapAlignment.center,
            children: [
              _categoryChip('Users'),
              _categoryChip('Pets'),
              _categoryChip('Products'),
              _categoryChip('Veterinary'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        tooltip: 'Add New',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _categoryChip(String category) {
    return ChoiceChip(
      label: Text(category),
      selected: selectedCategory == category,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedCategory = category;
            searchQuery = ''; // Clear search when switching categories
          });
        }
      },
    );
  }
}
