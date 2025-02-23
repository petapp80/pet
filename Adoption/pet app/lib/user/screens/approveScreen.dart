import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detailScreen.dart';

class ApproveScreen extends StatefulWidget {
  const ApproveScreen({super.key});

  @override
  State<ApproveScreen> createState() => _ApproveScreenState();
}

class _ApproveScreenState extends State<ApproveScreen> {
  String selectedCategory = 'Users'; // Default category
  String searchQuery = ''; // Current search query
  List<Map<String, dynamic>> allDocuments = [];
  List<Map<String, dynamic>> displayedResults = [];
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await fetchData('Users');
    } catch (e) {
      print('Error fetching initial data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchData(String category) async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data = [];
      final firestore = FirebaseFirestore.instance;

      switch (category) {
        case 'Users':
          data = await fetchUsers(firestore);
          break;
        case 'Pets':
          data = await fetchPets(firestore);
          break;
        case 'Products':
          data = await fetchProducts(firestore);
          break;
        case 'Veterinary':
          data = await fetchVeterinary(firestore);
          break;
        default:
          data = [];
          break;
      }

      setState(() {
        allDocuments = data.where((doc) => doc.isNotEmpty).toList();
        displayedResults = allDocuments;
        isLoading = false;
      });

      print('Fetched $category documents: ${data.length}');
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers(
      FirebaseFirestore firestore) async {
    try {
      final falseApprovedSnapshot = await firestore
          .collection('user')
          .where('approved', isEqualTo: false)
          .get();

      print('False approved Users: ${falseApprovedSnapshot.docs.length}');

      final allUsersSnapshot = await firestore.collection('user').get();

      final noApprovedFieldDocs = allUsersSnapshot.docs
          .where((doc) => !doc.data().containsKey('approved'))
          .toList();

      print('Users with no approved field: ${noApprovedFieldDocs.length}');

      final allDocs = falseApprovedSnapshot.docs + noApprovedFieldDocs;
      return allDocs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()?['name'] ?? 'No name',
                'email': doc.data()?['email'] ?? 'No email',
                'profileImage': doc.data()?['profileImage'],
              })
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPets(
      FirebaseFirestore firestore) async {
    try {
      final falseApprovedSnapshot = await firestore
          .collection('pets')
          .where('approved', isEqualTo: false)
          .get();

      print('False approved Pets: ${falseApprovedSnapshot.docs.length}');

      final allPetsSnapshot = await firestore.collection('pets').get();

      final noApprovedFieldDocs = allPetsSnapshot.docs
          .where((doc) => !doc.data().containsKey('approved'))
          .toList();

      print('Pets with no approved field: ${noApprovedFieldDocs.length}');

      final allDocs = falseApprovedSnapshot.docs + noApprovedFieldDocs;
      return await Future.wait(
          allDocs.map<Future<Map<String, dynamic>>>((doc) async {
        final docData = doc.data() as Map<String, dynamic>?;
        if (docData == null) {
          print('Null document data for doc ID: ${doc.id}');
          return {};
        }
        final userId = docData['userId'];
        final userSnapshot =
            await firestore.collection('user').doc(userId).get();
        final userData = userSnapshot.data() as Map<String, dynamic>?;

        if (userData == null) {
          print('Null user data for user ID: $userId');
          return {};
        }

        return {
          'id': doc.id,
          'userId': userId,
          'collection': 'Pets',
          'name': userData['name'] ?? 'No name',
          'email': userData['email'] ?? 'No email',
          'profileImage': userData['profileImage'],
          'text': docData['petType'] ?? docData['name'] ?? 'Unknown',
          'description': docData['about'] ?? 'No description',
          'location': docData['location'] ?? 'Unknown location',
          'image': docData['imageUrl'] ?? '',
          'price': docData['price'],
          'publishedTime':
              (docData['publishedTime'] as Timestamp?)?.toDate().toString() ??
                  'Unknown date',
          'age': docData['age'],
          'breed': docData['breed'],
          'colour': docData['colour'],
          'sex': docData['sex'],
          'weight': docData['weight'],
          if (docData.containsKey('vaccinationUrl'))
            'vaccinationUrl': docData['vaccinationUrl'],
        };
      }).toList());
    } catch (e) {
      print('Error fetching pets: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts(
      FirebaseFirestore firestore) async {
    try {
      final falseApprovedSnapshot = await firestore
          .collection('products')
          .where('approved', isEqualTo: false)
          .get();

      print('False approved Products: ${falseApprovedSnapshot.docs.length}');

      final allProductsSnapshot = await firestore.collection('products').get();

      final noApprovedFieldDocs = allProductsSnapshot.docs
          .where((doc) => !doc.data().containsKey('approved'))
          .toList();

      print('Products with no approved field: ${noApprovedFieldDocs.length}');

      final allDocs = falseApprovedSnapshot.docs + noApprovedFieldDocs;
      return await Future.wait(
          allDocs.map<Future<Map<String, dynamic>>>((doc) async {
        final docData = doc.data() as Map<String, dynamic>?;
        if (docData == null) {
          print('Null document data for doc ID: ${doc.id}');
          return {};
        }
        final userId = docData['userId'];
        final userSnapshot =
            await firestore.collection('user').doc(userId).get();
        final userData = userSnapshot.data() as Map<String, dynamic>?;

        if (userData == null) {
          print('Null user data for user ID: $userId');
          return {};
        }

        return {
          'id': doc.id,
          'userId': userId,
          'collection': 'Products',
          'name': userData['name'] ?? 'No name',
          'email': userData['email'] ?? 'No email',
          'profileImage': userData['profileImage'],
          'text': docData['productName'] ?? 'Unknown',
          'description': docData['description'] ?? 'No description',
          'location': docData['location'] ?? 'Unknown location',
          'image': docData['imageUrl'] ?? '',
          'price': docData['price'],
          'publishedTime':
              (docData['publishedTime'] as Timestamp?)?.toDate().toString() ??
                  'Unknown date',
          'quantity': docData['quantity'],
        };
      }).toList());
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchVeterinary(
      FirebaseFirestore firestore) async {
    try {
      final falseApprovedSnapshot = await firestore
          .collection('Veterinary')
          .where('approved', isEqualTo: false)
          .get();

      print('False approved Veterinary: ${falseApprovedSnapshot.docs.length}');

      final noApprovedFieldSnapshot = await firestore
          .collection('Veterinary')
          .where('approved', isNull: true)
          .get();

      print(
          'Veterinary with no approved field: ${noApprovedFieldSnapshot.docs.length}');

      final allDocs = falseApprovedSnapshot.docs + noApprovedFieldSnapshot.docs;

      return await Future.wait(
          allDocs.map<Future<Map<String, dynamic>>>((doc) async {
        final docData = doc.data() as Map<String, dynamic>?;
        if (docData == null) {
          print('Null document data for doc ID: ${doc.id}');
          return {};
        }
        final userId = docData['userId'];
        final userSnapshot =
            await firestore.collection('user').doc(userId).get();
        final userData = userSnapshot.data() as Map<String, dynamic>?;

        if (userData == null) {
          print('Null user data for user ID: $userId');
          return {};
        }

        return {
          'id': doc.id,
          'userId': userId,
          'collection': 'Veterinary',
          'name': userData['name'] ?? 'No name',
          'email': userData['email'] ?? 'No email',
          'profileImage': userData['profileImage'],
          'text': docData['name'] ?? 'Unknown',
          'description': docData['about'] ?? 'No description',
          'location': docData['location'] ?? 'Unknown location',
          'image': docData['imageUrl'] ?? '',
          'price': docData['price'],
          'publishedTime':
              (docData['publishedTime'] as Timestamp?)?.toDate().toString() ??
                  'Unknown date',
          'experience': docData['experience'],
          'availability': docData['availability'],
          if (docData.containsKey('licenseCertificateUrl'))
            'licenseCertificateUrl': docData['licenseCertificateUrl'],
        };
      }).toList());
    } catch (e) {
      print('Error fetching Veterinary: $e');
      return [];
    }
  }

  Future<void> approveDocument(String id, String? userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      if (userId == null) {
        await firestore.collection('user').doc(id).update({'approved': true});
      } else {
        final userDocRef = firestore.collection('user').doc(userId);

        if (selectedCategory == 'Pets') {
          await firestore.collection('pets').doc(id).update({'approved': true});
          await userDocRef
              .collection('pets')
              .doc(id)
              .update({'approved': true});
        } else if (selectedCategory == 'Products') {
          await firestore
              .collection('products')
              .doc(id)
              .update({'approved': true});
          await userDocRef
              .collection('products')
              .doc(id)
              .update({'approved': true});
        } else if (selectedCategory == 'Veterinary') {
          await firestore
              .collection('Veterinary')
              .doc(id)
              .update({'approved': true});
          await userDocRef
              .collection('Veterinary')
              .doc(id)
              .update({'approved': true});
        }
      }

      setState(() {
        displayedResults.removeWhere((doc) => doc['id'] == id);
      });

      print('Approved document: $id');
    } catch (e) {
      print('Error approving document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Select Filter'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _filterOption('Users'),
                        _filterOption('Pets'),
                        _filterOption('Products'),
                        _filterOption('Veterinary'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('Users'),
                        _buildFilterButton('Pets'),
                        _buildFilterButton('Products'),
                        _buildFilterButton('Veterinary'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        displayedResults = allDocuments.where((doc) {
                          String searchField = selectedCategory == 'Users'
                              ? doc['name'] + ' ' + doc['email']
                              : selectedCategory == 'Pets'
                                  ? doc['petType'] + ' ' + doc['about']
                                  : selectedCategory == 'Products'
                                      ? doc['productName'] +
                                          ' ' +
                                          doc['description']
                                      : selectedCategory == 'Veterinary'
                                          ? doc['name'] + ' ' + doc['about']
                                          : '';
                          return searchField
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase());
                        }).toList();
                        print('Search query: $searchQuery');
                        print('Filtered results: ${displayedResults.length}');
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: displayedResults.isEmpty
                        ? const Center(child: Text('No items found.'))
                        : ListView.builder(
                            itemCount: displayedResults.length,
                            itemBuilder: (context, index) {
                              final item = displayedResults[index];

                              if (selectedCategory == 'Users') {
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: item['profileImage'] !=
                                              null
                                          ? NetworkImage(item['profileImage'])
                                          : const AssetImage(
                                              'asset/image/default_profile.png'),
                                    ),
                                    title: Text(
                                        '${item['name']}, ${item['email']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.check_circle,
                                          color: Colors.green),
                                      onPressed: () {
                                        approveDocument(
                                            item['id'], item['userId']);
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                return GestureDetector(
                                  onTap: () {
                                    if (selectedCategory != 'Users') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailScreen(
                                            data: {
                                              'id': item['id'],
                                              'collection': selectedCategory,
                                              'userId': item['userId'],
                                              'profileName': item['name'],
                                              'profileImage':
                                                  item['profileImage'],
                                              'text': item['text'],
                                              'description':
                                                  item['description'],
                                              'location': item['location'],
                                              'image': item['image'],
                                              'price': item['price'],
                                              'publishedTime':
                                                  item['publishedTime'],
                                              if (selectedCategory ==
                                                  'Veterinary')
                                                'experience':
                                                    item['experience'],
                                              if (selectedCategory ==
                                                  'Veterinary')
                                                'availability':
                                                    item['availability'],
                                              if (selectedCategory == 'Pets')
                                                'age': item['age'],
                                              if (selectedCategory == 'Pets')
                                                'breed': item['breed'],
                                              if (selectedCategory == 'Pets')
                                                'colour': item['colour'],
                                              if (selectedCategory == 'Pets')
                                                'sex': item['sex'],
                                              if (selectedCategory == 'Pets')
                                                'weight': item['weight'],
                                              if (selectedCategory ==
                                                  'Products')
                                                'quantity': item['quantity'],
                                              if (selectedCategory ==
                                                      'Veterinary' &&
                                                  item.containsKey(
                                                      'licenseCertificateUrl'))
                                                'licenseCertificateUrl': item[
                                                    'licenseCertificateUrl'],
                                              if (selectedCategory == 'Pets' &&
                                                  item.containsKey(
                                                      'vaccinationUrl'))
                                                'vaccinationUrl':
                                                    item['vaccinationUrl'],
                                            },
                                            navigationSource: 'ApproveScreen',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                          color: Colors.blue, width: 2),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(8)),
                                          child: item['image'] != null &&
                                                  item['image'].isNotEmpty
                                              ? Image.network(
                                                  item['image'],
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(
                                                          Icons.broken_image,
                                                          size: 50),
                                                )
                                              : const Icon(Icons.broken_image,
                                                  size: 50),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['text'] ?? 'Unknown',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (item['profileImage'] != null)
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage: NetworkImage(
                                                      item['profileImage']),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                          child: Text(
                                            item['description'] ??
                                                'No description',
                                            style: const TextStyle(
                                              fontSize: 14,
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
                                              Text(
                                                'Published: ${item['publishedTime'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['publishedTime'])) : 'Unknown date'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                onPressed: () {
                                                  approveDocument(item['id'],
                                                      item['userId']);
                                                },
                                                icon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12.0, bottom: 12.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['location'] ??
                                                    'Unknown location',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _filterOption(String option) {
    return ListTile(
      title: Text(option),
      onTap: () {
        setState(() {
          selectedCategory = option;
          fetchData(selectedCategory); // Update displayed results
        });
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildFilterButton(String category) {
    bool isSelected = selectedCategory == category;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCategory = category;
          fetchData(selectedCategory); // Fetch data for new category
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade600,
      ),
      child: Text(
        category,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
