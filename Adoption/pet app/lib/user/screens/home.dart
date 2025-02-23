import 'dart:math';
import 'package:flutter/material.dart';
import 'package:PetApp/user/screens/chatDetailScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'floatingbttn.dart';
import 'productScreen.dart';
import 'profile.dart';
import 'cartScreen.dart';
import 'messageScreen.dart';
import 'searchScreen.dart';
import 'addScreen.dart';
import 'veterinary.dart';
import 'veterinaryAdd.dart';
import 'detailScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  DateTime? lastBackPressed;
  String? _userPosition;
  late final List<Widget> _screens;
  int? _totalDocs;

  @override
  void initState() {
    super.initState();
    _fetchUserPosition();
    _getTotalDocs();
    _screens = [
      const Messagescreen(navigationSource: 'HomePage'),
      const Searchscreen(navigationSource: 'HomePage'),
      Container(),
      const CartScreen(navigationSource: 'HomePage'),
      const ProfileScreen(navigationSource: 'HomePage'),
    ];
  }

  Future<void> _fetchUserPosition() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        _userPosition = userDoc.data()?['position'];
      });
    }
  }

  Future<void> _getTotalDocs() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _totalDocs = querySnapshot.size;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _screens[2] = _buildHomeScreen();
    });
  }

  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pets',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSection('pets', 'petType'),
              const SizedBox(height: 16),
              const Text(
                'Products',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSection('products', 'description'),
              const SizedBox(height: 16),
              const Text(
                'Veterinary',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSection('Veterinary', 'name'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String collection, String nameField) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchApprovedDocuments(collection),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching data'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data found'));
        } else {
          return Column(
            children: snapshot.data!.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('user')
                    .doc(data['userId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (userSnapshot.hasError) {
                    return const Center(
                        child: Text('Error fetching user data'));
                  } else if (!userSnapshot.hasData ||
                      !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  } else {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    final isUserApproved = userData['approved'] == true;

                    final publishedTime =
                        (data['publishedTime'] as Timestamp?)?.toDate();
                    final publishedDate = publishedTime != null
                        ? DateFormat('dd MMM yyyy').format(publishedTime)
                        : 'Unknown date';
                    final licenseCertificateUrl = collection == 'Veterinary' &&
                            data.containsKey('licenseCertificateUrl')
                        ? data['licenseCertificateUrl']
                        : null;

                    final vaccinationUrl = collection == 'pets' &&
                            data.containsKey('vaccinationUrl')
                        ? data['vaccinationUrl']
                        : null;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              data: {
                                'id': doc.id,
                                'collection': collection,
                                'image': data['imageUrl'] ?? '',
                                'text': data[nameField] ?? 'Unknown',
                                'description': collection == 'products'
                                    ? data['description']
                                    : data['about'] ?? 'No description',
                                'location':
                                    data['location'] ?? 'Unknown location',
                                'published': publishedDate,
                                'profileImage': userData['profileImage'] ??
                                    'asset/image/default_profile.png',
                                'profileName':
                                    userData['name'] ?? 'Unknown user',
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
                                if (licenseCertificateUrl != null)
                                  'licenseCertificateUrl':
                                      licenseCertificateUrl,
                                if (vaccinationUrl != null)
                                  'vaccinationUrl': vaccinationUrl,
                              },
                              navigationSource: 'HomePage',
                            ),
                          ),
                        );
                      },
                      child: _buildTile(
                        id: doc.id,
                        collection: collection,
                        image: data['imageUrl'] ?? '',
                        text: data[nameField] ?? 'Unknown',
                        description: collection == 'products'
                            ? data['description']
                            : data['about'] ?? 'No description',
                        location: data['location'] ?? 'Unknown location',
                        published: publishedDate,
                        profileImage: userData['profileImage'] != null &&
                                userData['profileImage'].isNotEmpty
                            ? NetworkImage(userData['profileImage'])
                            : const AssetImage(
                                'asset/image/default_profile.png'),
                        profileName: userData['name'] ?? 'Unknown user',
                        userId: data['userId'],
                        isUserApproved: isUserApproved,
                      ),
                    );
                  }
                },
              );
            }).toList(),
          );
        }
      },
    );
  }

  Future<List<QueryDocumentSnapshot>> _fetchApprovedDocuments(
      String collection) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('approved', isEqualTo: true)
        .get();

    final approvedDocs = querySnapshot.docs;
    approvedDocs.shuffle(); // Shuffle the list to get a random subset
    final randomDocs = approvedDocs.take(5).toList(); // Take 5 random documents

    return randomDocs;
  }

  Widget _buildTile({
    required String id,
    required String collection,
    required String image,
    required String text,
    required String description,
    required String location,
    required String published,
    required ImageProvider<Object> profileImage,
    required String profileName,
    required String userId,
    required bool isUserApproved,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isUserApproved
            ? BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      color: isUserApproved ? Colors.lightBlue.shade50 : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  )
                : const Icon(Icons.broken_image, size: 50),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isUserApproved)
                  const Icon(Icons.verified, color: Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: profileImage,
                ),
                const SizedBox(width: 8),
                Text(
                  profileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    addItemToCart({
                      'id': id,
                      'collection': collection,
                      'image': image,
                      'text': text,
                      'description': description,
                      'location': location,
                      'published': published,
                      'profileName': profileName,
                      'userId': userId,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$text added to cart'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_outlined),
                ),
                IconButton(
                  onPressed: () {
                    reportItem({
                      'id': id,
                      'collection': collection,
                      'image': image,
                      'text': text,
                      'description': description,
                      'location': location,
                      'published': published,
                      'profileName': profileName,
                      'userId': userId,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$text reported'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'Published: $published',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
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
  }

  void addItemToCart(Map<String, String> item) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartItem = {
      'id': item['id'],
      'collection': item['collection'],
      'image': item['image'],
      'text': item['text'],
      'description': item['description'],
      'location': item['location'],
      'published': item['published'],
      'profileName': item['profileName'],
      'userId': item['userId'],
      'addedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('CartList')
        .doc(item['id'])
        .set(cartItem);
  }

  void reportItem(Map<String, String> item) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final reportItem = {
      'id': item['id'],
      'collection': item['collection'],
      'image': item['image'],
      'text': item['text'],
      'description': item['description'],
      'location': item['location'],
      'published': item['published'],
      'profileName': item['profileName'],
      'userId': item['userId'],
      'reportedBy': userId,
      'reportedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('Reports')
        .doc(item['id'])
        .set(reportItem);
  }

  Future<void> _handleRefresh() async {
    setState(() {});
    await _getTotalDocs();
    setState(() {
      _screens[2] = _buildHomeScreen();
      print("Refreshed");
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    const duration = Duration(seconds: 2);

    if (lastBackPressed == null ||
        now.difference(lastBackPressed!) > duration) {
      lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    lastBackPressed = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_userPosition == 'Buyer-Seller') {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const ProductsScreen(navigationSource: 'HomePage')),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.storefront),
      );
    } else if (_userPosition == 'Buyer-Veterinary') {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const VeterinaryScreen(navigationSource: 'HomePage')),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.medical_services),
      );
    } else {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const AddItemScreen(navigationSource: 'HomePage')),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      );
    }
  }
}
