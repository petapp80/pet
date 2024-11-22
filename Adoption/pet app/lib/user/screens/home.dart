import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/chatDetailScreen.dart';

import 'profile.dart';
import 'cartScreen.dart';
import 'messageScreen.dart';
import 'searchScreen.dart';
import 'addScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  DateTime? lastBackPressed;

  // Sample data for suggestions
  final List<Map<String, String>> _suggestions = [
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 1",
      "description": "This is a description for Suggestion 1.",
      "location": "Location 1",
      "published": "2 days ago",
      "profileName": "John Doe"
    },
    {
      "image": "asset/image/dog2.png",
      "text": "Suggestion 2",
      "description": "This is a description for Suggestion 2.",
      "location": "Location 2",
      "published": "1 week ago",
      "profileName": "Jane Smith"
    },
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 3",
      "description": "This is a description for Suggestion 3.",
      "location": "Location 3",
      "published": "1 month ago",
      "profileName": "Alice Brown"
    },
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 4",
      "description": "This is a description for Suggestion 4.",
      "location": "Location 4",
      "published": "3 months ago",
      "profileName": "Bob Johnson"
    },
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize the screens
    _screens = [
      const Messagescreen(),
      const Searchscreen(),
      _buildHomeScreen(),
      const CartScreen(), // CartScreen without cartItems passed as a parameter
      const ProfileScreen(),
    ];
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10.6),
          const Text(
            'Suggestions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh, // Triggered on pull-to-refresh
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  final isSpecial =
                      index == 2; // Explicitly mark the 3rd suggestion

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: isSpecial ? Colors.lightBlue.shade50 : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSpecial) ...[
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Verified Organization',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Image.asset(
                            suggestion["image"]!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
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
                              color: Colors.grey,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              // Circular Avatar and Name aligned to the start
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        AssetImage(suggestion["image"]!),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    suggestion["profileName"]!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ChatDetailScreen(
                                                      name: suggestion[
                                                          "profileName"]!,
                                                      image: suggestion[
                                                          "image"]!)));
                                    },
                                    icon: const Icon(Icons.message_outlined),
                                    color: Colors.orange,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      addItemToCart(suggestion);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${suggestion["text"]} added to cart'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                        Icons.shopping_cart_outlined),
                                    color: Colors.green,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final shareText =
                                          '${suggestion["text"]}\n\n${suggestion["description"]}';
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Share'),
                                          content: Text(
                                              'You are sharing: \n$shareText'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.share_outlined),
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'Published: ${suggestion["published"]!}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 12.0, bottom: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                suggestion["location"]!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addItemToCart(Map<String, String> item) {
    print('Item added to cart: ${item["text"]}');
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      print("Refreshed");
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    const duration = Duration(seconds: 2);

    if (lastBackPressed == null ||
        now.difference(lastBackPressed!) > duration) {
      lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    lastBackPressed = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to AddScreen when the button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddScreen()),
            );
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
