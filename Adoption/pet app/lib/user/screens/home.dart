import 'package:flutter/material.dart';
import 'package:flutter_application_1/messageScreen.dart';
import 'package:flutter_application_1/user/screens/searchScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;

  // Sample data for suggestions with local images and descriptions
  final List<Map<String, String>> _suggestions = [
    {
      "image": "asset/image/dog1.png", // Local image path
      "text": "Suggestion 1",
      "description":
          "This is a brief description of Suggestion 1. It could be a bit longer to test multi-line wrapping."
    },
    {
      "image": "asset/image/dog2.png", // Local image path
      "text": "Suggestion 2",
      "description": "This is a brief description of Suggestion 2."
    },
    {
      "image": "asset/image/dog1.png", // Local image path
      "text": "Suggestion 3",
      "description":
          "This is a brief description of Suggestion 3. It is a bit longer to test multiline handling."
    },
    {
      "image": "asset/image/dog1.png", // Local image path
      "text": "Suggestion 4",
      "description": "This is a brief description of Suggestion 4."
    },
  ];

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();

    // Initialize screens dynamically
    _screens.addAll([
      const Messagescreen(),
      const Searchscreen(),
      _buildHomeScreen(), // Home screen
      const Center(child: Text('Cart Screen', style: TextStyle(fontSize: 24))),
      const Center(
          child: Text('Profile Screen', style: TextStyle(fontSize: 24))),
    ]);
  }

  // Home screen widget with suggestions
  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Image.asset(
                          suggestion["image"]!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit
                              .cover, // Adjusts image according to container
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              height: 150,
                              child: Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          suggestion["text"]!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          suggestion["description"]!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(
                                0xFF191970), // Optional: Make description grey
                          ),
                          maxLines: 3, // Allow up to 3 lines
                          overflow: TextOverflow
                              .ellipsis, // Add ellipsis if text overflows
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
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'My Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
