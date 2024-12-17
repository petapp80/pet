import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/chatDetailScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailScreen({required this.data, Key? key}) : super(key: key);

  void addItemToCart(BuildContext context, Map<String, dynamic> item) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartItem = {
      'id': item['id'],
      'collection': item['collection'],
      'image': item['image'],
      'text': item['text'],
      'description': item['description'],
      'location': item['location'],
      'published': item['published'],
      'profileName': item['profileName'],
      'addedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('CartList')
        .doc(item['id'])
        .set(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['text']} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data['text'] ?? 'Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['image'] != null && data['image'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    data['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                data['text'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Published: ${data['published']}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                data['description'] ?? 'No description',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    data['location'] ?? 'Unknown location',
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: data['profileImage'] != null &&
                            data['profileImage'].isNotEmpty
                        ? NetworkImage(data['profileImage'])
                        : const AssetImage('asset/image/dog1.png')
                            as ImageProvider,
                    radius: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data['profileName'] ?? 'Unknown user',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            name: data['profileName'],
                            image: data['profileImage'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message_outlined),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  IconButton(
                    onPressed: () {
                      addItemToCart(context, data);
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
