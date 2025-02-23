import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatDetailScreen.dart'; // Import the ChatDetailScreen
import 'package:cron/cron.dart'; // Import the cron package

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  List<Map<String, dynamic>> _appointments = []; // Define _appointments
  Stream<QuerySnapshot>? _appointmentsStream;
  bool _isBlocked = false;
  bool _isUpdating = false;
  final cron = Cron();
  String? place; // Added place to store the selected place

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _checkAvailability();
    _initializeAppointmentStream();
    _scheduleMidnightDeletion();
  }

  Future<void> _fetchAppointments() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final customerSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('customers')
        .get();

    List<Map<String, dynamic>> appointments = [];

    for (var doc in customerSnapshot.docs) {
      final data = doc.data();
      final customerId = data['customerId'] as String;
      final itemId = data['id'] as String;
      final status = data['status'] as String;
      final typeOfPet = data['type of pet'] as String? ??
          'Unknown'; // Provide a default value
      final place = data['place'] as String?; // Retrieve the selected place

      final customerDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(customerId)
          .get();
      if (customerDoc.exists) {
        final customerName = customerDoc.data()?['name'] ?? 'Unknown';
        appointments.add({
          'customerId': customerId,
          'itemId': itemId,
          'patientName': customerName,
          'petType': typeOfPet,
          'status': status,
          'place': place, // Add place to the appointment data
        });
      }
    }

    setState(() {
      _appointments = appointments;
    });
  }

  Future<void> _checkAvailability() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    final vetDocNested = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('Veterinary')
        .doc(userId)
        .get();

    QuerySnapshot vetDocsExternal = await FirebaseFirestore.instance
        .collection('Veterinary')
        .where('userId', isEqualTo: userId)
        .get();

    bool vetExternalExists = vetDocsExternal.docs.isNotEmpty;

    if (userDoc.exists && (vetDocNested.exists || vetExternalExists)) {
      setState(() {
        _isBlocked = (vetDocNested.data()?['availability'] ?? 'unblocked') ==
                'blocked' ||
            (vetExternalExists
                    ? (vetDocsExternal.docs.first.data()
                            as Map<String, dynamic>)['availability'] ??
                        'unblocked'
                    : 'unblocked') ==
                'blocked' ||
            (userDoc.data()?['availability'] ?? 'unblocked') == 'blocked';
      });
    }
  }

  Future<void> _toggleAvailability() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('user').doc(userId);
      final vetDocRefNested = userDocRef.collection('Veterinary').doc(userId);
      QuerySnapshot vetDocsExternal = await FirebaseFirestore.instance
          .collection('Veterinary')
          .where('userId', isEqualTo: userId)
          .get();

      // Create the documents if they do not exist
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        await userDocRef.set({'availability': 'unblocked'});
      }

      final vetDocNested = await vetDocRefNested.get();
      if (!vetDocNested.exists) {
        await vetDocRefNested.set({'availability': 'unblocked'});
      }

      bool vetExternalExists = vetDocsExternal.docs.isNotEmpty;
      if (!vetExternalExists) {
        await FirebaseFirestore.instance
            .collection('Veterinary')
            .add({'userId': userId, 'availability': 'unblocked'});
      }

      if (_isBlocked) {
        await userDocRef.update({'availability': FieldValue.delete()});
        await vetDocRefNested.update({'availability': FieldValue.delete()});

        if (vetExternalExists) {
          await vetDocsExternal.docs.first.reference
              .update({'availability': FieldValue.delete()});
        }
      } else {
        await userDocRef.update({'availability': 'blocked'});
        await vetDocRefNested.update({'availability': 'blocked'});

        if (vetExternalExists) {
          await vetDocsExternal.docs.first.reference
              .update({'availability': 'blocked'});
        }
      }

      setState(() {
        _isBlocked = !_isBlocked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isBlocked ? 'Appointments blocked' : 'Appointments unblocked'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error updating availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update availability: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _initializeAppointmentStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _appointmentsStream = FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('customers')
            .snapshots();
      });
    }
  }

  Future<void> _updateStatusToCompleted(
      String customerId, String itemId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final customersCollection = FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('customers');

      final customerQuerySnapshot = await customersCollection
          .where('customerId', isEqualTo: customerId)
          .where('id', isEqualTo: itemId)
          .get();

      if (customerQuerySnapshot.docs.isEmpty) {
        print(
            'Customer document not found for itemId: $itemId and customerId: $customerId');
        return;
      }

      final customerDocRef = customerQuerySnapshot.docs.first.reference;
      final cartListDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(customerId)
          .collection('CartList')
          .doc(itemId);

      final cartListSnapshot = await cartListDocRef.get();
      if (!cartListSnapshot.exists) {
        print('CartList document not found for itemId: $itemId');
        return;
      }

      await customerDocRef.update({'status': 'completed'});
      await cartListDocRef.update({'status': 'completed'});
      print('Status updated to completed for itemId: $itemId');
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _scheduleMidnightDeletion() {
    cron.schedule(Schedule.parse('0 0 * * *'), () async {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final customersCollection = FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('customers');

      final snapshot = await customersCollection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    });
  }

  Future<String> _getPatientName(String customerId) async {
    final customerDoc = await FirebaseFirestore.instance
        .collection('user')
        .doc(customerId)
        .get();
    return customerDoc.data()?['name']?.toString() ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _appointmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text('Error loading appointments');
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No appointments found');
                  } else {
                    final appointments = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointmentData =
                            appointments[index].data() as Map<String, dynamic>;
                        final customerId =
                            appointmentData['customerId'] as String;
                        final itemId = appointmentData['id'] as String;
                        final petType =
                            appointmentData['type of pet'] as String? ??
                                'Unknown';
                        final status = appointmentData['status'] as String;
                        final place =
                            appointmentData['place'] as String? ?? 'Unknown';

                        return FutureBuilder<String>(
                          future: _getPatientName(customerId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const ListTile(
                                title: Text('Loading...'),
                              );
                            } else if (snapshot.hasError) {
                              return const ListTile(
                                title: Text('Error loading patient details'),
                              );
                            } else {
                              final patientName = snapshot.data ?? 'Unknown';
                              return AppointmentTile(
                                patientName: patientName,
                                petType: petType,
                                status: status,
                                place: place,
                                customerId: customerId,
                                itemId: itemId,
                                onComplete: () async {
                                  await _updateStatusToCompleted(
                                      customerId, itemId);
                                },
                              );
                            }
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAvailability,
        child: _isUpdating
            ? const CircularProgressIndicator(color: Colors.white)
            : Icon(_isBlocked ? Icons.lock_open : Icons.lock),
        tooltip: _isBlocked ? 'Unblock Appointments' : 'Block Appointments',
      ),
    );
  }
}

class AppointmentTile extends StatelessWidget {
  final String patientName;
  final String petType;
  final String status;
  final String place; // Updated to use place
  final String customerId;
  final String itemId;
  final VoidCallback onComplete;

  const AppointmentTile({
    required this.patientName,
    required this.petType,
    required this.status,
    required this.place, // Updated to use place
    required this.customerId,
    required this.itemId,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          status != 'completed' ? Icons.pending : Icons.check_circle,
          color: status == 'completed' ? Colors.green : Colors.orange,
        ),
        title: Text("Patient: $patientName"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pet: $petType"),
            Text("Place: $place"), // Display place
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != 'completed')
              IconButton(
                icon: const Icon(Icons.check_circle),
                color: Colors.orange,
                onPressed: onComplete,
              ),
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      name: patientName,
                      image:
                          'assets/image/default_profile.png', // Provide a default image or fetch from Firestore if available
                      navigationSource: 'VeterinaryScreen',
                      userId: customerId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
