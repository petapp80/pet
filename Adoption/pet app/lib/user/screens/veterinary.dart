import 'package:flutter/material.dart';

class VeterinaryScreen extends StatefulWidget {
  const VeterinaryScreen({super.key});

  @override
  State<VeterinaryScreen> createState() => _VeterinaryScreenState();
}

class _VeterinaryScreenState extends State<VeterinaryScreen> {
  // Mock list of veterinarians
  final List<Map<String, String>> veterinarians = [
    {
      'name': 'Dr. Emily Johnson',
      'hospital': 'Happy Paws Veterinary Clinic',
      'contact': 'emily.johnson@happypaws.com',
    },
    {
      'name': 'Dr. Michael Smith',
      'hospital': 'Purrfect Care Animal Hospital',
      'contact': 'michael.smith@purrfectcare.com',
    },
    {
      'name': 'Dr. Sarah Wilson',
      'hospital': 'Furry Friends Vet Center',
      'contact': 'sarah.wilson@furryfriends.com',
    },
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Veterinarians'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Search bar for filtering veterinarians
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                hintText: 'Search veterinarians...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
              ),
            ),
          ),
          // Filtered list based on search query
          Expanded(
            child: ListView.builder(
              itemCount: veterinarians.length,
              itemBuilder: (context, index) {
                final vet = veterinarians[index];
                if (searchQuery.isNotEmpty &&
                    !vet['name']!.toLowerCase().contains(searchQuery) &&
                    !vet['hospital']!.toLowerCase().contains(searchQuery)) {
                  return const SizedBox.shrink();
                }
                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      vet['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text('Hospital: ${vet['hospital']}'),
                    onTap: () {
                      // Navigate to Doctor Details Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailsScreen(
                            doctorDetails: vet,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorDetailsScreen extends StatelessWidget {
  final Map<String, String> doctorDetails;

  const DoctorDetailsScreen({super.key, required this.doctorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details - ${doctorDetails['name']}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hospital: ${doctorDetails['hospital']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Contact: ${doctorDetails['contact']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Message Form
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageFormScreen(
                      doctorDetails: doctorDetails,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Message Doctor'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigate to Appointment Booking Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentScreen(
                      doctorDetails: doctorDetails,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageFormScreen extends StatelessWidget {
  final Map<String, String> doctorDetails;

  const MessageFormScreen({super.key, required this.doctorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message ${doctorDetails['name']}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send a Message:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Mock sending message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message sent to ${doctorDetails['name']}!'),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentScreen extends StatelessWidget {
  final Map<String, String> doctorDetails;

  const AppointmentScreen({super.key, required this.doctorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment with ${doctorDetails['name']}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Select Date and Time:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Pick a date (e.g., 2024-01-01)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Pick a time (e.g., 10:00 AM)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Mock appointment booking
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Appointment booked with ${doctorDetails['name']}!'),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Confirm Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}
