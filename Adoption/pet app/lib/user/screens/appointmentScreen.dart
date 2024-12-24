import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatDetailScreen.dart'; // Import the ChatDetailScreen

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  Stream<QuerySnapshot>? _appointmentsStream;
  bool _isBlocked = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
    _initializeAppointmentStream();
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
                        final customerInfoArray =
                            appointmentData['customerInfo'] as List<dynamic>?;
                        if (customerInfoArray == null ||
                            customerInfoArray.isEmpty) {
                          return const ListTile(
                            title: Text('No customer info found'),
                          );
                        }

                        final customerInfo =
                            customerInfoArray[0] as Map<String, dynamic>;
                        final customerId =
                            customerInfo['customerId'] as String?;
                        final petType =
                            customerInfo['type of pet'] as String? ?? 'Unknown';

                        if (customerId == null) {
                          return const ListTile(
                            title: Text('Customer ID not found'),
                          );
                        }

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
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  title: Text("Patient: $patientName"),
                                  subtitle: Text("Pet: $petType"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.message),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChatDetailScreen(
                                            name: patientName,
                                            image:
                                                'asset/image/default_profile.png', // Provide a default image or fetch from Firestore if available
                                            navigationSource:
                                                'VeterineryScreen',
                                            userId: customerId!,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
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

  void _viewAppointmentDetails(Map<String, dynamic> appointment) async {
    final patientName = await _getPatientName(appointment['customerId']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Appointment Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient Name: $patientName"),
            Text("Pet Type: ${appointment['type of pet'] ?? 'Unknown'}"),
            Text("Status: ${appointment['status'] ?? 'Unknown'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
