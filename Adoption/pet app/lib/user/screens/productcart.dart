import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detailScreen.dart';
import 'chatDetailScreen.dart';
import 'addScreen.dart';
import 'productsAddScreen.dart';
import 'package:intl/intl.dart';

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
  late String currentUserName;
  // late String currentUserProfileImage;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid ?? '';
    _fetchCurrentUserDetails();
  }

  Future<void> _fetchCurrentUserDetails() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    final userData = userDoc.data();
    if (userData != null) {
      setState(() {
        currentUserName = userData['name'] ?? 'Unknown user';
        // currentUserProfileImage = userData['profileImage'] ?? '';
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getCustomerCartItems() {
    return FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('customers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getAllItems() async* {
    final fetchCollectionItems = (String collection) async {
      return FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection(collection)
          .get()
          .then((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'collection': collection,
                  'data': data,
                };
              }).toList());
    };

    yield (await fetchCollectionItems('pets')) +
        (await fetchCollectionItems('products'));
  }

  Future<Map<String, dynamic>?> getDocumentData(
      String collection, String docId) async {
    if (docId.isEmpty) return null;
    final doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .get();
    return doc.exists ? doc.data() as Map<String, dynamic>? : null;
  }

  Future<void> finalizeStatus(
      String itemId, String customerId, String newStatus) async {
    if (userId.isEmpty || itemId.isEmpty || customerId.isEmpty) return;
    try {
      final customersCollection = FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('customers');

      final querySnapshot = await customersCollection
          .where('customerId', isEqualTo: customerId)
          .where('id', isEqualTo: itemId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        await docRef.update({'status': newStatus});
        final cartListDocRef = FirebaseFirestore.instance
            .collection('user')
            .doc(customerId)
            .collection('CartList')
            .doc(itemId);
        await cartListDocRef.update({'status': newStatus});
        await checkAndFinalizePaymentStatus(itemId);

        // Refresh state to update the UI
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item marked as $newStatus'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        print('No matching documents found');
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> checkAndFinalizePaymentStatus(String itemId) async {
    final paymentsCollection =
        FirebaseFirestore.instance.collection('Payments');

    final querySnapshot =
        await paymentsCollection.where('id', isEqualTo: itemId).get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data();

      if (data.containsKey('paymentMethod') && data['paymentMethod'] == 'COD') {
        await doc.reference.update({'status': 'completed'});
      }
    }
  }

  Future<void> deleteItem(String docId, String collection) async {
    try {
      // Delete the pet/product document from user's subcollection
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection(collection)
          .doc(docId)
          .delete();

      // Delete the same document from the global collection
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }

  Future<void> _deleteFromCloudinary(String publicId) async {
    // Implement Cloudinary deletion logic here
    // Example: await cloudinary.api.deleteResources([publicId]);
  }

  Future<void> handleDeleteItem(String docId, String collection,
      String? imagePublicId, String? vaccinationPublicId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        // Delete from Cloudinary
        if (imagePublicId != null) {
          await _deleteFromCloudinary(imagePublicId);
        }
        if (vaccinationPublicId != null) {
          await _deleteFromCloudinary(vaccinationPublicId);
        }

        // Delete the item document
        await deleteItem(docId, collection);
      } catch (e) {
        print('Error deleting item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
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
          future: getDocumentData('user', customerId),
          builder: (context, customerSnapshot) {
            if (customerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (customerSnapshot.hasError) {
              return const Center(child: Text('Error fetching customer data'));
            } else if (!customerSnapshot.hasData) {
              return const Center(child: Text('Customer data not available'));
            }

            final customerData = customerSnapshot.data!;

            return FutureBuilder<Map<String, dynamic>?>(
              future: getDocumentData(
                  itemType == 'pets' ? 'pets' : 'products', itemId),
              builder: (context, itemSnapshot) {
                if (itemSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (itemSnapshot.hasError) {
                  return const Center(child: Text('Error fetching item data'));
                } else if (!itemSnapshot.hasData) {
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

                return _buildCard(item, customerData, itemData, title,
                    description, imageUrl, customerId);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
    Map<String, dynamic> item,
    Map<String, dynamic> customerData,
    Map<String, dynamic> itemData,
    String title,
    String description,
    String imageUrl,
    String customerId,
  ) {
    bool isOngoing = item['status'] == 'ongoing';

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
                            'published': itemData['publishedTime'] != null
                                ? DateFormat('dd MMMM yyyy').format(
                                    (itemData['publishedTime'] as Timestamp)
                                        .toDate())
                                : 'Unknown',
                            // 'profileImage': currentUserProfileImage,
                            'profileName': currentUserName,
                            'userId': itemData['userId'] ?? '',
                          },
                          navigationSource: 'ProductCartScreen',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye),
                  color: Colors.orange,
                ),
                if (!isAllSelected)
                  IconButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('user')
                          .doc(customerId)
                          .collection('ChatAsBuyer')
                          .doc(userId)
                          .set({});
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            name: customerData['name'] ?? 'Unknown customer',
                            image: customerData['profileImage'] ?? '',
                            navigationSource: 'productsScreen',
                            userId: customerId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message),
                    color: Colors.blue,
                  ),
                if (isOngoing)
                  IconButton(
                    onPressed: () async {
                      await finalizeStatus(item['id'], customerId, 'completed');
                    },
                    icon: const Icon(Icons.check_circle),
                    color: Colors.green,
                  ),
                if (isAllSelected) ...[
                  IconButton(
                    onPressed: () async {
                      await handleDeleteItem(
                        item['id'],
                        item['collection'],
                        itemData['imagePublicId'],
                        itemData['vaccinationPublicId'],
                      );
                    },
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => item['type'] == 'pets'
                              ? AddScreen(
                                  fromScreen: 'ProductCartScreen',
                                  docId: item['id'],
                                )
                              : ProductsAddScreen(
                                  fromScreen: 'ProductCartScreen',
                                  docId: item['id'],
                                ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    color: Colors.blue,
                  ),
                ]
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
                            builder: (context) => DetailScreen(
                              data: {
                                'id': item['id'],
                                'collection': item['collection'],
                                'image': imageUrl,
                                'text': title ?? 'No title available',
                                'description':
                                    description ?? 'No description available',
                                'location':
                                    data['location'] ?? 'Unknown location',
                                'published': data['publishedTime'] != null
                                    ? DateFormat('dd MMMM yyyy').format(
                                        (data['publishedTime'] as Timestamp)
                                            .toDate())
                                    : 'Unknown',
                                // 'profileImage': currentUserProfileImage,
                                'profileName': currentUserName,
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
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => collection == 'pets'
                                ? AddScreen(
                                    fromScreen: 'ProductCartScreen',
                                    docId: item['id'],
                                  )
                                : ProductsAddScreen(
                                    fromScreen: 'ProductCartScreen',
                                    docId: item['id'],
                                  ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                    ),
                    IconButton(
                      onPressed: () async {
                        await handleDeleteItem(
                          item['id'],
                          collection,
                          data['imagePublicId'],
                          data['vaccinationPublicId'],
                        );
                      },
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
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
