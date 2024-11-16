import 'package:flutter/material.dart';
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

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;
  DateTime? lastBackPressed;

  // Sample data for suggestions
  final List<Map<String, String>> _suggestions = [
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 1",
      "description": "This is a description for Suggestion 1."
    },
    {
      "image": "asset/image/dog2.png",
      "text": "Suggestion 2",
      "description": "This is a description for Suggestion 2."
    },
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 3",
      "description": "This is a description for Suggestion 3."
    },
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 4",
      "description": "This is a description for Suggestion 4."
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

  // Home screen with cart functionality
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  // Call the placeholder method for adding item to cart
                                  addItemToCart(suggestion);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${suggestion["text"]} added to cart'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.shopping_cart_outlined),
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
                                      content:
                                          Text('You are sharing: \n$shareText'),
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

  // Placeholder method for adding item to cart (to be updated later)
  void addItemToCart(Map<String, String> item) {
    // Placeholder implementation: this is where you can later integrate backend logic.
    print('Item added to cart: ${item["text"]}');
  }

  // Refresh function: to be triggered on pull-to-refresh
  Future<void> _handleRefresh() async {
    // Simulate network delay (you can replace this with real data fetching)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      // For now, we will just print a message
      print("Refreshed");
      // You can update the _suggestions list here or fetch new data
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
          duration: Duration(seconds: 2), // Visible for 2 seconds
        ),
      );
      return false; // Prevent exiting the app
    }

    // Reset `lastBackPressed` to null to enforce the double-back press rule every time
    lastBackPressed = null;
    return true; // Allow exiting the app
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Intercept the back button press
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
              label: 'My Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to AddScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddScreen()),
            );
          },
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}
