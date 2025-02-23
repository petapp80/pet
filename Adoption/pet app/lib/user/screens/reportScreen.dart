import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Future<void> _deleteReport(
      String userId, String collection, String docId) async {
    // Deleting from the user's subcollection
    String subcollection;
    if (collection == 'pets') {
      subcollection = 'pets';
    } else if (collection == 'products') {
      subcollection = 'products';
    } else {
      subcollection = 'Veterinary';
    }

    // Delete from user's subcollection
    await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection(subcollection)
        .doc(docId)
        .delete();

    // Delete from outside collection
    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();

    // Delete from Reports collection
    await FirebaseFirestore.instance.collection('Reports').doc(docId).delete();
  }

  Future<void> _removeFromReports(String docId) async {
    // Delete from Reports collection only
    await FirebaseFirestore.instance.collection('Reports').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching reports'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reports found'));
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.red.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (report['image'] != null && report['image'].isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Image.network(
                          report['image'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report['text'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report['description'] ?? 'No description',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Location: ${report['location'] ?? 'Unknown location'}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Published: ${report['published'] ?? 'Unknown date'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: report['profileImage'] !=
                                            null &&
                                        report['profileImage'].isNotEmpty
                                    ? NetworkImage(report['profileImage'])
                                    : const AssetImage(
                                            'asset/image/default_profile.png')
                                        as ImageProvider,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                report['profileName'] ?? 'Unknown user',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () async {
                                  await _deleteReport(report['userId'],
                                      report['collection'], reports[index].id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Report and associated document deleted'),
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await _removeFromReports(reports[index].id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Document removed from Reports collection'),
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.check, color: Colors.blue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
