import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  double _rating = 3.0; // Default rating
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to submit the review
  Future<void> _submitReview() async {
    // Get current user details
    final User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Add the review to Firestore
        await FirebaseFirestore.instance.collection('review').add({
          'userId': user.uid, // User ID
          'rating': _rating, // Rating value
          'text': _feedbackController.text, // Feedback text
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Clear the fields after submission
        _feedbackController.clear();
        setState(() {
          _rating = 3.0; // Reset the rating
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to submit review. Please try again.')),
        );
      }
    } else {
      // If user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to submit a review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Rate your experience',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Rating Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            // Feedback Text Area
            const Text(
              'Leave a feedback:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your feedback here...',
              ),
            ),
            const SizedBox(height: 20),
            // Submit Button
            ElevatedButton(
              onPressed: _submitReview,
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
