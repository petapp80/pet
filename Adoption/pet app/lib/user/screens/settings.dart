import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'login screen.dart';
import 'themeProvider.dart';
import 'package:lottie/lottie.dart'; // Make sure to add the Lottie package in your pubspec.yaml

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _removeAccount() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("This will permanently remove your account."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes, Remove"),
            ),
          ],
        );
      },
    );

    if (confirmation ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Fetch user data to get the Cloudinary image public IDs
          final userData = await FirebaseFirestore.instance
              .collection('user')
              .doc(user.uid)
              .get();

          final profileImagePublicId =
              userData.data()?.containsKey('profileImagePublicId') ?? false
                  ? userData['profileImagePublicId']
                  : null;

          // Fetch and delete user's related pets, products, and veterinary records
          final collections = ['pets', 'products', 'veterinary'];
          for (var collection in collections) {
            final querySnapshot = await FirebaseFirestore.instance
                .collection(collection)
                .where('userId', isEqualTo: user.uid)
                .get();
            for (var doc in querySnapshot.docs) {
              final data = doc.data();
              final imagePublicId = data.containsKey('imagePublicId')
                  ? data['imagePublicId']
                  : null;
              final vaccinationPublicId =
                  data.containsKey('vaccinationPublicId')
                      ? data['vaccinationPublicId']
                      : null;
              final licenseCertificatePublicId =
                  data.containsKey('licenseCertificatePublicId')
                      ? data['licenseCertificatePublicId']
                      : null;

              if (imagePublicId != null) {
                await _deleteImageFromCloudinary(imagePublicId);
              }
              if (vaccinationPublicId != null) {
                await _deleteImageFromCloudinary(vaccinationPublicId);
              }
              if (licenseCertificatePublicId != null) {
                await _deleteImageFromCloudinary(licenseCertificatePublicId);
              }
              await doc.reference.delete();
            }
          }

          // Delete the profile image from Cloudinary if it exists
          if (profileImagePublicId != null) {
            await _deleteImageFromCloudinary(profileImagePublicId);
          }

          // Delete the user's document and subcollections in Firestore
          await _deleteUserDocumentWithSubcollections(user.uid);

          // Delete the user account from Firebase Auth
          await user.delete();

          // Short delay before navigating to the login page
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            // Close the loading dialog
            Navigator.of(context).pop();

            // Redirect to login page
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          // Close the loading dialog
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing account: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _deleteUserDocumentWithSubcollections(String uid) async {
    final userDoc = FirebaseFirestore.instance.collection('user').doc(uid);

    // Fetch and delete each subcollection manually
    final subcollections = [
      'subcollection1',
      'subcollection2'
    ]; // Add all subcollection names here
    for (var subcollection in subcollections) {
      final subDocs = await userDoc.collection(subcollection).get();
      for (var subDoc in subDocs.docs) {
        await subDoc.reference.delete();
      }
    }

    // Delete user document
    await userDoc.delete();
  }

  Future<void> _deleteImageFromCloudinary(String publicId) async {
    const cloudName = 'db3cpgdwm';
    const apiKey = '545187993373729';
    const apiSecret = 'gdgWv-rubTrQTMn6KG0T7-Q5Cfw';

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final signature = sha1
        .convert(
            utf8.encode('public_id=$publicId&timestamp=$timestamp$apiSecret'))
        .toString();

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
    final response = await http.post(uri, body: {
      'public_id': publicId,
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': signature,
    });

    if (response.statusCode == 200) {
      print('Image deleted successfully from Cloudinary');
    } else {
      print('Error deleting image from Cloudinary: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Dark Theme'),
                value: context.watch<ThemeProvider>().isDarkTheme,
                onChanged: (bool value) {
                  context.read<ThemeProvider>().toggleTheme();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Remove Account',
                    style: TextStyle(color: Colors.red)),
                onTap: _removeAccount,
              ),
            ],
          ),
          if (_isLoading)
            Center(
              child: Lottie.asset(
                'asset/image/loading.json', // Correct asset path
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
