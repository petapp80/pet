import 'package:flutter/material.dart';
import 'userEdit.dart'; // Import the UserEdit screen

class NewlyRegistered extends StatefulWidget {
  const NewlyRegistered({super.key});

  @override
  State<NewlyRegistered> createState() => _NewlyRegisteredState();
}

class _NewlyRegisteredState extends State<NewlyRegistered> {
  String selectedCategory = 'Users'; // Default category
  String searchQuery = ''; // Current search query

  // Mock data for newly registered users
  final List<Map<String, dynamic>> users = [
    {'name': 'Alice', 'description': 'Loves outdoor activities and nature.'},
    {'name': 'Bob', 'description': 'A tech enthusiast and gamer.'},
    {'name': 'Charlie', 'description': 'Enjoys painting and reading books.'},
    {
      'name': 'Diana',
      'description': 'Yoga lover and health-conscious individual.'
    },
  ];

  // Mock data for newly registered pets
  final List<Map<String, dynamic>> pets = [
    {
      'name': 'Fluffy',
      'description': 'A playful kitten who loves chasing balls.'
    },
    {'name': 'Sparky', 'description': 'A curious puppy with a lot of energy.'},
    {'name': 'Max', 'description': 'An affectionate dog who loves to cuddle.'},
    {'name': 'Bella', 'description': 'A gentle cat with a calm temperament.'},
  ];

  // Function to filter and search users or pets
  List<Map<String, dynamic>> get filteredItems {
    List<Map<String, dynamic>> data =
        selectedCategory == 'Users' ? users : pets;

    // Apply search filtering
    if (searchQuery.isNotEmpty) {
      data = data.where((item) {
        return item['name']
                ?.toLowerCase()
                .contains(searchQuery.toLowerCase()) ??
            false;
      }).toList();
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$selectedCategory - Newly Registered'),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Select Filter'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _filterOption('All'),
                        _filterOption('Users'),
                        _filterOption('Pets'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Category switch (Users / Pets)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = 'Users';
                    });
                  },
                  child: const Text('Users'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = 'Pets';
                    });
                  },
                  child: const Text('Pets'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search bar
            TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 10),

            // Display filtered user or pet list
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text('No items found.'))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Card(
                          child: ListTile(
                            title: Text(item['name'] ?? 'No name'),
                            subtitle:
                                Text(item['description'] ?? 'No description'),
                            onTap: () {
                              // Pass the category (isUser) flag to UserEdit
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserEdit(
                                    name: item['name'] ?? 'No name',
                                    description:
                                        item['description'] ?? 'No description',
                                    isUser: selectedCategory ==
                                        'Users', // Passing the isUser flag
                                  ),
                                ),
                              );
                            },
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

  // Helper to create filter options
  Widget _filterOption(String option) {
    return ListTile(
      title: Text(option),
      onTap: () {
        setState(() {
          if (option == 'All') {
            selectedCategory = 'Users';
          } else {
            selectedCategory = option;
          }
        });
        Navigator.of(context).pop();
      },
    );
  }
}
