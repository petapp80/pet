import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class GiveUpdate extends StatefulWidget {
  const GiveUpdate({super.key});

  @override
  State<GiveUpdate> createState() => _GiveUpdateState();
}

class _GiveUpdateState extends State<GiveUpdate> {
  final TextEditingController _textController = TextEditingController();
  List<dynamic> messageParts = []; // Holds text and image paths alternately

  // Function to add text
  void _addText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        messageParts.add({'type': 'text', 'content': text});
        _textController.clear();
      });
    }
  }

  // Function to add an image
  Future<void> _addImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      final imagePath = result.files.single.path!;
      setState(() {
        messageParts.add({'type': 'image', 'content': imagePath});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  // Function to send the message
  void _sendMessage() {
    if (messageParts.isNotEmpty) {
      // For demonstration, we'll print the message parts
      print('Message sent: $messageParts');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully!')),
      );

      // Clear the message parts
      setState(() {
        messageParts.clear();
        _textController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send an empty message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Update'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: messageParts.length,
              itemBuilder: (context, index) {
                final part = messageParts[index];
                if (part['type'] == 'text') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      part['content'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                } else if (part['type'] == 'image') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Image.file(
                      File(part['content']),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Add image button
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: _addImage,
                ),
                // Text input field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // Add text button
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: _addText,
                ),
                // Send button
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
