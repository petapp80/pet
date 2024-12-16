import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/appointmentScreen.dart';
import 'package:flutter_application_1/user/screens/profile.dart';
import 'package:flutter_application_1/user/screens/messageScreen.dart';

import 'veterinaryAdd.dart';

class VeterinaryScreen extends StatefulWidget {
  const VeterinaryScreen({super.key});

  @override
  State<VeterinaryScreen> createState() => _VeterinaryScreenState();
}

class _VeterinaryScreenState extends State<VeterinaryScreen> {
  int _selectedIndex = 0; // Index to keep track of the selected tab
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    final String fromScreen = 'VeterinaryScreen';
    _screens.addAll([
      const Messagescreen(),
      const AppointmentScreen(),
      VeterinaryAddScreen(
          fromScreen: fromScreen), // Pass the fromScreen argument
      const ProfileScreen(),
    ]);
  }

  // Function to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the index to change the screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(
          index: _selectedIndex,
          key: ValueKey<int>(_selectedIndex), // Important for AnimatedSwitcher
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Set the current selected index
        onTap: _onItemTapped, // Handle item taps
        backgroundColor: Colors.teal, // Bottom navigation bar background color
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
            icon: Icon(Icons.add_circle, size: 40), // "+" icon
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
