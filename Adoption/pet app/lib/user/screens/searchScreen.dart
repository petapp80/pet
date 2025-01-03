import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/detailScreen.dart';
import 'package:intl/intl.dart'; // Import to format DateTime

class Searchscreen extends StatefulWidget {
  final String navigationSource;

  const Searchscreen({super.key, required this.navigationSource});

  @override
  State<Searchscreen> createState() => _SearchscreenState();
}

class _SearchscreenState extends State<Searchscreen> {
  final List<String> _options = [
    'Pets',
    'Products',
    'Veterinary',
    'Pet Care Tips'
  ];
  String _selectedOption = 'Pets';
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _fetchProfileData(String? userId) async {
    if (userId == null) {
      return {
        'profileImage': 'asset/image/default_profile.png',
        'profileName': 'Unknown user',
      };
    }
    final userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      final profileImage = data.containsKey('profileImage') &&
              data['profileImage'] != null &&
              data['profileImage'].isNotEmpty
          ? data['profileImage']
          : 'asset/image/default_profile.png';
      final profileName = data.containsKey('name') &&
              data['name'] != null &&
              data['name'].isNotEmpty
          ? data['name']
          : 'Unknown user';
      return {
        'profileImage': profileImage,
        'profileName': profileName,
      };
    } else {
      return {
        'profileImage': 'asset/image/default_profile.png',
        'profileName': 'Unknown user',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Type to search...',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: DropdownButton<String>(
                  value: _selectedOption,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: Container(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOption = newValue!;
                    });
                  },
                  items: _options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    String collection;
    String nameField;
    switch (_selectedOption) {
      case 'Products':
        collection = 'products';
        nameField = 'productName';
        break;
      case 'Veterinary':
        collection = 'Veterinary';
        nameField = 'name';
        break;
      case 'Pets':
        collection = 'pets';
        nameField = 'petType';
        break;
      default:
        collection = 'articles';
        nameField = 'title';
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching data'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data found'));
        }

        final items = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data[nameField]
                  ?.toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false;
        }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index].data() as Map<String, dynamic>;
            if (_selectedOption == 'Pet Care Tips') {
              return _buildArticleTile(items[index].id, item);
            } else {
              return GestureDetector(
                onTap: () {
                  _searchFocusNode.unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        data: {
                          'id': items[index].id,
                          'collection': collection,
                          'image': item['imageUrl'] ?? '',
                          'text': item[nameField] ?? 'Unknown',
                          'description': item['about'] ?? 'No description',
                          'location': item['location'] ?? 'Unknown location',
                          'published': item['published'] ?? 'Unknown time',
                          'profileImage': item['profileImage'] ?? '',
                          'profileName': item['name'] ?? 'Unknown user',
                          'userId': item['userId'],
                          // Include additional fields as necessary
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
                        navigationSource: widget.navigationSource,
                      ),
                    ),
                  );
                },
                child: FutureBuilder<Map<String, String>>(
                  future: _fetchProfileData(item['userId']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildTile(
                        id: items[index].id,
                        collection: collection,
                        image: item['imageUrl'] ?? '',
                        text: item[nameField] ?? 'Unknown',
                        description: item['about'] ?? 'No description',
                        location: item['location'] ?? 'Unknown location',
                        published: item['published'] ?? 'Unknown time',
                        profileImage: 'asset/image/default_profile.png',
                        profileName: 'Unknown user',
                        userId: item['userId'] ?? 'Unknown',
                      );
                    } else if (snapshot.hasError) {
                      return _buildTile(
                        id: items[index].id,
                        collection: collection,
                        image: item['imageUrl'] ?? '',
                        text: item[nameField] ?? 'Unknown',
                        description: item['about'] ?? 'No description',
                        location: item['location'] ?? 'Unknown location',
                        published: item['published'] ?? 'Unknown time',
                        profileImage: 'asset/image/default_profile.png',
                        profileName: 'Unknown user',
                        userId: item['userId'] ?? 'Unknown',
                      );
                    } else {
                      final profileData = snapshot.data!;
                      return _buildTile(
                        id: items[index].id,
                        collection: collection,
                        image: item['imageUrl'] ?? '',
                        text: item[nameField] ?? 'Unknown',
                        description: item['about'] ?? 'No description',
                        location: item['location'] ?? 'Unknown location',
                        published: item['published'] ?? 'Unknown time',
                        profileImage: profileData['profileImage']!,
                        profileName: profileData['profileName']!,
                        userId: item['userId'] ?? 'Unknown',
                      );
                    }
                  },
                ),
              );
            }
          },
        );
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
    required String profileName,
    required String userId,
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
                  backgroundImage: profileImage.startsWith('asset/')
                      ? AssetImage(profileImage)
                      : NetworkImage(profileImage) as ImageProvider<Object>,
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
                    addItemToCart(context, {
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

  void addItemToCart(BuildContext context, Map<String, String> item) async {
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

  Widget _buildArticleTile(String id, Map<String, dynamic> article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Card(
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
              child: article['image'] != null
                  ? Image.network(
                      article['image'],
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
                article['title'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                article['summary'] ?? 'No description',
                style: const TextStyle(
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'Published: ${DateFormat('yyyy-MM-dd – kk:mm').format(article['timestamp'].toDate())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article['title']),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              article['image'] != null
                  ? Image.network(article['image'])
                  : const SizedBox.shrink(),
              const SizedBox(height: 16),
              Text(
                article['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Published: ${DateFormat('yyyy-MM-dd – kk:mm').format(article['timestamp'].toDate())}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                article['summary'],
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ...article['content'].map<Widget>((part) {
                if (part['type'] == 'text') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      part['content'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                } else if (part['type'] == 'image') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.network(part['content']),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
