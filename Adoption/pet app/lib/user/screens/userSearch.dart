import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'userEdit.dart';
import 'petEdit.dart';
import 'productEdit.dart';
import 'veterinaryEdit.dart';

class UserSearch extends StatefulWidget {
  const UserSearch({super.key});

  @override
  State<UserSearch> createState() => _UserSearchState();
}

class _UserSearchState extends State<UserSearch> {
  String searchQuery = '';
  String selectedCategory = 'Users'; // Default category

  List<Map<String, dynamic>> searchResults = [];

  Future<void> fetchSearchResults() async {
    if (searchQuery.isEmpty) {
      return;
    }

    try {
      List<Map<String, dynamic>> data;
      switch (selectedCategory) {
        case 'Users':
          final userSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('name', isGreaterThanOrEqualTo: searchQuery)
              .get();
          data = userSnapshot.docs.map((doc) => doc.data()).toList();
          break;
        case 'Pets':
          final userSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('name', isGreaterThanOrEqualTo: searchQuery)
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
              .where('name', isGreaterThanOrEqualTo: searchQuery)
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
              .collection('Veterinary')
              .where('name', isGreaterThanOrEqualTo: searchQuery)
              .get();
          data = vetSnapshot.docs.map((doc) {
            var vetData = doc.data();
            vetData['userId'] = doc.id; // Add the userId to the data
            return vetData;
          }).toList();
          break;
        default:
          data = [];
          break;
      }
      setState(() {
        searchResults = data;
      });
    } catch (e) {
      print('Error fetching search results: $e');
    }
  }

  void _navigateToEditScreen(Map<String, dynamic> item) async {
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

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => editScreen,
      ),
    );

    // Refresh the search results if an item was deleted
    if (result == true) {
      fetchSearchResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                      fetchSearchResults();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search $selectedCategory',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedCategory,
                  items: <String>['Users', 'Pets', 'Products', 'Veterinary']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                      searchQuery =
                          ''; // Clear search when switching categories
                      searchResults =
                          []; // Clear search results when switching categories
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Results
          Expanded(
            child: searchResults.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final item = searchResults[index];
                      return ListTile(
                        title: Text(item['name'] ?? 'No name'),
                        subtitle: Text(item['email'] ??
                            item['about'] ??
                            item['description'] ??
                            'No information'),
                        onTap: () => _navigateToEditScreen(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
