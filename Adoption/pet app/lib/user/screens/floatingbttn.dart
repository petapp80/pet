import 'package:flutter/material.dart';
import 'package:PetApp/user/screens/addScreen.dart';
import 'package:PetApp/user/screens/productsAddScreen.dart';
import 'veterinaryAdd.dart'; // Import the VeterinaryAddScreen

class AddItemScreen extends StatefulWidget {
  final String navigationSource; // Add this line

  const AddItemScreen(
      {super.key, required this.navigationSource}); // Add this line

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the argument you want to pass
    final String fromScreen = 'AddItemScreen';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pets'),
            Tab(text: 'Products'),
            Tab(text: 'Veterinary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AddScreen(
              fromScreen: fromScreen), // Screen for adding pets with argument
          ProductsAddScreen(
              fromScreen:
                  fromScreen), // Screen for adding products with argument
          VeterinaryAddScreen(
              fromScreen:
                  fromScreen), // Screen for adding veterinary profiles with argument
        ],
      ),
    );
  }
}
