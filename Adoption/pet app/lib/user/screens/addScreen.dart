import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'home.dart'; // Import the HomePage

class AddScreen extends StatefulWidget {
  final String fromScreen;

  const AddScreen({required this.fromScreen, super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController petTypeController = TextEditingController();
  TextEditingController breedController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController sexController = TextEditingController();
  TextEditingController colourController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController aboutController = TextEditingController();

  File? _selectedFile;
  String _selectedCurrency = 'USD'; // Currency selection

  // Function to pick a file using FilePicker
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'heic'], // allowed file types
    );

    if (result != null) {
      setState(() {
        // Assign the selected file
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  // Function to remove the selected file
  void _removeFile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("File Canceled"),
      duration: Duration(seconds: 1),
    ));
    setState(() {
      _selectedFile = null; // Remove the selected file
    });
  }

  Future<Map<String, dynamic>?> _uploadToCloudinary(File imageFile) async {
    try {
      const cloudName = 'db3cpgdwm';
      const uploadPreset = 'pet_preset';
      const apiKey = '545187993373729';
      const apiSecret = 'gdgWv-rubTrQTMn6KG0T7-Q5Cfw';

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = sha1
          .convert(utf8.encode(
              'timestamp=$timestamp&upload_preset=$uploadPreset$apiSecret'))
          .toString();

      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
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

  Future<void> _publishPet() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Check the position in the user collection
      final userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final position = data['position'] as String?;
        if (position != 'Seller') {
          await FirebaseFirestore.instance
              .collection('user')
              .doc(userId)
              .update({
            'position': 'Buyer-Seller',
          });
        }
      }

      String? imageUrl;
      String? imagePublicId;

      // Upload selected image to Cloudinary
      if (_selectedFile != null) {
        final uploadResponse = await _uploadToCloudinary(_selectedFile!);
        if (uploadResponse != null) {
          imageUrl = uploadResponse['secure_url'];
          imagePublicId = uploadResponse['public_id'];
          print("Image uploaded: $imageUrl");
        }
      }

      // Prepare data for Firestore
      final petData = {
        'userId': userId, // Link pet to current user
        'petType': petTypeController.text,
        'breed': breedController.text,
        'age': ageController.text,
        'sex': sexController.text,
        'colour': colourController.text,
        'weight': weightController.text,
        'location': locationController.text,
        'price': '${_selectedCurrency} ${priceController.text}',
        'about': aboutController.text,
        'imageUrl': imageUrl,
        'imagePublicId': imagePublicId,
      };

      // Add pet data to Firestore in the 'pets' collection
      await FirebaseFirestore.instance.collection('pets').add(petData);

      // Also add pet data to user's sub-collection in 'user' collection
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('pets')
          .add(petData);

      print("Pet added: $petData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet Published Successfully!')),
      );

      // Navigate to HomePage or the screen you want
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    } catch (error) {
      print('Error publishing pet: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Publish Pet')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pet'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Pet Type
              TextFormField(
                controller: petTypeController,
                decoration: const InputDecoration(
                  labelText: 'Pet Type',
                  icon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pet type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Breed
              TextFormField(
                controller: breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  icon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the breed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Age (Simple Text Field)
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  icon: Icon(Icons.cake),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Sex
              TextFormField(
                controller: sexController,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  icon: Icon(Icons.male),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the sex';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Colour
              TextFormField(
                controller: colourController,
                decoration: const InputDecoration(
                  labelText: 'Colour',
                  icon: Icon(Icons.color_lens),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the colour';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Weight
              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  icon: Icon(Icons.fitness_center),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the weight';
                  } else if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Location
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  icon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Price
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
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        icon: _selectedCurrency == 'USD'
                            ? const Icon(Icons.attach_money)
                            : const Icon(Icons.currency_rupee),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the price';
                        } else if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // About (Multi-line text area)
              TextFormField(
                controller: aboutController,
                decoration: const InputDecoration(labelText: 'About'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some details about the pet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // File Selection Button
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(_selectedFile == null
                    ? 'Select Image'
                    : 'File Selected: ${_selectedFile!.path.split('/').last}'),
              ),
              const SizedBox(height: 10),

              // Display selected file with close button
              if (_selectedFile != null)
                Center(
                  child: Stack(
                    alignment: Alignment.topRight, // Close button at top right
                    children: [
                      // Displaying the selected file as an image
                      Image.file(
                        _selectedFile!,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                      // Close button positioned above the image
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _removeFile,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),

              // Publish Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Publishing...')),
                    );
                    // Call the _publishPet function to handle publishing logic
                    _publishPet();
                  }
                },
                child: const Text('Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
