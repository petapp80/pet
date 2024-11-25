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

  // Mock data for newly added products
  final List<Map<String, dynamic>> products = [
    {'name': 'Dog Toy', 'description': 'A squeaky toy for playful puppies.'},
    {'name': 'Cat Bed', 'description': 'A soft, cozy bed for your cat.'},
    {'name': 'Pet Collar', 'description': 'Stylish and adjustable collar.'},
    {'name': 'Fish Food', 'description': 'Nutritional feed for aquarium fish.'},
  ];

  // Function to filter and search users, pets, or products
  List<Map<String, dynamic>> get filteredItems {
    List<Map<String, dynamic>> data;
    switch (selectedCategory) {
      case 'Users':
        data = users;
        break;
      case 'Pets':
        data = pets;
        break;
      case 'Products':
        data = products;
        break;
      default:
        data = [];
    }

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
                        _filterOption('Users'),
                        _filterOption('Pets'),
                        _filterOption('Products'),
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
            // Category switch (Users / Pets / Products)
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = 'Products';
                    });
                  },
                  child: const Text('Products'),
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

            // Display filtered user, pet, or product list
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
                                    isUser: selectedCategory == 'Users',
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
          selectedCategory = option;
        });
        Navigator.of(context).pop();
      },
    );
  }
}
