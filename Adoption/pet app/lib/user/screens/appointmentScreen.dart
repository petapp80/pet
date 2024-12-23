import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isBlocked = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _checkAvailability();
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
      List<dynamic> customerInfo = doc.data()['customerInfo'] ?? [];
      for (var info in customerInfo) {
        final customerId = info['customerId'];
        final customerDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(customerId)
            .get();
        if (customerDoc.exists) {
          final customerName = customerDoc.data()?['name'] ?? 'Unknown';
          appointments.add({
            'time': info['time'] ?? 'Unknown', // Get time from the field time
            'patientName': customerName,
            'petName': info['petItem'] ?? 'Unknown',
            'reason':
                'Appointment', // Placeholder reason, replace with actual if available
            'status':
                'Confirmed', // Placeholder status, replace with actual if available
          });
        }
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
        await userDocRef.update({
          'availability': FieldValue.delete(),
        });
        await vetDocRefNested.update({
          'availability': FieldValue.delete(),
        });

        if (vetExternalExists) {
          await vetDocsExternal.docs.first.reference.update({
            'availability': FieldValue.delete(),
          });
        }
      } else {
        await userDocRef.update({
          'availability': 'blocked',
        });
        await vetDocRefNested.update({
          'availability': 'blocked',
        });

        if (vetExternalExists) {
          await vetDocsExternal.docs.first.reference.update({
            'availability': 'blocked',
          });
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

  void _viewAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Appointment Details - ${appointment['time']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient Name: ${appointment['patientName']}"),
            Text("Pet Name: ${appointment['petName']}"),
            Text("Reason: ${appointment['reason']}"),
            Text("Status: ${appointment['status']}"),
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
              child: ListView.builder(
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        appointment['status'] == 'Confirmed'
                            ? Icons.check_circle
                            : appointment['status'] == 'Pending'
                                ? Icons.hourglass_empty
                                : Icons.done,
                        color: appointment['status'] == 'Confirmed'
                            ? Colors.green
                            : appointment['status'] == 'Pending'
                                ? Colors.orange
                                : Colors.grey,
                      ),
                      title: Text("Time: ${appointment['time']}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Patient: ${appointment['patientName']}"),
                          Text("Pet: ${appointment['petName']}"),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () {
                          _viewAppointmentDetails(appointment);
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
