import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VeterinaryEdit extends StatefulWidget {
  final String name;
  final Map<String, dynamic> vetData;
  final String userId;

  const VeterinaryEdit({
    super.key,
    required this.name,
    required this.vetData,
    required this.userId,
  });

  @override
  State<VeterinaryEdit> createState() => _VeterinaryEditState();
}

class _VeterinaryEditState extends State<VeterinaryEdit> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _imagePublicIdController =
      TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  bool nameEditMode = false;
  bool aboutEditMode = false;
  bool availabilityEditMode = false;
  bool experienceEditMode = false;
  bool imagePublicIdEditMode = false;
  bool imageUrlEditMode = false;
  bool locationEditMode = false;
  bool priceEditMode = false;
  bool userIdEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchVeterinaryData();
    _nameController.text = widget.name;
    _userIdController.text = widget.userId;
  }

  Future<void> _fetchVeterinaryData() async {
    try {
      var vetDoc = await FirebaseFirestore.instance
          .collection('eterinary')
          .doc(widget.name)
          .get();
      if (vetDoc.exists) {
        var vetData = vetDoc.data();
        if (vetData != null) {
          _initializeVeterinaryFields(vetData);
        }
      }
    } catch (e) {
      print('Error fetching veterinary data: $e');
    }
  }

  void _initializeVeterinaryFields(Map<String, dynamic> vetData) {
    setState(() {
      _aboutController.text = vetData['about'] ?? '';
      _availabilityController.text = vetData['availability'] ?? '';
      _experienceController.text = vetData['experience'] ?? '';
      _imagePublicIdController.text = vetData['imagePublicId'] ?? '';
      _imageUrlController.text = vetData['imageUrl'] ?? '';
      _locationController.text = vetData['location'] ?? '';
      _priceController.text = vetData['price'] ?? '';
    });
  }

  // Function to save changes
  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('veterinary')
          .doc(widget.name)
          .update({
        'about': _aboutController.text,
        'availability': _availabilityController.text,
        'experience': _experienceController.text,
        'imagePublicId': _imagePublicIdController.text,
        'imageUrl': _imageUrlController.text,
        'location': _locationController.text,
        'price': _priceController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
    } catch (e) {
      print('Error saving changes: $e');
    }
  }

  // Function to delete the veterinary
  Future<void> _deleteVeterinary() async {
    try {
      await FirebaseFirestore.instance
          .collection('veterinary')
          .doc(widget.name)
          .delete();
      print('Veterinary deleted: ${widget.name}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veterinary deleted successfully')),
      );

      // Close the current screen and return true to indicate success
      Navigator.pop(context, true);
    } catch (e) {
      print('Error deleting veterinary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting veterinary: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinary Edit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteVeterinary,
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
                // About Field
                _buildLabelTextField(
                  label: 'About',
                  controller: _aboutController,
                  editMode: aboutEditMode,
                  onEditPressed: () {
                    setState(() {
                      aboutEditMode = !aboutEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Availability Field
                _buildLabelTextField(
                  label: 'Availability',
                  controller: _availabilityController,
                  editMode: availabilityEditMode,
                  onEditPressed: () {
                    setState(() {
                      availabilityEditMode = !availabilityEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Experience Field
                _buildLabelTextField(
                  label: 'Experience',
                  controller: _experienceController,
                  editMode: experienceEditMode,
                  onEditPressed: () {
                    setState(() {
                      experienceEditMode = !experienceEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Image Public ID Field
                _buildLabelTextField(
                  label: 'Image Public ID',
                  controller: _imagePublicIdController,
                  editMode: imagePublicIdEditMode,
                  onEditPressed: () {
                    setState(() {
                      imagePublicIdEditMode = !imagePublicIdEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Image URL Field
                _buildLabelTextField(
                  label: 'Image URL',
                  controller: _imageUrlController,
                  editMode: imageUrlEditMode,
                  onEditPressed: () {
                    setState(() {
                      imageUrlEditMode = !imageUrlEditMode;
                    });
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                // Location Field
                _buildLabelTextField(
                  label: 'Location',
                  controller: _locationController,
                  editMode: locationEditMode,
                  onEditPressed: () {
                    setState(() {
                      locationEditMode = !locationEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Price Field
                _buildLabelTextField(
                  label: 'Price',
                  controller: _priceController,
                  editMode: priceEditMode,
                  onEditPressed: () {
                    setState(() {
                      priceEditMode = !priceEditMode;
                    });
                  },
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
                const SizedBox(height: 20),
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
