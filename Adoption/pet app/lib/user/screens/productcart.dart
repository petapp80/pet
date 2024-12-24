import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detailScreen.dart';
import 'productsAddScreen.dart';
import 'addScreen.dart';
import 'package:rxdart/rxdart.dart';

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

  Stream<List<Map<String, dynamic>>> getAllItems() {
    return CombineLatestStream.list([
      FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('products')
          .snapshots(),
      FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('pets')
          .snapshots(),
    ]).map((snapshots) {
      final productsSnapshot = snapshots[0] as QuerySnapshot;
      final petsSnapshot = snapshots[1] as QuerySnapshot;

      print('Products Snapshot: ${productsSnapshot.docs.length} documents');
      print('Pets Snapshot: ${petsSnapshot.docs.length} documents');

      final products = productsSnapshot.docs.map((doc) {
        print('Product: ${doc.data()}');
        return {
          'id': doc.id,
          'data': doc.data() as Map<String, dynamic>,
          'collection': 'products',
        };
      }).toList();

      final pets = petsSnapshot.docs.map((doc) {
        print('Pet: ${doc.data()}');
        return {
          'id': doc.id,
          'data': doc.data() as Map<String, dynamic>,
          'collection': 'pets',
        };
      }).toList();

      print('Combined List: ${products.length + pets.length} items');

      return [...products, ...pets];
    });
  }

  List<Map<String, dynamic>> filterItems(
      List<Map<String, dynamic>> items, String status) {
    return items.where((item) {
      final customerInfo = item['data']['customerInfo'];
      if (customerInfo == null || customerInfo is! List<dynamic>) {
        return false;
      }
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
    final collection = type == 'pet' ? 'pets' : 'products';
    final doc =
        await FirebaseFirestore.instance.collection(collection).doc(id).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
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
                      final ongoingItems = filterItems(items, 'ongoing');
                      final completedItems = filterItems(items, 'completed');

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
        final customerInfo = item['data']['customerInfo'];
        if (customerInfo == null || customerInfo is! List<dynamic>) {
          return Container(); // Skip if customerInfo is null or not a list
        }
        final data =
            customerInfo.isNotEmpty ? customerInfo.first : <String, dynamic>{};
        final customerId = data['customerId'] ?? '';
        final itemId = data['id'] ?? '';
        final itemType = data['type'] ?? '';

        if (customerId.isEmpty || itemId.isEmpty || itemType.isEmpty) {
          return Container(); // Skip if any required fields are empty
        }

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
                    ? _buildOngoingCard(
                        itemData, customerData, title, description, imageUrl)
                    : _buildCompletedCard(
                        itemData,
                        customerData,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          data: {
                            'id': item['id'] ?? '',
                            'collection': item['collection'] ?? '',
                            'image': item['imageUrl'] ?? '',
                            'text': title,
                            'description': description,
                            'location': item['location'] ?? 'Unknown location',
                            'published': item['published'] ?? 'Unknown time',
                            'profileImage': customerData['profileImage'] ?? '',
                            'profileName':
                                customerData['name'] ?? 'Unknown user',
                            'userId': item['userId'] ?? '',
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

  Widget _buildCompletedCard(
    Map<String, dynamic> item,
    Map<String, dynamic> customerData,
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
