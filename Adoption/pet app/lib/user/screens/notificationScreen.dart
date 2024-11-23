import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import the file_picker package

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _controller = TextEditingController();
  late String _message;

  // Function to pick an image from the gallery using file_picker
  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      // Get the file path
      String? filePath = result.files.single.path;
      if (filePath != null) {
        // Handle the selected file (e.g., display it, upload it, etc.)
        print('Selected File: $filePath');
      }
    } else {
      // User canceled the picker
      print('No file selected');
    }
  }

  // Function to handle sending the message
  void _sendMessage() {
    setState(() {
      _message = _controller.text;
      // Do something with the message, like sending it to a server or chat
      print("Message sent: $_message");
      _controller.clear(); // Clear the input field after sending
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Message Box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // File upload button using FilePicker
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFile,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Send Button
            ElevatedButton(
              onPressed: _sendMessage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
