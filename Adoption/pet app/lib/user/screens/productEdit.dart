import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductEdit extends StatefulWidget {
  final String name;
  final Map<String, dynamic> productData;
  final String userName;
  final String userEmail;
  final String userId;
  final String productId;

  const ProductEdit({
    super.key,
    required this.name,
    required this.productData,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.productId,
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
  final TextEditingController _quantityController = TextEditingController();
  late Timestamp _publishedTime;

  bool nameEditMode = false;
  bool descriptionEditMode = false;
  bool productNameEditMode = false;
  bool productLocationEditMode = false;
  bool productPriceEditMode = false;
  bool productImagePublicIdEditMode = false;
  bool productImageUrlEditMode = false;
  bool userIdEditMode = false;
  bool quantityEditMode = false;

  @override
  void initState() {
    super.initState();
    _initializeProductFields(widget.productData);
    _nameController.text = widget.userName;
    _userIdController.text = widget.userId;
    _fetchProductData(); // Ensure data is fetched on initialization
  }

  Future<void> _fetchProductData() async {
    try {
      print('Fetching Product Data for ID: ${widget.productId}'); // Debug print
      var productDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('products')
          .doc(widget.productId)
          .get();
      if (productDoc.exists) {
        var productData = productDoc.data();
        if (productData != null) {
          _initializeProductFields(productData);
        }
      } else {
        print('Product Document does not exist.');
      }
    } catch (e) {
      print('Error fetching product data: $e');
    }
  }

  void _initializeProductFields(Map<String, dynamic> productData) {
    print('Initializing Product Fields: $productData'); // Debug print
    setState(() {
      _descriptionController.text = productData['description'] ?? '';
      _productNameController.text = productData['productName'] ?? '';
      _productLocationController.text = productData['location'] ?? '';
      _productPriceController.text = productData['price'] ?? '';
      _productImagePublicIdController.text = productData['imagePublicId'] ?? '';
      _productImageUrlController.text = productData['imageUrl'] ?? '';
      _quantityController.text = productData['quantity'] ?? '';
      _publishedTime = productData['publishedTime'] ?? Timestamp.now();
    });
  }

  Future<void> _saveField(String fieldName, String value) async {
    try {
      var productDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('products')
          .doc(widget.productId)
          .get();

      if (productDoc.exists) {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .collection('products')
            .doc(widget.productId)
            .update({fieldName: value});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product document does not exist.')),
        );
      }
    } catch (e) {
      print('Error updating field: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating field: $e')),
      );
    }
  }

  Future<void> _deleteProduct() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        // Deleting the product document
        await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .collection('products')
            .doc(widget.productId)
            .delete();

        // Deleting the user document
        await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .delete();

        print(
            'Product and User documents deleted: ${widget.productId}, ${widget.userId}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Product and User deleted successfully')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        print('Error deleting product: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Edit'),
        actions: [
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
                _buildLabelTextField(
                  label: 'Name',
                  controller: _nameController,
                  editMode: nameEditMode,
                  onEditPressed: () {
                    setState(() {
                      nameEditMode = !nameEditMode;
                      if (!nameEditMode) {
                        _saveField('name', _nameController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  editMode: descriptionEditMode,
                  onEditPressed: () {
                    setState(() {
                      descriptionEditMode = !descriptionEditMode;
                      if (!descriptionEditMode) {
                        _saveField('description', _descriptionController.text);
                      }
                    });
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Product Name',
                  controller: _productNameController,
                  editMode: productNameEditMode,
                  onEditPressed: () {
                    setState(() {
                      productNameEditMode = !productNameEditMode;
                      if (!productNameEditMode) {
                        _saveField('productName', _productNameController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Location',
                  controller: _productLocationController,
                  editMode: productLocationEditMode,
                  onEditPressed: () {
                    setState(() {
                      productLocationEditMode = !productLocationEditMode;
                      if (!productLocationEditMode) {
                        _saveField('location', _productLocationController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Price',
                  controller: _productPriceController,
                  editMode: productPriceEditMode,
                  onEditPressed: () {
                    setState(() {
                      productPriceEditMode = !productPriceEditMode;
                      if (!productPriceEditMode) {
                        _saveField('price', _productPriceController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Image Public ID',
                  controller: _productImagePublicIdController,
                  editMode: productImagePublicIdEditMode,
                  onEditPressed: () {
                    setState(() {
                      productImagePublicIdEditMode =
                          !productImagePublicIdEditMode;
                      if (!productImagePublicIdEditMode) {
                        _saveField('imagePublicId',
                            _productImagePublicIdController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Image URL',
                  controller: _productImageUrlController,
                  editMode: productImageUrlEditMode,
                  onEditPressed: () {
                    setState(() {
                      productImageUrlEditMode = !productImageUrlEditMode;
                      if (!productImageUrlEditMode) {
                        _saveField('imageUrl', _productImageUrlController.text);
                      }
                    });
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Quantity',
                  controller: _quantityController,
                  editMode: quantityEditMode,
                  onEditPressed: () {
                    setState(() {
                      quantityEditMode = !quantityEditMode;
                      if (!quantityEditMode) {
                        _saveField('quantity', _quantityController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'User ID',
                  controller: _userIdController,
                  editMode: userIdEditMode,
                  onEditPressed: () {
                    setState(() {
                      userIdEditMode = !userIdEditMode;
                      if (!userIdEditMode) {
                        _saveField('userId', _userIdController.text);
                      }
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
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: editMode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
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
