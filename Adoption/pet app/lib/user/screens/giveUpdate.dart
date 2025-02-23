import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class GiveUpdate extends StatefulWidget {
  const GiveUpdate({super.key});

  @override
  State<GiveUpdate> createState() => _GiveUpdateState();
}

class _GiveUpdateState extends State<GiveUpdate> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _articleController = TextEditingController();
  final List<Map<String, String>> _articleParts = [];
  File? _selectedImage;
  bool _isUploading = false;
  bool _isLoadingImage = false;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  Future<String?> _uploadImage(File image) async {
    final cloudName = 'db3cpgdwm'; // Replace with your Cloudinary cloud name
    final preset = 'article_preset'; // Replace with your upload preset
    final apiKey = '545187993373729'; // Replace with your Cloudinary API key
    final apiSecret =
        'gdgWv-rubTrQTMn6KG0T7-Q5Cfw'; // Replace with your Cloudinary API secret

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Generate the signature
    final bytes =
        utf8.encode('timestamp=$timestamp&upload_preset=$preset$apiSecret');
    final signature = sha1.convert(bytes).toString();

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..fields['api_key'] = apiKey
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      final imageUrl = jsonResponse['secure_url'];
      return imageUrl;
    } else {
      print('Upload failed with status ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
      return null;
    }
  }

  void _removeImage(int index) {
    setState(() {
      _articleParts.removeAt(index);
    });
  }

  void _addText() {
    final text = _articleController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _articleParts.add({'type': 'text', 'content': text});
        _articleController.clear();
      });
    }
  }

  Future<void> _publishArticle() async {
    if (_titleController.text.isEmpty ||
        _summaryController.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title, summary, and main image are mandatory')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Upload main image
    String? mainImageUrl;
    if (_selectedImage != null) {
      mainImageUrl = await _uploadImage(_selectedImage!);
      if (mainImageUrl == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }
    }

    // Ensure all images in article are local paths before uploading
    for (var part in _articleParts) {
      if (part['type'] == 'image' && !part['content']!.startsWith('http')) {
        final imageUrl = await _uploadImage(File(part['content']!));
        if (imageUrl != null) {
          part['content'] = imageUrl;
        } else {
          setState(() {
            _isUploading = false;
          });
          return;
        }
      }
    }

    // Store article in Firestore
    await FirebaseFirestore.instance.collection('articles').add({
      'title': _titleController.text,
      'summary': _summaryController.text,
      'image': mainImageUrl,
      'content': _articleParts,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article published successfully!')),
    );

    // Clear the form
    setState(() {
      _titleController.clear();
      _summaryController.clear();
      _articleController.clear();
      _articleParts.clear();
      _selectedImage = null;
      _isUploading = false;
    });
  }

  Future<void> _pickAndUploadImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _isLoadingImage = true;
      });
      final imageUrl = await _uploadImage(File(result.files.single.path!));
      setState(() {
        _isLoadingImage = false;
        if (imageUrl != null) {
          _articleParts.add({'type': 'image', 'content': imageUrl});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Update'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Title field
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary field
                  TextField(
                    controller: _summaryController,
                    decoration: const InputDecoration(
                      labelText: 'Summary',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main image
                  _selectedImage == null
                      ? ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Select Main Image'),
                        )
                      : Column(
                          children: [
                            Image.file(_selectedImage!),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: const Text('Remove Image',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            TextButton(
                              onPressed: _pickImage,
                              child: const Text('Replace Image',
                                  style: TextStyle(color: Colors.blue)),
                            ),
                          ],
                        ),

                  const SizedBox(height: 16),

                  // Article writing section
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _articleParts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _articleParts.length) {
                        return TextField(
                          controller: _articleController,
                          decoration: const InputDecoration(
                            labelText: 'Continue writing...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                        );
                      }

                      final part = _articleParts[index];
                      if (part['type'] == 'text') {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            part['content']!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      } else if (part['type'] == 'image') {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Stack(
                            children: [
                              Image.network(part['content']!),
                              Positioned(
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () => _removeImage(index),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Add image button
                        IconButton(
                          icon: const Icon(Icons.image, color: Colors.blue),
                          onPressed: _pickAndUploadImage,
                        ),
                        // Add text button
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.blue),
                          onPressed: _addText,
                        ),
                        // Publish button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _publishArticle,
                            child: const Text('Publish'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_isLoadingImage)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
