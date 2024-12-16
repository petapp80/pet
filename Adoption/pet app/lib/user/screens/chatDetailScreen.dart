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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Adjust screen when keyboard is shown or Snackbar appears
      appBar: AppBar(
        backgroundColor: isDark
            ? Colors.black
            : Colors.blue, // Change AppBar color based on theme
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
            Text(
              widget.name,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Example of chat messages (add more if needed)
                _buildChatBubble(
                  message: 'Hello!',
                  isSender: false,
                  isDark: isDark,
                ),
                _buildChatBubble(
                  message: 'Hi there!',
                  isSender: true,
                  isDark: isDark,
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
                  icon: Icon(
                    Icons.attach_file,
                    color: isDark ? Colors.grey[400] : Colors.grey[800],
                  ),
                ),
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[200], // Input background
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Handle send action
                  },
                  icon: Icon(
                    Icons.send,
                    color: theme.colorScheme.primary,
                  ),
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

  // Helper function to build chat bubbles dynamically
  Widget _buildChatBubble({
    required String message,
    required bool isSender,
    required bool isDark,
  }) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSender
              ? (isDark ? Colors.blue[700] : Colors.blue[300]) // Sender bubble
              : (isDark
                  ? Colors.grey[800]
                  : Colors.grey[200]), // Receiver bubble
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
