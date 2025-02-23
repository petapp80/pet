import 'package:flutter/material.dart';
import 'package:PetApp/user/screens/giveUpdate.dart';
import 'login screen.dart';
import 'newlyRegistered.dart';
import 'salesScreen.dart'; // Import other pages as needed
import 'feedbackScreen.dart';
import 'approveScreen.dart'; // Import the ApproveScreen
import 'reportScreen.dart'; // Import the ReportScreen

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
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 boxes in each row
                  crossAxisSpacing: 16, // Space between boxes
                  mainAxisSpacing: 16, // Space between boxes vertically
                  childAspectRatio:
                      1.0, // Adjusted Aspect ratio to prevent overflow
                ),
                itemCount: 6, // Total number of boxes updated to 6
                itemBuilder: (context, index) {
                  // List of titles for the boxes
                  final titles = [
                    'Newly Registered',
                    'Sales',
                    'Feedback',
                    'Pet Care Tip',
                    'Approve', // Added Approve tile
                    'Reports' // Added Reports tile
                  ];

                  // List of corresponding pages to navigate to
                  final pages = [
                    const NewlyRegistered(), // Newly Registered page
                    const SalesScreen(), // Sales page
                    const FeedbackScreen(), // Feedback page
                    const GiveUpdate(), // Give Update page
                    const ApproveScreen(), // Approve page
                    const ReportScreen(), // Report page
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
