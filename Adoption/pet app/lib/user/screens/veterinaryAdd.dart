import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'home.dart';

class VeterinaryAddScreen extends StatefulWidget {
  final String fromScreen;
  const VeterinaryAddScreen({required this.fromScreen, super.key});
  @override
  State<VeterinaryAddScreen> createState() => _VeterinaryAddScreenState();
}

class _VeterinaryAddScreenState extends State<VeterinaryAddScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _appointmentsController = TextEditingController();
  final TextEditingController _placesController = TextEditingController();
  String _selectedCurrency = 'USD';
  File? _image;
  File? _licenseCertificate;
  String? _existingImageUrl;
  String? _existingLicenseCertificateUrl;
  String? _existingImagePublicId;
  String? _existingLicenseCertificatePublicId;
  String? _profileId;
  bool _isLoading = true;
  bool _approved = false;
  List<String> _places = [];

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
    _scheduleDailyReset();
    _placesController.addListener(() {
      if (_placesController.text.endsWith(',')) {
        setState(() {
          _places.add(_placesController.text.trim().replaceAll(',', ''));
          _placesController.clear();
        });
      }
    });
  }

  Future<void> _checkExistingProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('Veterinary')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final profileData = snapshot.docs.first.data();
        _profileId = snapshot.docs.first.id;
        _nameController.text = profileData['name'];
        _locationController.text = profileData['location'];
        _experienceController.text = profileData['experience'];
        _aboutController.text = profileData['about'];
        _priceController.text = profileData['price'].toString().split(' ')[1];
        _selectedCurrency = profileData['price'].toString().split(' ')[0];
        _appointmentsController.text =
            (profileData['appointments'] ?? '').toString();
        _places =
            (profileData['places'] as List<dynamic>?)?.cast<String>() ?? [];
        _existingImageUrl = profileData['imageUrl'];
        _existingImagePublicId = profileData['imagePublicId'];
        _existingLicenseCertificateUrl = profileData['licenseCertificateUrl'];
        _existingLicenseCertificatePublicId =
            profileData['licenseCertificatePublicId'];
        _approved = profileData['approved'] ?? false;
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _scheduleDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final midnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final durationUntilMidnight = midnight.difference(now);
    Timer(durationUntilMidnight, () {
      _resetAppointments();
      Timer.periodic(const Duration(days: 1), (timer) {
        _resetAppointments();
      });
    });
  }

  Future<void> _resetAppointments() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final profileDocRef = FirebaseFirestore.instance
        .collection('Veterinary')
        .doc(_profileId ?? userId);
    await profileDocRef.update({'appointments': '0'});
    final userProfileDocRef = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('Veterinary')
        .doc(_profileId ?? userId);
    await userProfileDocRef.update({'appointments': '0'});
    print("Appointments reset at midnight");
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'heic'],
    );
    if (result != null) {
      setState(() {
        _image = File(result.files.single.path!);
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _pickLicenseCertificate() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null) {
      setState(() {
        _licenseCertificate = File(result.files.single.path!);
        _existingLicenseCertificateUrl = null;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _existingImageUrl = null;
    });
  }

  void _removeLicenseCertificate() {
    setState(() {
      _licenseCertificate = null;
      _existingLicenseCertificateUrl = null;
    });
  }

  Future<Map<String, dynamic>?> _uploadToCloudinary(
      File file, String uploadPreset) async {
    try {
      const cloudName = 'db3cpgdwm';
      const apiKey = '545187993373729';
      const apiSecret = 'gdgWv-rubTrQTMn6KG0T7-Q5Cfw';
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final folder = 'Veterinary';
      final signature = sha1
          .convert(utf8.encode(
              'folder=$folder&timestamp=$timestamp&upload_preset=$uploadPreset$apiSecret'))
          .toString();
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final jsonResponse = json.decode(String.fromCharCodes(responseData));
      if (response.statusCode == 200) {
        print("Upload successful: $jsonResponse");
        return jsonResponse;
      } else {
        print("Error uploading file: ${response.statusCode}");
        print("Response Data: ${String.fromCharCodes(responseData)}");
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _deleteFromCloudinary(String publicId) async {
    try {
      const cloudName = 'db3cpgdwm';
      const apiKey = '545187993373729';
      const apiSecret = 'gdgWv-rubTrQTMn6KG0T7-Q5Cfw';
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
      final request = http.MultipartRequest('POST', uri);
      final signature = sha1
          .convert(
              utf8.encode('public_id=$publicId&timestamp=$timestamp$apiSecret'))
          .toString();
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['public_id'] = publicId;
      final response = await request.send();
      if (response.statusCode == 200) {
        print("Deletion successful for public_id: $publicId");
      } else {
        print("Error deleting file: ${response.statusCode}");
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Future<void> _publishVeterinaryProfile() async {
    if (_nameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _experienceController.text.isEmpty ||
        _aboutController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _appointmentsController.text.isEmpty ||
        int.parse(_appointmentsController.text) > 30) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(_appointmentsController.text.isEmpty ||
                  int.parse(_appointmentsController.text) > 30
              ? 'The number of appointments per day must be a valid number and less than 30.'
              : 'All fields are mandatory! Please fill them all.'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: Text('OK'))
          ],
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      String? imageUrl = _existingImageUrl;
      String? imagePublicId = _existingImagePublicId;
      String? licenseCertificateUrl = _existingLicenseCertificateUrl;
      String? licenseCertificatePublicId = _existingLicenseCertificatePublicId;

      // Upload selected image to Cloudinary if a new image is chosen
      if (_image != null) {
        if (_existingImagePublicId != null) {
          await _deleteFromCloudinary(_existingImagePublicId!);
        }
        final uploadResponse =
            await _uploadToCloudinary(_image!, 'veterinary_preset');
        if (uploadResponse != null) {
          imageUrl = uploadResponse['secure_url'];
          imagePublicId = uploadResponse['public_id'];
          print("Image uploaded: $imageUrl");
        }
      }

      // Upload selected license certificate to Cloudinary if a new one is chosen
      if (_licenseCertificate != null) {
        if (_existingLicenseCertificatePublicId != null) {
          await _deleteFromCloudinary(_existingLicenseCertificatePublicId!);
        }
        final uploadResponse = await _uploadToCloudinary(
            _licenseCertificate!, 'licensecertificate_preset');
        if (uploadResponse != null) {
          licenseCertificateUrl = uploadResponse['secure_url'];
          licenseCertificatePublicId = uploadResponse['public_id'];
          print("License Certificate uploaded: $licenseCertificateUrl");
        }
      }

      // Prepare data for Firestore
      final vetData = {
        'userId': userId,
        'name': _nameController.text,
        'location': _locationController.text,
        'experience': _experienceController.text,
        'about': _aboutController.text,
        'price': '${_selectedCurrency} ${_priceController.text}',
        'appointments': _appointmentsController.text,
        'places': _places,
        'imageUrl': imageUrl ?? '',
        'imagePublicId': imagePublicId ?? '',
        'licenseCertificateUrl': licenseCertificateUrl ?? '',
        'licenseCertificatePublicId': licenseCertificatePublicId ?? '',
        'publishedTime': FieldValue.serverTimestamp(),
        'approved': _approved,
      };

      DocumentReference veterinaryDocRef;
      if (_profileId == null) {
        // Add veterinary profile data to Firestore
        veterinaryDocRef = await FirebaseFirestore.instance
            .collection('Veterinary')
            .add(vetData);
        _profileId = veterinaryDocRef.id;
      } else {
        // Update existing veterinary profile data in Firestore
        veterinaryDocRef =
            FirebaseFirestore.instance.collection('Veterinary').doc(_profileId);
        await veterinaryDocRef.update(vetData);
      }

      // Also add/update veterinary profile data to user's sub-collection in 'user' collection
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('Veterinary')
          .doc(_profileId)
          .set(vetData);

      // Update the user's position and approved status in Firestore
      await FirebaseFirestore.instance.collection('user').doc(userId).update({
        'position': 'Buyer-Veterinary',
        'approved': _approved,
      });

      print(
          "Veterinary profile ${_profileId == null ? 'added' : 'updated'}: $vetData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veterinary Profile Published Successfully!')),
      );

      // Navigate to HomePage only if fromScreen is AddItemScreen
      if (widget.fromScreen == 'AddItemScreen') {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false);
      } else {
        Navigator.pop(context);
      }
    } catch (error) {
      print('Error publishing veterinary profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Publish Veterinary Profile')),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Veterinary Profile'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Name TextField
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location TextField
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Experience TextField
                  TextField(
                    controller: _experienceController,
                    decoration: InputDecoration(
                      labelText: 'Experience',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // About TextArea
                  TextField(
                    controller: _aboutController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'About',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Appointments per Day
                  TextField(
                    controller: _appointmentsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'No. of Appointments/Day',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (int.tryParse(value) != null &&
                          int.parse(value) > 30) {
                        _appointmentsController.text = '30';
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Maximum appointments per day is 30.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Places TextField
                  TextField(
                    controller: _placesController,
                    decoration: InputDecoration(
                      labelText:
                          'Places (separate multiple places with commas)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Display places as tags
                  Wrap(
                    spacing: 8.0,
                    children: _places.map((place) {
                      return Chip(
                        label: Text(place),
                        onDeleted: () {
                          setState(() {
                            _places.remove(place);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Price and Currency Selection
                  Row(
                    children: [
                      // Currency Dropdown Button
                      DropdownButton<String>(
                        value: _selectedCurrency,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCurrency = newValue!;
                          });
                        },
                        items: <String>['USD', 'INR']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      const SizedBox(width: 16),
                      // Price Input Field
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Image Picker Section
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text(
                            _image == null ? 'Pick Image' : 'Change Image'),
                      ),
                      if (_image != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Stack(
                            children: [
                              Image.file(_image!,
                                  width: 100, height: 100, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: _removeImage),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_existingImageUrl != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Stack(
                            children: [
                              Image.network(_existingImageUrl!,
                                  width: 100, height: 100, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: _removeImage),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // License Certificate Picker Section
                  ElevatedButton(
                    onPressed: _pickLicenseCertificate,
                    child: Text(_licenseCertificate == null
                        ? 'Pick License Certificate'
                        : 'Change License Certificate'),
                  ),
                  const SizedBox(height: 16),
                  if (_licenseCertificate != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Stack(
                        children: [
                          _licenseCertificate!.path.endsWith('.jpg') ||
                                  _licenseCertificate!.path.endsWith('.png') ||
                                  _licenseCertificate!.path.endsWith('.heic')
                              ? Image.file(
                                  _licenseCertificate!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Text(
                                  _licenseCertificate!.path.split('/').last,
                                  style: TextStyle(fontSize: 16),
                                ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: _removeLicenseCertificate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_existingLicenseCertificateUrl != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Stack(
                        children: [
                          _existingLicenseCertificateUrl!.endsWith('.jpg') ||
                                  _existingLicenseCertificateUrl!
                                      .endsWith('.png') ||
                                  _existingLicenseCertificateUrl!
                                      .endsWith('.heic')
                              ? Image.network(
                                  _existingLicenseCertificateUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Text(
                                  'Existing License Certificate',
                                  style: TextStyle(fontSize: 16),
                                ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: _removeLicenseCertificate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Publish Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _publishVeterinaryProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Publish'),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          Size(double.infinity, 50), // Full-width button
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black
                  .withOpacity(0.5), // Transparent and dark background
              child: Center(
                child: Lottie.asset(
                  'asset/image/loading.json',
                  width: 100, // Small size for the Lottie animation
                  height: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
