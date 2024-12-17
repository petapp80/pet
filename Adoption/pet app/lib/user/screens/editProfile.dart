import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  String? _selectedProfileImagePath;
  String? _name;
  String? _existingProfileImageUrl;
  String? _existingProfileImagePublicId;

  bool _isSaveButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        final data = userDoc.data()!;
        _existingProfileImageUrl = data['profileImage'] as String?;
        _existingProfileImagePublicId = data['profileImagePublicId'] as String?;
        _name = data['name'] as String?;
      });
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _selectedProfileImagePath = result.files.single.path;
        _isSaveButtonEnabled =
            true; // Enable the save button when image is selected
      });
    }
  }

  void _cancelImageSelection() {
    setState(() {
      _selectedProfileImagePath = null;
      _isSaveButtonEnabled =
          _name != null; // Enable the button if name is present
    });
  }

  Future<Map<String, dynamic>?> _uploadToCloudinary(File imageFile) async {
    try {
      const cloudName = 'db3cpgdwm';
      const uploadPreset = 'pet_preset';
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'public'; // Specify the public asset folder
      request.fields['resource_type'] = 'image';

      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final jsonResponse = json.decode(String.fromCharCodes(responseData));

      if (response.statusCode == 200) {
        print("Upload successful: $jsonResponse");
        return jsonResponse;
      } else {
        print("Error uploading image: ${response.statusCode}");
        print("Response Data: ${String.fromCharCodes(responseData)}");
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      String? newImageUrl;
      String? newImagePublicId;

      // Upload new image if selected
      if (_selectedProfileImagePath != null) {
        final uploadResponse =
            await _uploadToCloudinary(File(_selectedProfileImagePath!));
        if (uploadResponse != null) {
          newImageUrl = uploadResponse['secure_url'];
          newImagePublicId = uploadResponse['public_id'];
          print("Image uploaded: $newImageUrl");
        }
      }

      // Prepare data for Firestore update
      final updateData = <String, dynamic>{};
      if (_name != null) updateData['name'] = _name; // Update name if provided
      if (newImageUrl != null) {
        updateData['profileImage'] = newImageUrl;
        updateData['profileImagePublicId'] = newImagePublicId;
      }

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .update(updateData);
      print("Firestore updated with: $updateData");

      // If old image exists and a new one was uploaded, delete the old image from Cloudinary
      if (_existingProfileImagePublicId != null && newImagePublicId != null) {
        await _deleteOldCloudinaryImage(_existingProfileImagePublicId!);
      }

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (error) {
      print('Error updating profile: $error');
    }
  }

  Future<void> _deleteOldCloudinaryImage(String publicId) async {
    try {
      const cloudName = 'db3cpgdwm';
      const apiKey = '545187993373729';
      const apiSecret = 'gdgWv-rubTrQTMn6KG0T7-Q5Cfw';
      final authHeader = base64Encode(utf8.encode('$apiKey:$apiSecret'));

      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Basic $authHeader'},
        body: {'public_id': publicId},
      );

      if (response.statusCode == 200) {
        print('Old image deleted successfully');
      } else {
        print('Failed to delete old image: ${response.body}');
      }
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _selectedProfileImagePath != null
                      ? FileImage(File(_selectedProfileImagePath!))
                      : (_existingProfileImageUrl != null
                              ? NetworkImage(_existingProfileImageUrl!)
                              : const AssetImage('asset/image/care.jpg'))
                          as ImageProvider,
                ),
                if (_selectedProfileImagePath != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _cancelImageSelection,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _pickImage,
              child: const Text('Select Image'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: _name),
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                setState(() {
                  _name = value.isNotEmpty ? value : null;
                  _isSaveButtonEnabled = true;
                });
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaveButtonEnabled ? _updateProfile : null,
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor:
                    _isSaveButtonEnabled ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}