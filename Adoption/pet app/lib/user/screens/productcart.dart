import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detailScreen.dart';
import 'productsAddScreen.dart';
import 'addScreen.dart';

class ProductCartScreen extends StatefulWidget {
  const ProductCartScreen({super.key});

  @override
  State<ProductCartScreen> createState() => _ProductCartScreenState();
}

class _ProductCartScreenState extends State<ProductCartScreen> {
  bool isOngoingSelected = true;
  bool isAllSelected = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;

  @override
  void initState() {
    super.initState();
    final User? user = _auth.currentUser;
    userId = user?.uid ?? '';
  }

  Stream<List<Map<String, dynamic>>> getCustomerCartItems() {
    return FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('customers')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': data['id'],
          'customerId': data['customerId'],
          'status': data['status'],
          'type': data['type'],
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getAllItems() async* {
    // Fetch pets
    final petsSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('pets')
        .get();

    final pets = petsSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'collection': 'pets',
        'data': data,
      };
    }).toList();

    // Fetch products
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('products')
        .get();

    final products = productsSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'collection': 'products',
        'data': data,
      };
    }).toList();

    // Combine results
    yield pets + products;
  }

  Future<Map<String, dynamic>?> getCustomerDetails(String customerId) async {
    if (customerId.isEmpty) return null;
    final doc = await FirebaseFirestore.instance
        .collection('user')
        .doc(customerId)
        .get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getItemDetails(String id, String type) async {
    if (id.isEmpty || type.isEmpty) return null;
    final collection = type == 'pets' ? 'pets' : 'products';
    final doc =
        await FirebaseFirestore.instance.collection(collection).doc(id).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> finalizeStatus(
      String itemId, String customerId, String newStatus) async {
    if (userId.isEmpty || itemId.isEmpty || customerId.isEmpty) return;
    try {
      // Access all documents in the `customers` collection
      final customersCollection = FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('customers');

      // Retrieve all documents and match `customerId` and `id` fields
      final querySnapshot = await customersCollection
          .where('customerId', isEqualTo: customerId)
          .where('id', isEqualTo: itemId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document reference
        final docRef = querySnapshot.docs.first.reference;

        // Update the status in the `customers` collection
        await docRef.update({'status': newStatus});
        print('Updated status in customers collection for item: $itemId');

        // Access the `CartList` subcollection of the customer
        final cartListDocRef = FirebaseFirestore.instance
            .collection('user')
            .doc(customerId)
            .collection('CartList')
            .doc(itemId);

        // Update the status in the `CartList` subcollection
        await cartListDocRef.update({'status': newStatus});
        print('Updated status in CartList subcollection for item: $itemId');

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item marked as $newStatus'),
            duration: const Duration(seconds: 1),
          ),
        );

        // Refresh the UI
        setState(() {});
      } else {
        print(
            'No matching document found in customers collection for item: $itemId');
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Cart'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Row with Ongoing, Completed, and All Text inside rounded box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildTabText('Ongoing', isOngoingSelected && !isAllSelected),
                const SizedBox(width: 16),
                _buildTabText(
                    'Completed', !isOngoingSelected && !isAllSelected),
                const SizedBox(width: 16),
                _buildTabText('All', isAllSelected),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: isAllSelected
                ? StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getAllItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Error fetching data'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No data yet'));
                      }

                      final items = snapshot.data!;
                      return _buildAllItemList(items);
                    },
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getCustomerCartItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Error fetching data'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No data yet'));
                      }

                      final items = snapshot.data!;
                      final ongoingItems = items
                          .where((item) => item['status'] == 'ongoing')
                          .toList();
                      final completedItems = items
                          .where((item) => item['status'] == 'completed')
                          .toList();

                      return isOngoingSelected
                          ? _buildItemList(ongoingItems, 'No ongoing data yet')
                          : _buildItemList(
                              completedItems, 'No completed data yet');
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabText(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isOngoingSelected = text == 'Ongoing';
          isAllSelected = text == 'All';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.teal : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildItemList(List<Map<String, dynamic>> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final customerId = item['customerId'];
        final itemId = item['id'];
        final itemType = item['type'];

        return FutureBuilder<Map<String, dynamic>?>(
          future: getCustomerDetails(customerId),
          builder: (context, customerSnapshot) {
            if (customerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (customerSnapshot.hasError) {
              return const Center(child: Text('Error fetching customer data'));
            } else if (!customerSnapshot.hasData ||
                customerSnapshot.data == null) {
              return const Center(child: Text('Customer data not available'));
            }

                       final customerData = customerSnapshot.data!;

            return FutureBuilder<Map<String, dynamic>?>(
              future: getItemDetails(itemId, itemType),
              builder: (context, itemSnapshot) {
                if (itemSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (itemSnapshot.hasError) {
                  return const Center(child: Text('Error fetching item data'));
                } else if (!itemSnapshot.hasData || itemSnapshot.data == null) {
                  return const Center(child: Text('Item data not available'));
                }

                final itemData = itemSnapshot.data!;
                final title = itemType == 'pets'
                    ? itemData['petType']
                    : itemData['productName'];
                final description = itemType == 'pets'
                    ? itemData['about']
                    : itemData['description'];
                final imageUrl = itemData['imageUrl'] ?? '';

                return isOngoingSelected
                    ? _buildOngoingCard(
                        item,
                        customerData,
                        itemData, // Pass itemData to _buildOngoingCard
                        title,
                        description,
                        imageUrl,
                        customerId,
                      )
                    : _buildCompletedCard(
                        item,
                        customerData,
                        itemData, // Pass itemData to _buildCompletedCard
                        title,
                        description,
                        imageUrl,
                      );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOngoingCard(
    Map<String, dynamic> item,
    Map<String, dynamic> customerData,
    Map<String, dynamic> itemData, // Add itemData parameter
    String title,
    String description,
    String imageUrl,
    String customerId,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50),
              ),
            )
          else
            const Icon(Icons.broken_image, size: 50),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          data: {
                            'id': item['id'],
                            'collection': item['type'],
                            'image': imageUrl,
                            'text': title,
                            'description': description,
                            'location':
                                itemData['location'] ?? 'Unknown location',
                            'published':
                                itemData['published'] ?? 'Unknown time',
                            'profileImage': customerData['profileImage'] ?? '',
                            'profileName':
                                customerData['name'] ?? 'Unknown user',
                            'userId': itemData['userId'] ?? '',
                          },
                          navigationSource: 'ProductCartScreen',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_outlined),
                  color: Colors.orange,
                ),
                IconButton(
                  onPressed: () async {
                    await finalizeStatus(item['id'], customerId, 'completed');
                  },
                  icon: const Icon(Icons.check_circle),
                  color: Colors.green,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                customerData['profileImage'] != null
                    ? CircleAvatar(
                        backgroundImage:
                            NetworkImage(customerData['profileImage']),
                      )
                    : const Icon(Icons.person, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  customerData['name'] ?? 'Unknown customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(
    Map<String, dynamic> item,
    Map<String, dynamic> customerData,
    Map<String, dynamic> itemData, // Add itemData parameter
    String title,
    String description,
    String imageUrl,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50),
              ),
            )
          else
            const Icon(Icons.broken_image, size: 50),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          data: {
                            'id': item['id'],
                            'collection': item['type'],
                            'image': imageUrl,
                            'text': title,
                            'description': description,
                            'location':
                                itemData['location'] ?? 'Unknown location',
                            'published':
                                itemData['published'] ?? 'Unknown time',
                            'profileImage': customerData['profileImage'] ?? '',
                            'profileName':
                                customerData['name'] ?? 'Unknown user',
                          },
                          navigationSource: 'ProductCartScreen',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_outlined),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                customerData['profileImage'] != null
                    ? CircleAvatar(
                        backgroundImage:
                            NetworkImage(customerData['profileImage']),
                      )
                    : const Icon(Icons.person, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  customerData['name'] ?? 'Unknown customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllItemList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No data yet'));
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final collection = item['collection'];
        final data = item['data'];

        // Access relevant fields based on the collection type
        final title =
            collection == 'pets' ? data['petType'] : data['productName'];
        final description =
            collection == 'pets' ? data['about'] : data['description'];
        final imageUrl = data['imageUrl'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
                )
              else
                const Icon(Icons.broken_image, size: 50),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  title ?? 'No title available',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  description ?? 'No description available',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => collection == 'pets'
                                ? AddScreen(
                                    fromScreen: 'ProductCartScreen',
                                    docId: item['id'], // Pass document ID
                                  )
                                : ProductsAddScreen(
                                    fromScreen: 'ProductCartScreen',
                                    docId: item['id'], // Pass document ID
                                  ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              data: {
                                'id': item['id'],
                                'collection': item['collection'],
                                'image': imageUrl,
                                'text': title ?? 'No title available',
                                'description': description ?? 'No description available',
                                'location': data['location'] ?? 'Unknown location',
                                'published': data['published'] ?? 'Unknown time',
                                'profileImage': data['profileImage'] ?? '',
                                'profileName': data['profileName'] ?? 'Unknown user',
                                'userId': data['userId'],
                                'age': data['age'],
                                'breed': data['breed'],
                                'colour': data['colour'],
                                'price': data['price'],
                                'sex': data['sex'],
                                'weight': data['weight'],
                                'quantity': data['quantity'],
                                'experience': data['experience'],
                                'availability': data['availability'],
                              },
                              navigationSource: 'ProductCartScreen',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.remove_red_eye),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
