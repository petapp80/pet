import 'package:flutter/material.dart';

class Searchscreen extends StatefulWidget {
  const Searchscreen({super.key});

  @override
  State<Searchscreen> createState() => _SearchscreenState();
}

class _SearchscreenState extends State<Searchscreen> {
  // Define the dropdown options
  final List<String> _options = [
    'Pets',
    'Products',
    'Veterinary',
    'Pet Care Tips'
  ];
  String _selectedOption = 'Pets'; // Default selection

  // Example list of items with text and image
  final List<Map<String, String>> _items = [
    {
      "title": "Pet Care Tips",
      "image": "asset/image/dog1.png" // Correct local image path
    },
    {"title": "Best Pet Products", "image": "asset/image/dog1.png"},
    {"title": "Veterinary Services", "image": "asset/image/dog2.png"},
    {"title": "Adopt a Pet", "image": "asset/image/dog1.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar with Embedded Dropdown
            TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Type to search...',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: DropdownButton<String>(
                  value: _selectedOption,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: Container(), // Remove the underline
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOption = newValue!;
                    });
                  },
                  items: _options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // List of items with image and text
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Use Stack for Image Cover and Text
                        Stack(
                          children: [
                            // Displaying the image with BoxFit.cover
                            Image.asset(
                              item["image"]!,
                              height: 180, // Set fixed height
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image,
                                    size: 100, color: Colors.grey);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Displaying the title text with dynamic color
                        Text(
                          item["title"]!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
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
