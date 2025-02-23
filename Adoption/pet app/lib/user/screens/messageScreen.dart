import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:string_similarity/string_similarity.dart';
import 'chatDetailScreen.dart'; // Import the ChatDetailScreen
import 'aiChat.dart'; // Import the AIWebView

class Messagescreen extends StatefulWidget {
  final String? navigationSource; // Make this parameter optional

  const Messagescreen({super.key, this.navigationSource});

  @override
  State<Messagescreen> createState() => _MessagescreenState();
}

class _MessagescreenState extends State<Messagescreen> {
  List<Map<String, dynamic>> _filteredMessages = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Function to load messages from Firestore
  Future<void> _loadMessages() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("User is not authenticated");
      return;
    }

    // Determine the collection name based on navigation source or user's position
    String? collectionName;
    if (widget.navigationSource == 'HomePage') {
      collectionName = 'ChatAsBuyer';
    } else if (widget.navigationSource == 'productsScreen') {
      collectionName = 'ChatAsSeller';
      print("Accessed from productsScreen");
    } else if (widget.navigationSource == 'veterinaryScreen') {
      collectionName = 'ChatAsVeterinary';
      print("Accessed from veterinaryScreen");
    }

    if (collectionName == null) {
      final userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      final positionField = userDoc.data()?['position'] ?? 'Buyer';
      collectionName = _getCollectionName(positionField);
    }

    print("Collection Name: $collectionName");

    final querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection(collectionName!)
        .get();

    if (!mounted) return; // Check if the widget is still mounted

    setState(() {
      _filteredMessages = [
        {
          'name': 'Pet App AI',
          'profileImage': 'asset/image/ai_logo.jpg',
          'userId': 'ai_user', // A placeholder ID for Pet App AI
        }
      ];
    });

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final receiverId = doc.id;

      // Fetch the receiver's data from the user collection
      final receiverDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(receiverId)
          .get();

      final receiverData = receiverDoc.data() as Map<String, dynamic>?;
      final name = receiverData?['name'] ?? 'No Name';
      final profileImage =
          receiverData?['profileImage'] ?? 'asset/image/default_profile.png';

      if (mounted) {
        setState(() {
          _filteredMessages.add({
            'name': name,
            'profileImage': profileImage,
            'userId': receiverId,
          });
        });
      }

      print(
          "Fetched Data: name=$name, profileImage=$profileImage, userId=$receiverId");
    }

    print("Filtered Messages: $_filteredMessages");
  }

  // Function to get the collection name based on position field
  String _getCollectionName(String positionField) {
    switch (positionField) {
      case 'Buyer-Veterinary':
        return 'ChatAsVeterinary';
      case 'Buyer-Seller':
        return 'ChatAsSeller';
      default:
        return 'ChatAsBuyer';
    }
  }

  // Function to search users from the Firestore collection
  Future<void> _searchUsers(String query) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (query.isEmpty) {
      setState(() {
        _suggestedUsers = [];
      });
      return;
    }

    final querySnapshot =
        await FirebaseFirestore.instance.collection('user').get();

    if (!mounted) return; // Check if the widget is still mounted

    setState(() {
      _suggestedUsers = querySnapshot.docs
          .where((doc) {
            final name = doc.data().containsKey('name')
                ? doc['name'].toString().toLowerCase()
                : "";
            final position = doc.data().containsKey('position')
                ? doc['position'].toString()
                : "";
            final similarity =
                StringSimilarity.compareTwoStrings(query.toLowerCase(), name);

            if (widget.navigationSource == 'HomePage' && position == 'Buyer') {
              return false;
            }

            return similarity > 0.3; // Adjust this threshold as needed
          })
          .where((doc) => doc.id != userId) // Exclude current user
          .map((doc) {
            final profileImage = (doc.data().containsKey('profileImage') &&
                    (doc['profileImage'] as String).isNotEmpty)
                ? doc['profileImage']
                : 'asset/image/default_profile.png';
            return {
              'name': doc['name'] ?? 'No Name',
              'profileImage': profileImage,
              'userId': doc.id,
            };
          })
          .toList();
    });
    print("Suggested Users: $_suggestedUsers");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              'Messages${widget.navigationSource != null ? ' - ${widget.navigationSource}' : ''}'),
          backgroundColor: isDark ? Colors.black : Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar at the top
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (query) {
                  if (_focusNode.hasFocus) {
                    _searchUsers(query);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Search users or messages',
                  hintText: 'Type to search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 20),
              if (_focusNode.hasFocus && _suggestedUsers.isNotEmpty)
                _buildSuggestions(),

              // List of message boxes with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadMessages,
                  child: ListView.builder(
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = _filteredMessages[index];
                      final profileImage = (message["profileImage"] ==
                              'asset/image/default_profile.png')
                          ? const AssetImage('asset/image/default_profile.png')
                              as ImageProvider<Object>?
                          : NetworkImage(message["profileImage"])
                              as ImageProvider<Object>?;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        color: isDark ? Colors.grey[900] : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          leading: CircleAvatar(
                            backgroundImage: profileImage,
                            radius: 30,
                            onBackgroundImageError: (_, __) {
                              setState(() {
                                message["profileImage"] =
                                    'asset/image/default_profile.png';
                              });
                            },
                          ),
                          title: Text(
                            message["name"],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          onTap: () {
                            if (message["userId"] == 'ai_user') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AIWebView(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    name: message["name"],
                                    image: message["profileImage"] ==
                                            'asset/image/default_profile.png'
                                        ? 'asset/image/default_profile.png'
                                        : message["profileImage"],
                                    navigationSource:
                                        widget.navigationSource ?? 'Default',
                                    userId: message["userId"],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build the suggestions list
  Widget _buildSuggestions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Colors.grey[850]
          : Colors.lightBlueAccent, // Change suggestion background color
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestedUsers.length,
        itemBuilder: (context, index) {
          final user = _suggestedUsers[index];
          final profileImage = (user['profileImage'] ==
                  'asset/image/default_profile.png')
              ? const AssetImage('asset/image/default_profile.png')
                  as ImageProvider<Object>?
              : NetworkImage(user['profileImage']) as ImageProvider<Object>?;

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: profileImage,
              radius: 20,
              onBackgroundImageError: (_, __) {
                setState(() {
                  user['profileImage'] = 'asset/image/default_profile.png';
                });
              },
            ),
            title: Text(
              user['name'] ?? 'No Name',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              _searchController.clear();
              _focusNode.unfocus();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    name: user['name'],
                    image: user['profileImage'] ==
                            'asset/image/default_profile.png'
                        ? 'asset/image/default_profile.png'
                        : user['profileImage'],
                    navigationSource: widget.navigationSource ?? 'Default',
                    userId: user['userId'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
