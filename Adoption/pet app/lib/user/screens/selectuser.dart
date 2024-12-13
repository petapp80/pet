import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:flutter_application_1/user/screens/productScreen.dart';
import 'package:flutter_application_1/user/screens/veterinary.dart';
import 'home.dart';

class SelectUser extends StatefulWidget {
  const SelectUser({super.key});

  @override
  State<SelectUser> createState() => _SelectUserState();
}

class _SelectUserState extends State<SelectUser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _navigateToPurpose(String purpose) async {
    try {
      // Get the current user's ID
      final User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No authenticated user found.')),
        );
        return;
      }

      String userId = user.uid;

      // Check if user document exists
      DocumentReference userDoc = _firestore.collection('user').doc(userId);
      DocumentSnapshot snapshot = await userDoc.get();

      if (snapshot.exists) {
        // Update the document with the selected position
        await userDoc.set(
          {'position': purpose},
          SetOptions(merge: true), // Merge to add or update the field
        );
      } else {
        // Create a new document with the selected position if it doesn't exist
        await userDoc.set({
          'position': purpose,
          'createdAt': FieldValue.serverTimestamp(), // Optional metadata
        });
      }

      // Navigate based on the purpose
      if (purpose == 'Buyer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else if (purpose == 'Seller') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProductsScreen()),
        );
      } else if (purpose == 'Veterinary') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VeterinaryScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: $purpose')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving position: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Purpose'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose your purpose for using our app:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _purposeOption(
              icon: Icons.shopping_cart,
              title: 'Buyer',
              description:
                  'Explore and purchase items or services available on our platform.',
              onTap: () => _navigateToPurpose('Buyer'),
            ),
            const SizedBox(height: 20),
            _purposeOption(
              icon: Icons.production_quantity_limits,
              title: 'Products',
              description: 'Manage or browse products listed on the platform.',
              onTap: () => _navigateToPurpose('Seller'),
            ),
            const SizedBox(height: 20),
            _purposeOption(
              icon: Icons.pets,
              title: 'Veterinary',
              description:
                  'Connect with veterinary services or manage pet care needs.',
              onTap: () => _navigateToPurpose('Veterinary'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purposeOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100,
              ),
              child: Icon(
                icon,
                size: 30,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
