import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/chatDetailScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'floatingbttn.dart';
import 'productScreen.dart';
import 'profile.dart';
import 'cartScreen.dart';
import 'messageScreen.dart';
import 'searchScreen.dart';
import 'addScreen.dart';
import 'veterinary.dart';
import 'veterinaryAdd.dart';
import 'detailScreen.dart'; // Import the DetailScreen

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

  @override
  void initState() {
    super.initState();
    _fetchUserPosition();
    _screens = [
      const Messagescreen(),
      const Searchscreen(),
      Container(), // Placeholder, _buildHomeScreen will be rebuilt later
      const CartScreen(),
      const ProfileScreen(),
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
              _buildSection('products', 'productName'),
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
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(collection).limit(5).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching data'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data found'));
        } else {
          return Column(
            children: snapshot.data!.docs.map((doc) {
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
                    return const SizedBox
                        .shrink(); // Hide the tile if user is not found
                  } else {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
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
                                'description':
                                    data['about'] ?? 'No description',
                                'location':
                                    data['location'] ?? 'Unknown location',
                                'published':
                                    data['published'] ?? 'Unknown time',
                                'profileImage': userData['profileImage'] ?? '',
                                'profileImagePublicId':
                                    userData['profileImagePublicId'] ?? '',
                                'profileName':
                                    userData['name'] ?? 'Unknown user',
                              },
                            ),
                          ),
                        );
                      },
                      child: _buildTile(
                        id: doc.id,
                        collection: collection,
                        image: data['imageUrl'] ?? '',
                        text: data[nameField] ?? 'Unknown',
                        description: data['about'] ?? 'No description',
                        location: data['location'] ?? 'Unknown location',
                        published: data['published'] ?? 'Unknown time',
                        profileImage: userData['profileImage'] ?? '',
                        profileImagePublicId:
                            userData['profileImagePublicId'] ?? '',
                        profileName: userData['name'] ?? 'Unknown user',
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

  Widget _buildTile({
    required String id,
    required String collection,
    required String image,
    required String text,
    required String description,
    required String location,
    required String published,
    required String profileImage,
    required String profileImagePublicId,
    required String profileName,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
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
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8), // Added space above the description
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
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : const AssetImage('asset/image/dog1.png')
                          as ImageProvider,
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
      'addedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('CartList')
        .doc(item['id'])
        .set(cartItem);
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
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
            MaterialPageRoute(builder: (context) => const ProductsScreen()),
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
            MaterialPageRoute(builder: (context) => const VeterinaryScreen()),
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
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      );
    }
  }
}
