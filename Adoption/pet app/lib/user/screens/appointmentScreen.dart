import 'package:flutter/material.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  // Sample appointment data with more detailed user information
  final List<Map<String, dynamic>> _appointments = [
    {
      'time': '9:00 AM',
      'patientName': 'John Doe',
      'petName': 'Buddy',
      'petType': 'Dog',
      'reason': 'Vaccination',
      'status': 'Confirmed',
    },
    {
      'time': '10:00 AM',
      'patientName': 'Jane Smith',
      'petName': 'Whiskers',
      'petType': 'Cat',
      'reason': 'Routine Checkup',
      'status': 'Pending',
    },
    {
      'time': '11:30 AM',
      'patientName': 'Chris Johnson',
      'petName': 'Goldie',
      'petType': 'Fish',
      'reason': 'Water Quality Issue',
      'status': 'Completed',
    },
  ];

  // Function to view appointment details
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
            Text("Pet Type: ${appointment['petType']}"),
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
                          Text(
                              "Pet: ${appointment['petName']} (${appointment['petType']})"),
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
    );
  }
}
