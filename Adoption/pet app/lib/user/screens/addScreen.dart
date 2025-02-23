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
  final String? docId; // Add this line to accept docId

  const AddScreen({required this.fromScreen, this.docId, super.key});

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
  TextEditingController quantityController = TextEditingController();

  File? _selectedFile;
  File? _vaccinationFile; // New File variable for vaccination certificate
  String _selectedCurrency = 'USD'; // Currency selection
  String _selectedSex = 'Male'; // Default sex selection
  String? _existingImageUrl;
  String? _existingVaccinationUrl; // New variable to hold the vaccination certificate URL
  bool _isLoading = false;
  bool _approved = false;

  @override
  void initState() {
    super.initState();
    if (widget.docId != null) {
      print('Received docId: ${widget.docId}'); // Debug print
      _fetchPetData();
    }
  }

  Future<void> _fetchPetData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('pets')
          .doc(widget.docId)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          print('Data fetched: $data'); // Debug print
          petTypeController.text = data['petType'];
          breedController.text = data['breed'] ?? '';
          ageController.text = data['age'];
          _selectedSex = data['sex'];
          colourController.text = data['colour'];
          weightController.text = data['weight'];
          locationController.text = data['location'];
          priceController.text = data['price'].split(' ')[1];
          _selectedCurrency = data['price'].split(' ')[0];
          aboutController.text = data['about'];
          quantityController.text = data['quantity'].toString();
          _existingImageUrl = data['imageUrl'];
          _existingVaccinationUrl = data['vaccinationUrl']; // Get the vaccination certificate URL if it exists
          _approved = data.containsKey('approved') ? data['approved'] : false;
        });
      } else {
        print('No data found for docId: ${widget.docId}'); // Debug print
      }
    } catch (e) {
      print('Error fetching pet data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'heic'], // allowed file types
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _existingImageUrl = null; // Reset existing image if a new one is picked
      });
    }
  }

  Future<void> _pickVaccinationFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'heic'], // allowed file types
    );

    if (result != null) {
      setState(() {
        _vaccinationFile = File(result.files.single.path!);
        _existingVaccinationUrl =
            null; // Reset existing vaccination certificate if a new one is picked
      });
    }
  }

  void _removeFile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("File Canceled"),
      duration: Duration(seconds: 1),
    ));
    setState(() {
      _selectedFile = null; // Remove the selected file
      _existingImageUrl = null; // Clear the existing image URL
    });
  }

  void _removeVaccinationFile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Vaccination Certificate Canceled"),
      duration: Duration(seconds: 1),
    ));
    setState(() {
      _vaccinationFile = null; // Remove the selected vaccination file
      _existingVaccinationUrl = null; // Clear the existing vaccination URL
    });
  }

  Future<Map<String, dynamic>?> _uploadToCloudinary(
      File imageFile, String preset) async {
    try {
      const cloudName = 'db3cpgdwm';
      const apiKey = '545187993373729';
      const apiSecret = 'gdgWv-rubTrQTMn6KG0T7-Q5Cfw';

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = sha1
          .convert(utf8
              .encode('timestamp=$timestamp&upload_preset=$preset$apiSecret'))
          .toString();

      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = preset;
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

  Future<void> _deleteFromCloudinary(String publicId) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/db3cpgdwm/delete_by_token');
      final response = await http.post(uri, body: {
        'token': publicId,
      });

      if (response.statusCode == 200) {
        print('Image deleted successfully.');
      } else {
        print('Error deleting image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<void> _publishPet() async {
    if (petTypeController.text.isEmpty ||
        ageController.text.isEmpty ||
        colourController.text.isEmpty ||
        weightController.text.isEmpty ||
        locationController.text.isEmpty ||
        priceController.text.isEmpty ||
        quantityController.text.isEmpty ||
        (_selectedFile == null && _existingImageUrl == null)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('All fields are mandatory! Please fill them all.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      String? imageUrl = _existingImageUrl;
      String? imagePublicId;
      String? vaccinationUrl = _existingVaccinationUrl;
      String? vaccinationPublicId;

      if (_selectedFile != null) {
        final uploadResponse =
            await _uploadToCloudinary(_selectedFile!, 'pet_preset');
        if (uploadResponse != null) {
          if (_existingImageUrl != null) {
            await _deleteFromCloudinary(_existingImageUrl!);
          }
          imageUrl = uploadResponse['secure_url'];
          imagePublicId = uploadResponse['public_id'];
          print("Image uploaded: $imageUrl");
        }
      }

      if (_vaccinationFile != null) {
        final uploadResponse =
            await _uploadToCloudinary(_vaccinationFile!, 'vaccination_preset');
               if (uploadResponse != null) {
          if (_existingVaccinationUrl != null) {
            await _deleteFromCloudinary(_existingVaccinationUrl!);
          }
          vaccinationUrl = uploadResponse['secure_url'];
          vaccinationPublicId = uploadResponse['public_id'];
          print("Vaccination certificate uploaded: $vaccinationUrl");
        }
      }

      final petData = {
        'userId': userId, // Link pet to current user
        'petType': petTypeController.text,
        'age': ageController.text,
        'sex': _selectedSex,
        'colour': colourController.text,
        'weight': weightController.text,
        'location': locationController.text,
        'price': '${_selectedCurrency} ${priceController.text}',
        'about': aboutController.text,
        'quantity': int.parse(quantityController.text), // Add quantity field
        'imageUrl': imageUrl,
        'imagePublicId': imagePublicId,
        'vaccinationUrl': vaccinationUrl, // Add vaccination certificate URL
        'vaccinationPublicId': vaccinationPublicId, // Add vaccination certificate public ID
        'publishedTime': FieldValue.serverTimestamp(), // Add published time
        'approved': _approved, // Retain approved field if it exists
      };

      // Add optional fields if provided
      if (breedController.text.isNotEmpty) {
        petData['breed'] = breedController.text;
      }

      // Firestore document references
      DocumentReference petDocRef;
      if (widget.docId == null) {
        petDocRef = FirebaseFirestore.instance.collection('pets').doc();
      } else {
        petDocRef = FirebaseFirestore.instance.collection('pets').doc(widget.docId);
      }

      // Add or update pet document in Firestore
      if (widget.docId == null) {
        await petDocRef.set(petData);
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('pets')
            .doc(petDocRef.id)
            .set(petData);
      } else {
        await petDocRef.update(petData);
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('pets')
            .doc(petDocRef.id)
            .update(petData);
      }

      // Update user's position to Buyer-Seller
      await FirebaseFirestore.instance.collection('user').doc(userId).update({
        'position': 'Buyer-Seller',
      });

      print("Pet ${widget.docId == null ? 'added' : 'updated'}: $petData");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet Published Successfully!')),
      );

      if (widget.fromScreen == 'AddItemScreen') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      } else {
        Navigator.pop(context);
      }
    } catch (error) {
      print('Error publishing pet: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Publish Pet')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pet'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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

                    // Breed (Optional)
                    TextFormField(
                      controller: breedController,
                      decoration: const InputDecoration(
                        labelText: 'Breed (Optional)',
                        icon: Icon(Icons.pets),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Age
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        icon: Icon(Icons.cake),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the age';
                        } else if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Sex
                    DropdownButtonFormField<String>(
                      value: _selectedSex,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSex = newValue!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sex',
                        icon: Icon(Icons.male),
                      ),
                      items: <String>['Male', 'Female']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select the sex';
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

                    // Quantity
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        icon: Icon(Icons.confirmation_num),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the quantity';
                        } else if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
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

                    // Display selected image with close button
                    if (_selectedFile != null || _existingImageUrl != null)
                      Center(
                        child: Stack(
                          alignment: Alignment.topRight, // Close button at top right
                          children: [
                            // Displaying the selected image as an image
                            _selectedFile != null
                                ? Image.file(
                                    _selectedFile!,
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _existingImageUrl!,
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

                    // Vaccination Certificate Selection Button
                    ElevatedButton(
                      onPressed: _pickVaccinationFile,
                      child: Text(_vaccinationFile == null
                          ? 'Select Vaccination Certificate'
                          : 'File Selected: ${_vaccinationFile!.path.split('/').last}'),
                    ),
                    const SizedBox(height: 10),

                    // Display selected vaccination certificate with close button
                    if (_vaccinationFile != null || _existingVaccinationUrl != null)
                      Center(
                        child: Stack(
                          alignment: Alignment.topRight, // Close button at top right
                          children: [
                            // Displaying the selected vaccination certificate as an image
                            _vaccinationFile != null
                                ? Image.file(
                                    _vaccinationFile!,
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _existingVaccinationUrl!,
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                            // Close button positioned above the image
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _removeVaccinationFile,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Publish Button
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Publishing...')),
                                );
                                // Call the _publishPet function to handle publishing logic
                                _publishPet();
                              }
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                          : const Text('Publish'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
