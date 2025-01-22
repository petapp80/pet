import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      // Fetch documents with 'approved' field false
      final falseApprovedSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('approved', isEqualTo: false)
          .get();

      // Fetch all documents in 'user' collection
      final allUsersSnapshot =
          await FirebaseFirestore.instance.collection('user').get();

      // Filter documents without 'approved' field
      final noApprovedFieldDocs = allUsersSnapshot.docs
          .where((doc) => !doc.data().containsKey('approved'))
          .toList();

      // Combine both sets of documents
      final allDocs = falseApprovedSnapshot.docs + noApprovedFieldDocs;

      List<Map<String, dynamic>> data = allDocs
          .map((doc) => {
                'id': doc.id, // Store document ID
                'name': doc.data()['name'] ?? 'No name',
                'email': doc.data()['email'] ?? 'No email',
              })
          .toList();

      setState(() {
        allDocuments = data;
        displayedResults = data;
        isLoading = false; // Stop loading indicator
      });

      print('Fetched user documents: ${data.length}');
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false; // Stop loading indicator in case of error
      });
    }
  }

  Future<void> fetchData(String category) async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data;
      switch (category) {
        case 'Users':
          final falseApprovedSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('approved', isEqualTo: false)
              .get();

          final allUsersSnapshot =
              await FirebaseFirestore.instance.collection('user').get();

          final noApprovedFieldDocs = allUsersSnapshot.docs
              .where((doc) => !doc.data().containsKey('approved'))
              .toList();

          final allDocs = falseApprovedSnapshot.docs + noApprovedFieldDocs;
          data = allDocs
              .map((doc) => {
                    'id': doc.id, // Store document ID
                    'name': doc.data()['name'] ?? 'No name',
                    'email': doc.data()['email'] ?? 'No email',
                  })
              .toList();
          break;
        case 'Pets':
          // Fetch documents with 'approved' field false
          final falseApprovedPetsSnapshot = await FirebaseFirestore.instance
              .collection('pets')
              .where('approved', isEqualTo: false)
              .get();

          // Fetch all documents in 'pets' collection
          final allPetsSnapshot =
              await FirebaseFirestore.instance.collection('pets').get();

          // Filter documents without 'approved' field and check for required fields
          final noApprovedFieldPetsDocs = allPetsSnapshot.docs
              .where((doc) =>
                  !doc.data().containsKey('approved') &&
                  doc.data().containsKey('petType') &&
                  doc.data().containsKey('about'))
              .toList();

          // Combine both sets of documents
          final allPetsDocs =
              falseApprovedPetsSnapshot.docs + noApprovedFieldPetsDocs;

          data = allPetsDocs
              .map((doc) => {
                    'id': doc.id, // Store document ID
                    'userId': doc.data()['userId'], // Store parent user ID
                    'petType': doc.data()['petType'] ?? 'No pet type',
                    'about': doc.data()['about'] ?? 'No about information',
                  })
              .toList();

          print('Fetched pet documents: ${data.length}');
          data.forEach((doc) {
            print('Fetched pet: ${doc.toString()}');
          });
          break;
        case 'Products':
          final userSnapshot =
              await FirebaseFirestore.instance.collection('user').get();
          final productData =
              await Future.wait(userSnapshot.docs.map((doc) async {
            final userId = doc.id;
            final userName = doc.data()['name'];
            final userEmail = doc.data()['email'];
            final productsSnapshot =
                await doc.reference.collection('products').get();
            return productsSnapshot.docs.map((productDoc) {
              final product = productDoc.data();
              return {
                'id': productDoc.id, // Store document ID
                'userId': userId, // Store parent user ID
                'name': userName,
                'productName': product['productName'] ?? 'No product name',
                'description': product['description'] ?? 'No description',
                'location': product['location'] ?? 'No location',
                'price': product['price'] ?? 'No price',
                'imagePublicId':
                    product['imagePublicId'] ?? 'No image public ID',
                'imageUrl': product['imageUrl'] ?? 'No image URL',
                'quantity': product['quantity'] ?? 'No quantity',
                'userEmail': userEmail,
              };
            }).toList();
          }));
          data = productData
              .expand((x) => x)
              .toList()
              .cast<Map<String, dynamic>>();
          break;
        case 'Veterinary':
          final userSnapshot =
              await FirebaseFirestore.instance.collection('user').get();
          final vetData = await Future.wait(userSnapshot.docs.map((doc) async {
            final userId = doc.id;
            final userName = doc.data()['name'];
            final userEmail = doc.data()['email'];
            final vetSnapshot =
                await doc.reference.collection('Veterinary').get();
            return vetSnapshot.docs.map((vetDoc) {
              final vet = vetDoc.data();
              return {
                'id': vetDoc.id, // Store document ID
                'userId': userId, // Store parent user ID
                'userName': userName,
                'userEmail': userEmail,
                'vetType': vet['vetType'] ?? 'No vet type',
                'about': vet['about'] ?? 'No about information',
              };
            }).toList();
          }));
          data = vetData.expand((x) => x).toList().cast<Map<String, dynamic>>();
          break;
        default:
          data = [];
          break;
      }

      setState(() {
        allDocuments = data;
        displayedResults = data;
        isLoading = false; // Stop loading indicator
      });

      print('Displayed results: ${displayedResults.length}');
      displayedResults.forEach((item) {
        print('Displayed item: ${item.toString()}');
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false; // Stop loading indicator in case of error
      });
    }
  }

  Future<void> approveDocument(String id, String? userId) async {
    try {
      if (userId == null) {
        // Update in 'user' collection
        await FirebaseFirestore.instance
            .collection('user')
            .doc(id)
            .update({'approved': true});
      } else {
        // Update in user's subcollections
        final userDocRef =
            FirebaseFirestore.instance.collection('user').doc(userId);

        if (selectedCategory == 'Pets') {
          // Update in user's 'pets' subcollection and 'pets' collection
          await FirebaseFirestore.instance
              .collection('pets')
              .doc(id)
              .update({'approved': true});
          await userDocRef
              .collection('pets')
              .doc(id)
              .update({'approved': true});
        } else if (selectedCategory == 'Products') {
          // Update in user's 'products' subcollection and 'products' collection
          await FirebaseFirestore.instance
              .collection('products')
              .doc(id)
              .update({'approved': true});
          await userDocRef
              .collection('products')
              .doc(id)
              .update({'approved': true});
        } else if (selectedCategory == 'Veterinary') {
          // Update in user's 'Veterinary' subcollection and 'Veterinary' collection
          await FirebaseFirestore.instance
              .collection('Veterinary')
              .doc(id)
              .update({'approved': true});
          await userDocRef
              .collection('Veterinary')
              .doc(id)
              .update({'approved': true});
        }
      }

      // Remove the approved document from displayed results
      setState(() {
        displayedResults.removeWhere((doc) => doc['id'] == id);
      });
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
                                          ? doc['userName'] + ' ' + doc['about']
                                          : '';
                          return searchField
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase());
                        }).toList();
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
                              String displayText;
                              if (selectedCategory == 'Users') {
                                displayText =
                                    '${item['name']}, ${item['email']}';
                              } else if (selectedCategory == 'Pets') {
                                displayText =
                                    '${item['petType']}, ${item['about']}';
                              } else if (selectedCategory == 'Products') {
                                displayText =
                                    '${item['productName']}, ${item['description']}';
                              } else if (selectedCategory == 'Veterinary') {
                                displayText =
                                    '${item['userName']}, ${item['userEmail']}';
                              } else {
                                displayText = 'No display text';
                              }
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  title: Text(displayText),
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
