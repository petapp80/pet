import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductEdit extends StatefulWidget {
  final String name;
  final Map<String, dynamic> productData;
  final String userName;
  final String userEmail;
  final String userId;

  const ProductEdit({
    super.key,
    required this.name,
    required this.productData,
    required this.userName,
    required this.userEmail,
    required this.userId,
  });

  @override
  State<ProductEdit> createState() => _ProductEditState();
}

class _ProductEditState extends State<ProductEdit> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productLocationController =
      TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productImagePublicIdController =
      TextEditingController();
  final TextEditingController _productImageUrlController =
      TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  bool nameEditMode = false;
  bool descriptionEditMode = false;
  bool productNameEditMode = false;
  bool productLocationEditMode = false;
  bool productPriceEditMode = false;
  bool productImagePublicIdEditMode = false;
  bool productImageUrlEditMode = false;
  bool userIdEditMode = false;

  @override
  void initState() {
    super.initState();
    _initializeProductFields(widget.productData);
    _nameController.text = widget.userName;
    _userIdController.text = widget.userId;
  }

  Future<void> _fetchProductData() async {
    try {
      var productDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('products')
          .doc(widget.name)
          .get();
      if (productDoc.exists) {
        var productData = productDoc.data();
        if (productData != null) {
          _initializeProductFields(productData);
        }
      }
    } catch (e) {
      print('Error fetching product data: $e');
    }
  }

  void _initializeProductFields(Map<String, dynamic> productData) {
    setState(() {
      _descriptionController.text = productData['description'] ?? '';
      _productNameController.text = productData['productName'] ?? '';
      _productLocationController.text = productData['location'] ?? '';
      _productPriceController.text = productData['price'] ?? '';
      _productImagePublicIdController.text = productData['imagePublicId'] ?? '';
      _productImageUrlController.text = productData['imageUrl'] ?? '';
    });
  }

  // Function to save changes
  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('products')
          .doc(widget.name)
          .update({
        'description': _descriptionController.text,
        'productName': _productNameController.text,
        'location': _productLocationController.text,
        'price': _productPriceController.text,
        'imagePublicId': _productImagePublicIdController.text,
        'imageUrl': _productImageUrlController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
    } catch (e) {
      print('Error saving changes: $e');
    }
  }

  // Function to delete the product
  // Function to delete the product
  Future<void> _deleteProduct() async {
    try {
      // Query to find the document where userId matches and productName matches
      final querySnapshot = await FirebaseFirestore.instance
          .collection(
              'products') // Adjust collection name if it's not top-level
          .where('userId', isEqualTo: widget.userId)
          .get();
      // Check if any documents match the query
      if (querySnapshot.docs.isNotEmpty) {
        // Get the document ID of the first match
        final docId = querySnapshot.docs.first.id;

        // Delete the document using its ID
        await FirebaseFirestore.instance
            .collection('products')
            .doc(docId)
            .delete();

        print('Product deleted: ${widget.name}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );

        // Close the current screen and return true to indicate success
        Navigator.pop(context, true);
      } else {
        print('No matching product found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching product found')),
        );
      }
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Edit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteProduct,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                _buildLabelTextField(
                  label: 'Name',
                  controller: _nameController,
                  editMode: nameEditMode,
                  onEditPressed: () {
                    setState(() {
                      nameEditMode = !nameEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Description Field
                _buildLabelTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  editMode: descriptionEditMode,
                  onEditPressed: () {
                    setState(() {
                      descriptionEditMode = !descriptionEditMode;
                    });
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                // Product Name Field
                _buildLabelTextField(
                  label: 'Product Name',
                  controller: _productNameController,
                  editMode: productNameEditMode,
                  onEditPressed: () {
                    setState(() {
                      productNameEditMode = !productNameEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Location Field
                _buildLabelTextField(
                  label: 'Location',
                  controller: _productLocationController,
                  editMode: productLocationEditMode,
                  onEditPressed: () {
                    setState(() {
                      productLocationEditMode = !productLocationEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Price Field
                _buildLabelTextField(
                  label: 'Price',
                  controller: _productPriceController,
                  editMode: productPriceEditMode,
                  onEditPressed: () {
                    setState(() {
                      productPriceEditMode = !productPriceEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Image Public ID Field
                _buildLabelTextField(
                  label: 'Image Public ID',
                  controller: _productImagePublicIdController,
                  editMode: productImagePublicIdEditMode,
                  onEditPressed: () {
                    setState(() {
                      productImagePublicIdEditMode =
                          !productImagePublicIdEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Image URL Field
                _buildLabelTextField(
                  label: 'Image URL',
                  controller: _productImageUrlController,
                  editMode: productImageUrlEditMode,
                  onEditPressed: () {
                    setState(() {
                      productImageUrlEditMode = !productImageUrlEditMode;
                    });
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                // User ID Field
                _buildLabelTextField(
                  label: 'User ID',
                  controller: _userIdController,
                  editMode: userIdEditMode,
                  onEditPressed: () {
                    setState(() {
                      userIdEditMode = !userIdEditMode;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to build label, text field, and edit button
  Widget _buildLabelTextField({
    required String label,
    required TextEditingController controller,
    required bool editMode,
    required VoidCallback onEditPressed,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: editMode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onEditPressed,
            child: Text(
              editMode ? 'Save' : 'Edit',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }
}
