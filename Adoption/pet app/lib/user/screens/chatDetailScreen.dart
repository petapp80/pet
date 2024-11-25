import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // For File

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String image;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.image,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  // To store the selected file path
  String? _filePath;

  // Function to handle attachment action
  Future<void> _pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'heic'], // Allow only specific formats
    );

    if (result != null) {
      // Get the file path
      String? filePath = result.files.single.path;

      setState(() {
        _filePath = filePath;
      });

      // Show snack bar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected file: ${filePath?.split('/').last}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File selection canceled.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Function to clear the selected image
  void _clearSelectedImage() {
    setState(() {
      _filePath = null; // Clear the selected file path
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Adjust screen when keyboard is shown or Snackbar appears
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.image),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Text(widget.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: const [
                // Example of chat messages (add more if needed)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hello!',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Hi there!',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chatbox with attachment icon and send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _pickFile(context), // Open file picker
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Handle send action
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          if (_filePath != null) // Display selected image for sending
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  // Display the selected image
                  Image.file(
                    File(_filePath!), // Display the selected image
                    height: 100, // Adjust as needed
                    width: 100, // Adjust as needed
                    fit: BoxFit.cover,
                  ),
                  // Close button to remove the image selection
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed:
                          _clearSelectedImage, // Clear the selected image
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
