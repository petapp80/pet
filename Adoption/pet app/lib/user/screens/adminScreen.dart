import 'package:flutter/material.dart';

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
            // List of labels for the boxes
            final titles = [
              'Newly Registered',
              'Sales',
              'Feedback',
              'User Search',
              'Notification',
              'Give Update'
            ];

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () {
                  // Add functionality for when each box is tapped
                  print('${titles[index]} clicked');
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
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
