import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';
import 'userEdit.dart';
import 'petEdit.dart';
import 'productEdit.dart';
import 'veterinaryEdit.dart';

class NewlyRegistered extends StatefulWidget {
  const NewlyRegistered({super.key});

  @override
  State<NewlyRegistered> createState() => _NewlyRegisteredState();
}

class _NewlyRegisteredState extends State<NewlyRegistered> {
  String selectedCategory = 'Users'; // Default category
  String searchQuery = ''; // Current search query

  List<Map<String, dynamic>> searchResults = [];

  Future<void> fetchData(String category, String query) async {
    if (query.isEmpty) {
      return;
    }

    try {
      List<Map<String, dynamic>> data;
      switch (category) {
        case 'Users':
          final userSnapshot =
              await FirebaseFirestore.instance.collection('user').get();
          data = userSnapshot.docs
              .map((doc) => {
                    'name': doc.data()['name'] ?? 'No name',
                    'email': doc.data()['email'] ?? 'No email',
                    'position': doc.data()['position'] ?? 'No position',
                  })
              .toList();
          break;
        case 'Pets':
          final userSnapshot =
              await FirebaseFirestore.instance.collection('user').get();
          final petData = await Future.wait(userSnapshot.docs.map((doc) async {
            final userId = doc.id;
            final userName = doc.data()['name'];
            final userEmail = doc.data()['email'];
            final petsSnapshot = await doc.reference.collection('pets').get();
            return petsSnapshot.docs.map((petDoc) {
              final pet = petDoc.data();
              return {
                'petDocId': petDoc.id, // Add pet document ID
                'userName': userName,
                'userEmail': userEmail, // Add userEmail
                'userId': userId, // Add userId
                'petType': pet['petType'] ?? 'No pet type',
                'about': pet['about'] ?? 'No about information',
              };
            }).toList();
          }));
          data = petData.expand((x) => x).toList().cast<Map<String, dynamic>>();
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
                'productDocId': productDoc.id, // Add product document ID
                'name': userName,
                'productName': product['productName'] ?? 'No product name',
                'description': product['description'] ?? 'No description',
                'location': product['location'] ?? 'No location',
                'price': product['price'] ?? 'No price',
                'imagePublicId':
                    product['imagePublicId'] ?? 'No image public ID',
                'imageUrl': product['imageUrl'] ?? 'No image URL',
                'quantity': product['quantity'] ?? 'No quantity',
                'userId': userId, // Add userId
                'userEmail': userEmail, // Add userEmail
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
                'vetDocId': vetDoc.id, // Add veterinary document ID
                'userName':
                    userName, // Ensure this is consistent with other sections
                'userEmail': userEmail, // Add userEmail
                'userId': userId, // Add userId
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

      // Filter data using string similarity
      final filteredData = data.where((item) {
        String searchString;
        if (category == 'Users') {
          searchString = item['name']?.toString() ?? '';
        } else if (category == 'Pets') {
          searchString = item['userName']?.toString() ?? '';
        } else if (category == 'Products') {
          searchString = item['name']?.toString() ?? '';
        } else if (category == 'Veterinary') {
          searchString = item['userName']?.toString() ?? '';
        } else {
          searchString = '';
        }
        return searchString.similarityTo(query) >
            0.3; // You can adjust the threshold value as needed
      }).toList();

      setState(() {
        searchResults = filteredData;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _navigateToEditScreen(Map<String, dynamic> item) {
    Widget editScreen;
    switch (selectedCategory) {
      case 'Users':
        editScreen = UserEdit(
          name: item['name'] ?? 'No name',
          position: item['position'] ?? 'No position',
        );
        break;
      case 'Pets':
        editScreen = PetEdit(
          name: item['userName'] ?? 'No name',
          petData: item,
          userName: item['userName'] ?? 'No user name',
          userEmail: item['userEmail'] ?? 'No user email',
          userId: item['userId'] ?? 'No userId',
          petId: item['petDocId'] ?? 'No petId', // Pass the pet document ID
        );
        break;
      case 'Products':
        editScreen = ProductEdit(
          name: item['productName'] ?? 'No product name',
          productData: item,
          userName: item['name'] ?? 'No user name',
          userEmail: item['userEmail'] ?? 'No user email',
          userId: item['userId'] ?? 'No userId',
          productId: item['productDocId'] ?? 'No productId',
        );
        break;
      case 'Veterinary':
        editScreen = VeterinaryEdit(
          name: item['userName'] ?? 'No name',
          vetData: item,
          userId: item['userId'] ?? 'No userId',
        );
        break;
      default:
        editScreen = Container();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => editScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$selectedCategory - Newly Registered'),
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
      body: Padding(
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
                });
                fetchData(selectedCategory, value);
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
              child: searchResults.isEmpty
                  ? const Center(child: Text('No items found.'))
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        String displayText;
                        if (selectedCategory == 'Users') {
                          displayText = '${item['name']}, ${item['email']}';
                        } else if (selectedCategory == 'Pets') {
                          displayText =
                              '${item['userName']}, Type: ${item['petType']}, About: ${item['about']}';
                        } else if (selectedCategory == 'Products') {
                          displayText =
                              '${item['name']}, Product: ${item['productName']}, Description: ${item['description']}';
                        } else if (selectedCategory == 'Veterinary') {
                          displayText =
                              '${item['userName']}, ${item['userEmail']}';
                        } else {
                          displayText = 'No display text';
                        }
                        return Card(
                          child: ListTile(
                            title: Text(displayText),
                            onTap: () => _navigateToEditScreen(item),
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
          searchResults = [];
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
          searchResults = [];
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
