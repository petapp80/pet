import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
          final userSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('name', isGreaterThanOrEqualTo: query)
              .get();
          data = userSnapshot.docs.map((doc) => doc.data()).toList();
          break;
        case 'Pets':
          final userSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('name', isGreaterThanOrEqualTo: query)
              .get();
          final petData = await Future.wait(userSnapshot.docs.map((doc) async {
            final userId = doc.id;
            final userName = doc.data()['name'];
            final userEmail = doc.data()['email'];
            final petsSnapshot = await doc.reference.collection('pets').get();
            return petsSnapshot.docs.map((petDoc) {
              final pet = petDoc.data();
              return {
                ...pet,
                'userId': userId,
                'userName': userName,
                'userEmail': userEmail,
                'name': userName,
              };
            }).toList();
          }));
          data = petData.expand((x) => x).toList();
          break;
        case 'Products':
          final userSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('name', isGreaterThanOrEqualTo: query)
              .get();
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
                ...product,
                'userId': userId,
                'userName': userName,
                'userEmail': userEmail,
                'name': userName,
              };
            }).toList();
          }));
          data = productData.expand((x) => x).toList();
          break;
        case 'Veterinary':
          final vetSnapshot = await FirebaseFirestore.instance
              .collection('veterinary')
              .where('name', isGreaterThanOrEqualTo: query)
              .get();
          data = vetSnapshot.docs.map((doc) => doc.data()).toList();
          break;
        default:
          data = [];
          break;
      }
      setState(() {
        searchResults = data;
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
          email: item['email'] ?? 'No email',
        );
        break;
      case 'Pets':
        editScreen = PetEdit(
          name: item['name'] ?? 'No name',
          petData: item,
          userName: item['userName'] ?? 'No user name',
          userEmail: item['userEmail'] ?? 'No user email',
          userId: item['userId'] ?? 'No userId',
        );
        break;
      case 'Products':
        editScreen = ProductEdit(
          name: item['name'] ?? 'No name',
          productData: item,
          userName: item['userName'] ?? 'No user name',
          userEmail: item['userEmail'] ?? 'No user email',
          userId: item['userId'] ?? 'No userId',
        );
        break;
      case 'Veterinary':
        editScreen = VeterinaryEdit(
          name: item['name'] ?? 'No name',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = 'Users';
                      searchResults = [];
                    });
                  },
                  child: const Text('Users'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = 'Pets';
                      searchResults = [];
                    });
                  },
                  child: const Text('Pets'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = 'Products';
                      searchResults = [];
                    });
                  },
                  child: const Text('Products'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = 'Veterinary';
                      searchResults = [];
                    });
                  },
                  child: const Text('Veterinary'),
                ),
              ],
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
                        return Card(
                          child: ListTile(
                            title: Text(item['name'] ?? 'No name'),
                            subtitle: Text(
                              selectedCategory == 'Users'
                                  ? item['email'] ?? 'No email'
                                  : selectedCategory == 'Pets'
                                      ? item['about'] ?? 'No About Information'
                                      : selectedCategory == 'Products'
                                          ? item['description'] ??
                                              'No Description'
                                          : item['about'] ??
                                              'No About Information',
                            ),
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
}
