import 'package:flutter/material.dart';
// import 'package:flutter_application_1/user/screens/ProductsAddScreen.dart';
import 'package:flutter_application_1/user/screens/productCart.dart';
import 'package:flutter_application_1/user/screens/productSAddScreen.dart';
import 'package:flutter_application_1/user/screens/profile.dart'; // Adjust the import as needed
import 'package:flutter_application_1/user/screens/messageScreen.dart'; // Import the MessageScreen

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // Index to keep track of the selected tab, default to "Add" screen (index 1)
  int _selectedIndex = 1;

  // Used to track the back button press time
  DateTime? _lastPressedAt;

  // Function to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to handle back button press (exit confirmation)
  Future<bool> _onWillPop() async {
    DateTime currentTime = DateTime.now();
    bool backButtonExit = _lastPressedAt == null ||
        currentTime.difference(_lastPressedAt!) > const Duration(seconds: 2);

    if (backButtonExit) {
      // If the back button is pressed once, show the Snackbar message
      _lastPressedAt = currentTime;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false; // Prevent app exit
    } else {
      return true; // Exit the app
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Prevents back button and asks for confirmation
      child: Scaffold(
        // Removed appBar completely
        body: IndexedStack(
          index: _selectedIndex, // Sets the currently selected index
          children: <Widget>[
            const Messagescreen(), // Messages Screen
            const ProductsAddScreen(), // Products Add Screen
            const ProductCartScreen(), // Cart screen (now at third position)
            const ProfileScreen(), // Profile screen (now at fourth position)
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex, // Sets the current selected index
          onTap: _onItemTapped, // Handles icon taps
          backgroundColor:
              Colors.teal, // Bottom navigation bar background color
          selectedItemColor: Colors.blue, // Change selected item color to blue
          unselectedItemColor: Colors.grey, // Color for unselected items
          items: const <BottomNavigationBarItem>[
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

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Welcome to the Messages Screen!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
