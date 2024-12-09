import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/appointmentScreen.dart';
import 'package:flutter_application_1/user/screens/appointmentScreen.dart';
import 'package:flutter_application_1/user/screens/chatDetailScreen.dart';
import 'package:flutter_application_1/user/screens/productScreen.dart';
import 'package:flutter_application_1/user/screens/profile.dart'; // Import ProfileScreen from the correct file
import 'package:flutter_application_1/user/screens/messageScreen.dart'; // Import your existing MessageScreen

class VeterinaryScreen extends StatefulWidget {
  const VeterinaryScreen({super.key});

  @override
  State<VeterinaryScreen> createState() => _VeterinaryScreenState();
}

class _VeterinaryScreenState extends State<VeterinaryScreen> {
  // Index to keep track of the selected tab
  int _selectedIndex = 0;

  // Used to track the back button press time
  DateTime? _lastPressedAt;

  // Function to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update index to show the relevant screen
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
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex, // Show the selected tab based on index
          children: <Widget>[
            const Messagescreen(), // Make sure this screen is properly referenced
            const AppointmentScreen(), // Your existing AppointmentScreen
            const ProfileScreen(), // Your ProfileScreen
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex, // Set the current selected index
          onTap: _onItemTapped, // Handle item taps
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
              icon: Icon(Icons.event),
              label: 'Appointments',
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
