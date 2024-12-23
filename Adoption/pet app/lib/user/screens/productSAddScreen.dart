import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'home.dart'; // Import the HomePage

class ProductsAddScreen extends StatefulWidget {
  final String fromScreen;
  final String? docId; // Make docId optional

  const ProductsAddScreen({
    required this.fromScreen,
    this.docId, // Make this optional
    super.key,
  });

  @override
  State<ProductsAddScreen> createState() => _ProductsAddScreenState();
}

class _ProductsAddScreenState extends State<ProductsAddScreen> {
  TextEditingController _productNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();

  String _selectedCurrency = 'USD';
  File? _image;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.docId != null && widget.docId!.isNotEmpty) {
      _fetchProductData();
    }
  }

  Future<void> _fetchProductData() async {
    setState(() {
      _isLoading = true;
    });

    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.docId)
        .get();
    final data = doc.data();
    if (data != null) {
      _productNameController.text = data['productName'];
      _descriptionController.text = data['description'];
      _locationController.text = data['location'];
      _priceController.text = data['price'].split(' ')[1];
      _selectedCurrency = data['price'].split(' ')[0];
      _quantityController.text = data['quantity'];
      _existingImageUrl = data['imageUrl'];
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'heic'],
    );

    if (result != null) {
      setState(() {
        _image = File(result.files.single.path!);
        _existingImageUrl = null; // Reset existing image if a new one is picked
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _existingImageUrl = null;
    });
  }

  Future<Map<String, dynamic>?> _uploadToCloudinary(File imageFile) async {
    try {
      const cloudName = 'db3cpgdwm';
      const uploadPreset = 'product_preset';
      const apiKey = '545187993373729';
      const apiSecret = 'gdgWv-rubTrQTMn6KG0T7-Q5Cfw';

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final folder = 'Products';
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

  Future<void> _publishProduct() async {
    if (_productNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        (_image == null && _existingImageUrl == null)) {
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

      if (_image != null) {
        final uploadResponse = await _uploadToCloudinary(_image!);
        if (uploadResponse != null) {
          imageUrl = uploadResponse['secure_url'];
          imagePublicId = uploadResponse['public_id'];
          print("Image uploaded: $imageUrl");
        }
      }

      final productData = {
        'userId': userId,
        'productName': _productNameController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'price': '${_selectedCurrency} ${_priceController.text}',
        'quantity': _quantityController.text,
        'imageUrl': imageUrl,
        'imagePublicId': imagePublicId,
        'publishedTime': FieldValue.serverTimestamp(), // Add published time
      };

      if (widget.docId == null || widget.docId!.isEmpty) {
        await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('products')
            .add(productData);
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.docId)
            .update(productData);
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('products')
            .doc(widget.docId)
            .update(productData);
      }

      // Update user's position to Buyer-Seller
      await FirebaseFirestore.instance.collection('user').doc(userId).update({
        'position': 'Buyer-Seller',
      });

      print(
          "Product ${widget.docId == null || widget.docId!.isEmpty ? 'added' : 'updated'}: $productData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product Published Successfully!')),
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
      print('Error publishing product: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Publish Product')),
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
        title: const Text('Add Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _productNameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Product Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
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
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: Text(
                              _image == null ? 'Pick Image' : 'Change Image'),
                        ),
                        if (_image != null || _existingImageUrl != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Stack(
                              children: [
                                _image != null
                                    ? Image.file(
                                        _image!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _existingImageUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: _removeImage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _publishProduct,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                          : const Text('Publish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
