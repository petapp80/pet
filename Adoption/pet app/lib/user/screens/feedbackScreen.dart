import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:intl/intl.dart'; // Import to format DateTime

// A model class to hold feedback data
class Feedback {
  final String id; // Add an ID field to identify each feedback document
  final String user;
  final String email;
  final String feedbackText;
  final int rating;
  final DateTime date;

  Feedback({
    required this.id,
    required this.user,
    required this.email,
    required this.feedbackText,
    required this.rating,
    required this.date,
  });

  @override
  String toString() {
    return 'Feedback(id: $id, user: $user, email: $email, feedbackText: $feedbackText, rating: $rating, date: $date)';
  }
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<Feedback> _feedbackList = [];
  List<Feedback> _filteredFeedbackList = [];
  String _searchText = '';
  int? _selectedRating;
  bool _isLoading = true; // Loading state
  bool _isDeleting = false; // Deleting state

  @override
  void initState() {
    super.initState();
    _fetchFeedbackData();
  }

  Future<void> _fetchFeedbackData() async {
    QuerySnapshot feedbackSnapshot =
        await FirebaseFirestore.instance.collection('review').get();
    List<Feedback> feedbackList = [];

    for (var doc in feedbackSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      print("Feedback Data: $data");
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(data['userId'])
          .get();

      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;
      if (userData != null) {
        print("User Data for ${data['userId']}: $userData");
        String userName = userData['name'] ?? 'Unknown User';
        String email = userData['email'] ?? 'Unknown Email';

        feedbackList.add(
          Feedback(
            id: doc.id, // Use document ID
            user: userName,
            email: email,
            feedbackText: data['text'] ?? 'No Feedback Provided',
            rating: (data['rating'] as double?)?.toInt() ??
                0, // Handle null and convert to int
            date: (data['timestamp'] as Timestamp).toDate(),
          ),
        );
      } else {
        print("User Data for ${data['userId']} not found.");
      }
    }

    print("Fetched Feedback List: $feedbackList");

    setState(() {
      _feedbackList = feedbackList;
      _filteredFeedbackList = feedbackList;
      _isLoading = false; // Turn off loading state
    });
  }

  // Filter feedback based on the search and rating
  void _filterFeedback() {
    setState(() {
      _filteredFeedbackList = _feedbackList.where((feedback) {
        bool matchesSearch = feedback.feedbackText
                .toLowerCase()
                .contains(_searchText.toLowerCase()) ||
            feedback.user.toLowerCase().contains(_searchText.toLowerCase()) ||
            (_searchText.isNotEmpty &&
                StringSimilarity.compareTwoStrings(
                        feedback.feedbackText.toLowerCase(),
                        _searchText.toLowerCase()) >
                    0.5);
        bool matchesRating =
            _selectedRating == null || feedback.rating == _selectedRating;
        return matchesSearch && matchesRating;
      }).toList();
    });

    print("Filtered Feedback List: $_filteredFeedbackList");
  }

  Future<void> _deleteFeedback(String documentId) async {
    setState(() {
      _isDeleting = true; // Show deleting indicator
    });

    await FirebaseFirestore.instance
        .collection('review')
        .doc(documentId)
        .delete();
    await _fetchFeedbackData(); // Refresh the feedback list

    setState(() {
      _isDeleting = false; // Hide deleting indicator
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                        _filterFeedback();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Search Feedback',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter by Rating
                  DropdownButtonFormField<int>(
                    value: _selectedRating,
                    hint: const Text('Filter by Rating'),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('All Ratings'),
                      ),
                      ...[1, 2, 3, 4, 5].map((rating) => DropdownMenuItem<int>(
                            value: rating,
                            child: Text('$rating Stars'),
                          ))
                    ].toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRating = value;
                        _filterFeedback();
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Feedback List
                  Expanded(
                    child: _isDeleting
                        ? Center(
                            child:
                                CircularProgressIndicator()) // Show deleting indicator
                        : ListView.builder(
                            itemCount: _filteredFeedbackList.length,
                            itemBuilder: (context, index) {
                              final feedback = _filteredFeedbackList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 4,
                                child: ListTile(
                                  title: Text(
                                      '${feedback.user} (${feedback.email})'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(feedback.feedbackText),
                                      Text(
                                        'Rating: ${feedback.rating} Stars',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Date: ${DateFormat('yyyy-MM-dd – kk:mm').format(feedback.date)}',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      _deleteFeedback(
                                          feedback.id); // Use document ID
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
}
