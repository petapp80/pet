import 'package:flutter/material.dart';

// A model class to hold feedback data
class Feedback {
  final String user;
  final String feedbackText;
  final int rating;
  final DateTime date;

  Feedback({
    required this.user,
    required this.feedbackText,
    required this.rating,
    required this.date,
  });
}

class Feedbackscreen extends StatefulWidget {
  const Feedbackscreen({super.key});

  @override
  State<Feedbackscreen> createState() => _FeedbackscreenState();
}

class _FeedbackscreenState extends State<Feedbackscreen> {
  // Sample feedback list
  final List<Feedback> _feedbackList = [
    Feedback(
      user: 'User 1',
      feedbackText: 'Great app!',
      rating: 5,
      date: DateTime(2024, 10, 1),
    ),
    Feedback(
      user: 'User 2',
      feedbackText: 'Needs improvement.',
      rating: 3,
      date: DateTime(2024, 11, 10),
    ),
    Feedback(
      user: 'User 3',
      feedbackText: 'Awesome experience!',
      rating: 4,
      date: DateTime(2024, 9, 15),
    ),
    Feedback(
      user: 'User 4',
      feedbackText: 'Good, but could be faster.',
      rating: 3,
      date: DateTime(2024, 8, 20),
    ),
    Feedback(
      user: 'User 5',
      feedbackText: 'Amazing features!',
      rating: 5,
      date: DateTime(2024, 7, 25),
    ),
  ];

  List<Feedback> _filteredFeedbackList = [];
  String _searchText = '';
  int? _selectedRating;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _filteredFeedbackList = _feedbackList;
  }

  // Filter feedback based on the search, rating, and date range
  void _filterFeedback() {
    setState(() {
      _filteredFeedbackList = _feedbackList.where((feedback) {
        bool matchesSearch = feedback.feedbackText
            .toLowerCase()
            .contains(_searchText.toLowerCase());
        bool matchesRating = _selectedRating == null;
        feedback.rating == _selectedRating;
        bool matchesDate = _selectedDateRange == null;
        (feedback.date.isAfter(_selectedDateRange!.start) &&
            feedback.date.isBefore(_selectedDateRange!.end));
        return matchesSearch && matchesRating && matchesDate;
      }).toList();
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
        child: Column(
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
              items: [1, 2, 3, 4, 5]
                  .map((rating) => DropdownMenuItem<int>(
                        value: rating,
                        child: Text('$rating Stars'),
                      ))
                  .toList(),
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
            // Filter by Date Range
            TextButton(
              onPressed: () async {
                final DateTimeRange? picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                  initialDateRange: _selectedDateRange,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: Colors.blue,
                        hintColor: const Color.fromARGB(255, 32, 224, 102),
                        buttonTheme: const ButtonThemeData(
                            textTheme: ButtonTextTheme.primary),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != _selectedDateRange) {
                  setState(() {
                    _selectedDateRange = picked;
                    _filterFeedback();
                  });
                }
              },
              child: Text(
                _selectedDateRange == null
                    ? 'Filter by Date '
                    : 'Selected Date: ${_selectedDateRange!.start.toLocal()} - ${_selectedDateRange!.end.toLocal()}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),

            // Display Feedback List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredFeedbackList.length,
                itemBuilder: (context, index) {
                  final feedback = _filteredFeedbackList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      title: Text(feedback.user),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(feedback.feedbackText),
                          Text(
                            'Rating: ${feedback.rating} Stars',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Date: ${feedback.date.toLocal()}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
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
