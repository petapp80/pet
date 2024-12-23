import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/user/screens/chatDetailScreen.dart';
import 'package:flutter_application_1/user/screens/detailScreen.dart';

class CartScreen extends StatefulWidget {
  final String navigationSource;

  const CartScreen({super.key, required this.navigationSource});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedFilter = 'Wishlist'; // Default filter is Wishlist

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Additional initialization if needed
  }

  @override
  void dispose() {
    // Clean up any controllers or focus nodes
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    print("Refreshing data...");
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        print("Data refreshed");
      });
    }
  }

  void _updateItemStatus(
      String itemId, String newStatus, String createdById) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("User not logged in");
      return;
    }

    print("Updating status of item $itemId to $newStatus");

    await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('CartList')
        .doc(itemId)
        .update({'status': newStatus});

    final sellerCustomerRef = FirebaseFirestore.instance
        .collection('user')
        .doc(createdById)
        .collection('customers')
        .doc(itemId);

    final sellerCustomerSnapshot = await sellerCustomerRef.get();

    if (sellerCustomerSnapshot.exists) {
      final customerInfo =
          sellerCustomerSnapshot.data()?['customerInfo'] as List<dynamic>;
      final updatedCustomerInfo = customerInfo.map((info) {
        if (info['customerId'] == userId) {
          return {
            ...info,
            'status': newStatus,
          };
        }
        return info;
      }).toList();

      await sellerCustomerRef.update({
        'customerInfo': updatedCustomerInfo,
      });

      print("Updated customer's status in the seller's collection");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item marked as $newStatus'),
          duration: const Duration(seconds: 1),
        ),
      );
      setState(() {});
    }
  }

  void removeItemFromCart(
      BuildContext context, String itemId, String createdById) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("User not logged in");
      return;
    }

    print("Removing item $itemId from cart");

    await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('CartList')
        .doc(itemId)
        .delete();

    final sellerCustomerRef = FirebaseFirestore.instance
        .collection('user')
        .doc(createdById)
        .collection('customers')
        .doc(itemId);

    await sellerCustomerRef.delete();

    if (mounted) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from cart'),
            duration: Duration(seconds: 1),
          ),
        );
      });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('User not logged in'));
    }

    Stream<QuerySnapshot> cartStream = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('CartList')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onChanged: (String? newValue) {
              setState(() {
                _selectedFilter = newValue!;
              });
            },
            items: <String>['Wishlist', 'Ongoing', 'Completed']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: StreamBuilder<QuerySnapshot>(
                  stream: cartStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      print("Error: ${snapshot.error}");
                      return const Center(
                          child: Text('Error fetching cart data'));
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      print("No data found for filter: $_selectedFilter");
                      return const Center(child: Text('No data yet'));
                    }

                    final cartItems = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      switch (_selectedFilter) {
                        case 'Ongoing':
                          return data['status'] == 'ongoing';
                        case 'Completed':
                          return data['status'] == 'completed';
                        case 'Wishlist':
                        default:
                          return data['status'] == null ||
                              data['status'] == 'wishlist';
                      }
                    }).toList();

                    return ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item =
                            cartItems[index].data() as Map<String, dynamic>;
                        print("Cart Item: $item");

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                        data: item,
                                        navigationSource: widget
                                            .navigationSource, // Pass the navigation source
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  child: item['image'] != null &&
                                          item['image'].isNotEmpty
                                      ? Image.network(
                                          item['image'],
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image,
                                                      size: 50),
                                        )
                                      : const Icon(Icons.broken_image,
                                          size: 50),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  item['text'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Text(
                                  item['description'] ?? 'No description',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: item['profileImage'] !=
                                                  null &&
                                              item['profileImage'].isNotEmpty
                                          ? NetworkImage(item['profileImage'])
                                          : const AssetImage(
                                                  'asset/image/dog1.png')
                                              as ImageProvider,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['profileName'] ?? 'Unknown user',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChatDetailScreen(
                                              name: item['profileName'],
                                              image: item['profileImage'],
                                              navigationSource: widget
                                                  .navigationSource, // Pass the navigation source
                                              userId:
                                                  item['userId'], // Pass userId
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.message_outlined),
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    if (_selectedFilter == 'Ongoing')
                                      IconButton(
                                        onPressed: () {
                                          _updateItemStatus(item['id'],
                                              'completed', item['userId']);
                                        },
                                        icon: const Icon(Icons.check_circle),
                                      ),
                                    IconButton(
                                      onPressed: () {
                                        removeItemFromCart(context, item['id'],
                                            item['userId']);
                                      },
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8.0),
                                child: Text(
                                  'Published: ${item['published']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, bottom: 12.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['location'] ?? 'Unknown location',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
