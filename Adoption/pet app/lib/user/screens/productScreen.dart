import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator
import 'package:flutter_application_1/user/screens/addScreen.dart';
import 'package:flutter_application_1/user/screens/productCart.dart';
import 'package:flutter_application_1/user/screens/productsAddScreen.dart'; // Corrected import statement
import 'package:flutter_application_1/user/screens/profile.dart';
import 'package:flutter_application_1/user/screens/messageScreen.dart';

class ProductsScreen extends StatefulWidget {
  final String? navigationSource; // Make this parameter optional

  const ProductsScreen(
      {super.key, this.navigationSource}); // Update the constructor

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Default to "Add" screen in Bottom Navigation
  int _tabIndex = 0; // Default to "Products" tab when "Add" is selected
  late TabController _tabController; // TabController to manage the TabBar

  DateTime? _lastPressedAt;

  // Function to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex != 1) {
        _tabIndex = 0; // Reset tab index if not in "Add" screen
        _tabController.index =
            _tabIndex; // Reset TabController to the first tab
      }
    });
  }

  // Function to handle back button press (exit confirmation)
  Future<bool> _onWillPop() async {
    DateTime currentTime = DateTime.now();
    bool backButtonExit = _lastPressedAt == null ||
        currentTime.difference(_lastPressedAt!) > const Duration(seconds: 2);

    if (backButtonExit) {
      _lastPressedAt = currentTime;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    } else {
      // Instead of returning true directly, we exit the app using SystemNavigator
      SystemNavigator.pop();
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this); // Initialize TabController with 2 tabs
  }

  @override
  void dispose() {
    _tabController
        .dispose(); // Dispose the TabController when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the argument to pass
    final String fromScreen = widget.navigationSource ??
        'ProductsScreen'; // Use the passed value or default

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product & Pets'),
          bottom:
              _selectedIndex == 1 // Only show the TabBar if "Add" is selected
                  ? TabBar(
                      controller:
                          _tabController, // Use the TabController to manage tabs
                      onTap: (index) {
                        setState(() {
                          _tabIndex = index; // Update tab index when tapping
                        });
                      },
                      tabs: const [
                        Tab(text: 'Products'),
                        Tab(text: 'Pets'),
                      ],
                    )
                  : null,
        ),
        body: _selectedIndex == 1
            ? IndexedStack(
                index: _tabIndex, // Switch between Product and Pets screens
                children: [
                  ProductsAddScreen(
                      fromScreen:
                          fromScreen), // Products Add Screen with argument
                  AddScreen(
                      fromScreen: fromScreen), // Pets Add Screen with argument
                ],
              )
            : _selectedIndex == 0
                ? Messagescreen(
                    navigationSource:
                        fromScreen) // Messages Screen with argument
                : _selectedIndex == 2
                    ? const ProductCartScreen() // Cart Screen
                    : const ProfileScreen(), // Profile Screen
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.teal,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
