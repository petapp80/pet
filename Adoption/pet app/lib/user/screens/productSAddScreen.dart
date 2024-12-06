import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ProductsAddScreen extends StatefulWidget {
  const ProductsAddScreen({super.key});

  @override
  State<ProductsAddScreen> createState() => _ProductsAddScreenState();
}

class _ProductsAddScreenState extends State<ProductsAddScreen> {
  // Controllers for TextFields
  TextEditingController _productNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  // File to store the selected image
  File? _image;

  // Function to pick an image using FilePicker
  Future<void> _pickImage() async {
    // Open file picker to select an image
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Restricting file type to custom selection
      allowedExtensions: ['jpg', 'png', 'heic'], // Allowed image formats
    );

    if (result != null) {
      setState(() {
        // Get the selected file path
        _image = File(result.files.single.path!);
      });
    }
  }

  // Function to remove the selected image
  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  // Function to validate and publish the product
  void _publishProduct() {
    if (_productNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _image == null) {
      // Show an alert if any field is missing
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
    } else {
      // Proceed with the publish logic
      // For now, just show a success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success'),
          content: Text('Product published successfully!'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        //backgroundColor: Colors.teal, // Custom app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Product Name TextField
              TextField(
                controller: _productNameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Product Description TextField
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Product Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker Section
              Row(
                children: [
                  // Button to select an image
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(_image == null ? 'Pick Image' : 'Change Image'),
                  ),
                  if (_image != null) ...[
                    // Display selected image
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Stack(
                        children: [
                          Image.file(
                            _image!,
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

              // Publish Button
              ElevatedButton(
                onPressed: _publishProduct,
                child: Text('Publish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Button color
                  minimumSize: Size(double.infinity, 50), // Full-width button
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
