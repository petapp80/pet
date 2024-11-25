import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/giveUpdate.dart';
import 'newlyRegistered.dart';
import 'notificationScreen.dart'; // Import the Notification page
import 'salesScreen.dart'; // Import other pages as needed
import 'feedbackScreen.dart';
import 'userSearch.dart'; // Import other pages as needed

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 boxes in each row
            crossAxisSpacing: 16, // Space between boxes
            mainAxisSpacing: 16, // Space between boxes vertically
            childAspectRatio: 1.0, // Adjusted Aspect ratio to prevent overflow
          ),
          itemCount: 6, // Total number of boxes
          itemBuilder: (context, index) {
            // List of titles for the boxes
            final titles = [
              'Newly Registered',
              'Sales',
              'Feedback',
              'User Search',
              'Notification',
              'Give Update'
            ];

            // List of corresponding pages to navigate to
            final pages = [
              const NewlyRegistered(), // Newly Registered, no page
              const SalesScreen(), // Sales page
              const Feedbackscreen(),
              const UserSearch(), // User Search, no page for now
              const NotificationScreen(), // Notification page
              const GiveUpdate(), // Give Update, no page for now
            ];

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () {
                  // If a page is specified for the tile, navigate to it
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => pages[index]),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.dashboard,
                        size: 40,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        titles[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
