import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:PetApp/user/screens/detailScreen.dart';
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
  Map<String, Map<String, String>> _userProfileCache = {};

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
        'isApproved': 'false',
      };
    }
    if (_userProfileCache.containsKey(userId)) {
      return _userProfileCache[userId]!;
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
      final isApproved =
          data.containsKey('approved') && data['approved'] == true
              ? 'true'
              : 'false';
      final profileData = {
        'profileImage': profileImage,
        'profileName': profileName,
        'isApproved': isApproved,
      };
      _userProfileCache[userId] = profileData.cast<String, String>();
      return profileData.cast<String, String>();
    } else {
      return {
        'profileImage': 'asset/image/default_profile.png',
        'profileName': 'Unknown user',
        'isApproved': 'false',
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
    bool filterApproved = true;
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
        filterApproved = false; // Show all pet care tips regardless of approval
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
          bool matchesQuery = data[nameField]
                  ?.toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false;
          bool approved = filterApproved ? (data['approved'] == true) : true;
          return matchesQuery && approved;
        }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index].data() as Map<String, dynamic>;

            if (_selectedOption == 'Pet Care Tips') {
              return _buildArticleTile(items[index].id, item);
            } else {
              return FutureBuilder<Map<String, String>>(
                future: _fetchProfileData(item['userId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingTile(
                        item, collection, nameField, items[index].id);
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  } else {
                    final profileData = snapshot.data!;
                    final isUserApproved = profileData['isApproved'] == 'true';

                    if (!isUserApproved) {
                      return const SizedBox.shrink();
                    }

                    final publishedTime =
                        (item['publishedTime'] as Timestamp?)?.toDate();
                    final publishedDate = publishedTime != null
                        ? DateFormat('dd MMM yyyy').format(publishedTime)
                        : 'Unknown date';

                    ImageProvider<Object> profileImageProvider;
                    if (profileData['profileImage']!.startsWith('http')) {
                      profileImageProvider =
                          NetworkImage(profileData['profileImage']!);
                    } else {
                      profileImageProvider =
                          AssetImage(profileData['profileImage']!);
                    }

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
                                'description':
                                    item['about'] ?? 'No description',
                                'location':
                                    item['location'] ?? 'Unknown location',
                                'published': publishedDate,
                                'profileImage': profileImageProvider,
                                'profileName': profileData['profileName'] ??
                                    'Unknown user',
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
                      child: _buildTile(
                        id: items[index].id,
                        collection: collection,
                        image: item['imageUrl'] ?? '',
                        text: item[nameField] ?? 'Unknown',
                        description: item['about'] ?? 'No description',
                        location: item['location'] ?? 'Unknown location',
                        published: publishedDate,
                        profileImage: profileImageProvider,
                        profileName:
                            profileData['profileName'] ?? 'Unknown user',
                        userId: item['userId'],
                        isUserApproved: isUserApproved,
                      ),
                    );
                  }
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingTile(Map<String, dynamic> item, String collection,
      String nameField, String id) {
    return _buildTile(
      id: id,
      collection: collection,
      image: item['imageUrl'] ?? '',
      text: item[nameField] ?? 'Unknown',
      description: item['about'] ?? 'No description',
      location: item['location'] ?? 'Unknown location',
      published: item['published'] ?? 'Unknown time',
      profileImage: const AssetImage('asset/image/default_profile.png'),
      profileName: 'Unknown user',
      userId: item['userId'] ?? 'Unknown',
      isUserApproved:
          false, // Since this is a loading tile, assume not approved
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
