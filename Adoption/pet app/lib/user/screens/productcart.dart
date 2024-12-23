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
          'id': doc.id,
          'data': data,
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getAllItems() async* {
    final productsStream = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('products')
        .snapshots();

    final petsStream = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('pets')
        .snapshots();

    await for (final productsSnapshot in productsStream) {
      final products = productsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'data': doc.data(),
          'collection': 'products',
        };
      }).toList();

      await for (final petsSnapshot in petsStream) {
        final pets = petsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'data': doc.data(),
            'collection': 'pets',
          };
        }).toList();

        yield [...products, ...pets];
      }
    }
  }

  List<Map<String, dynamic>> filterItems(
      List<Map<String, dynamic>> items, String status) {
    return items.where((item) {
      final customerInfo = item['data']['customerInfo'] as List<dynamic>;
      final matchingItems =
          customerInfo.where((info) => info['status'] == status).toList();
      return matchingItems.isNotEmpty;
    }).map((item) {
      final customerInfo = (item['data']['customerInfo'] as List<dynamic>)
          .where((info) => info['status'] == status)
          .map((info) => info as Map<String, dynamic>)
          .toList();
      return {
        'id': item['id'],
        'data': {...item['data'], 'customerInfo': customerInfo},
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getCustomerDetails(String customerId) async {
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
    final collection = type == 'pet' ? 'pets' : 'products';
    final doc =
        await FirebaseFirestore.instance.collection(collection).doc(id).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> _markItemAsCompleted(String itemId, String customerId) async {
    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('customers')
          .doc(itemId);

      final customerSnapshot = await userDocRef.get();

      if (customerSnapshot.exists) {
        final customerInfo =
            customerSnapshot.data()?['customerInfo'] as List<dynamic>;
        final updatedCustomerInfo = customerInfo.map((info) {
          if (info['id'] == itemId) {
            _updateCartListStatus(
                customerId, itemId); // Update the CartList status
            return {...info, 'status': 'completed'};
          }
          return info;
        }).toList();

        await userDocRef.update({'customerInfo': updatedCustomerInfo});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item marked as completed')),
        );
      }
    } catch (e) {
      print('Error marking item as completed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark item as completed: $e')),
      );
    }
  }

  Future<void> _updateCartListStatus(String customerId, String itemId) async {
    try {
      final userCartListDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(customerId)
          .collection('CartList')
          .doc(itemId);

      await userCartListDocRef.update({'status': 'completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CartList status updated to completed')),
      );
    } catch (e) {
      print('Error updating CartList status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update CartList status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Cart'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Row with Ongoing, Completed, and All Text inside rounded box
              Row(
                children: [
                  _buildTabText('Ongoing', isOngoingSelected && !isAllSelected),
                  const SizedBox(width: 16),
                  _buildTabText(
                      'Completed', !isOngoingSelected && !isAllSelected),
                  const SizedBox(width: 16),
                  _buildTabText('All', isAllSelected),
                ],
              ),
              const SizedBox(height: 16),

              if (isAllSelected)
                StreamBuilder<List<Map<String, dynamic>>>(
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
              else
                StreamBuilder<List<Map<String, dynamic>>>(
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
                    final ongoingItems = filterItems(items, 'ongoing');
                    final completedItems = filterItems(items, 'completed');

                    return isOngoingSelected
                        ? _buildItemList(ongoingItems, 'No ongoing data yet')
                        : _buildItemList(
                            completedItems, 'No completed data yet');
                  },
                ),
            ],
          ),
        ),
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
        final customerInfo = item['data']['customerInfo'] as List<dynamic>;
        final data =
            customerInfo.isNotEmpty ? customerInfo.first : <String, dynamic>{};
        final customerId = data['customerId'] as String;
        final itemId = data['id'] as String;
        final itemType = data['type'] as String;

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
                final title = itemType == 'pet'
                    ? itemData['petType']
                    : itemData['productName'];
                final description = itemType == 'pet'
                    ? itemData['about']
                    : itemData['description'];
                final imageUrl = itemType == 'pet'
                    ? itemData['imageUrl']
                    : itemData['imageUrl'];

                return isOngoingSelected
                    ? _buildOngoingCard(itemData, customerData, title,
                        description, imageUrl, itemId, customerId)
                    : _buildCompletedCard(
                        itemData, customerData, title, description, imageUrl);
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
      String title,
      String description,
      String imageUrl,
      String itemId,
      String customerId) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
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
                            'collection': item['collection'],
                            'image': item['imageUrl'] ?? '',
                            'text': title,
                            'description': description,
                            'location': item['location'] ?? 'Unknown location',
                            'published': item['published'] ?? 'Unknown time',
                            'profileImage': customerData['profileImage'] ?? '',
                            'profileName':
                                customerData['name'] ?? 'Unknown user',
                            'userId': item['userId'],
                            'age': item['age'],
                            'breed': item['breed'],
                            'colour': item['colour'],
                            'price': item['price'],
                            'sex': item['sex'],
                            'weight': item['weight'],
                            'quantity': item['quantity'],
                            'experience': item['experience'],
                            'availability': item['availability'],
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
                    await _markItemAsCompleted(itemId, customerId);
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.green),
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
      String title,
      String description,
      String imageUrl) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
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
                            'collection': item['collection'],
                            'image': item['imageUrl'] ?? '',
                            'text': title,
                            'description': description,
                            'location': item['location'] ?? 'Unknown location',
                            'published': item['published'] ?? 'Unknown time',
                            'profileImage': customerData['profileImage'] ?? '',
                            'profileName':
                                customerData['name'] ?? 'Unknown user',
                            'userId': item['userId'],
                            'age': item['age'],
                            'breed': item['breed'],
                            'colour': item['colour'],
                            'price': item['price'],
                            'sex': item['sex'],
                            'weight': item['weight'],
                            'quantity': item['quantity'],
                            'experience': item['experience'],
                            'availability': item['availability'],
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

        final title =
            collection == 'pets' ? data['petType'] : data['productName'];
        final description =
            collection == 'pets' ? data['about'] : data['description'];
        final imageUrl = data['imageUrl'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                                'image': item['imageUrl'] ?? '',
                                'text': title,
                                'description': description,
                                'location':
                                    item['location'] ?? 'Unknown location',
                                'published':
                                    item['published'] ?? 'Unknown time',
                                'profileImage': data['profileImage'] ?? '',
                                'profileName':
                                    data['profileName'] ?? 'Unknown user',
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
