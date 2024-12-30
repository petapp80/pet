import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PetEdit extends StatefulWidget {
  final String name;
  final Map<String, dynamic> petData;
  final String userName;
  final String userEmail;
  final String userId;
  final String petId;

  const PetEdit({
    super.key,
    required this.name,
    required this.petData,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.petId,
  });

  @override
  State<PetEdit> createState() => _PetEditState();
}

class _PetEditState extends State<PetEdit> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _colourController = TextEditingController();
  final TextEditingController _imagePublicIdController =
      TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _petTypeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  bool nameEditMode = false;
  bool aboutEditMode = false;
  bool ageEditMode = false;
  bool breedEditMode = false;
  bool colourEditMode = false;
  bool imagePublicIdEditMode = false;
  bool imageUrlEditMode = false;
  bool locationEditMode = false;
  bool petTypeEditMode = false;
  bool priceEditMode = false;
  bool sexEditMode = false;
  bool userIdEditMode = false;
  bool weightEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchPetData();
  }

  Future<void> _fetchPetData() async {
    try {
      var petDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('pets')
          .doc(widget.petId)
          .get();
      if (petDoc.exists) {
        var petData = petDoc.data();
        if (petData != null) {
          _initializePetFields(petData);
        }
      }
    } catch (e) {
      print('Error fetching pet data: $e');
    }
  }

  void _initializePetFields(Map<String, dynamic> petData) {
    setState(() {
      _nameController.text = widget.userName;
      _aboutController.text = petData['about'] ?? 'null';
      _ageController.text = petData['age'] ?? 'null';
      _breedController.text = petData['breed'] ?? 'null';
      _colourController.text = petData['colour'] ?? 'null';
      _imagePublicIdController.text = petData['imagePublicId'] ?? 'null';
      _imageUrlController.text = petData['imageUrl'] ?? 'null';
      _locationController.text = petData['location'] ?? 'null';
      _petTypeController.text = petData['petType'] ?? 'null';
      _priceController.text = petData['price'] ?? 'null';
      _sexController.text = petData['sex'] ?? 'null';
      _userIdController.text = petData['userId'] ?? 'null';
      _weightController.text = petData['weight'] ?? 'null';
    });
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('pets')
          .doc(widget.petId)
          .update({
        'about': _aboutController.text,
        'age': _ageController.text,
        'breed': _breedController.text,
        'colour': _colourController.text,
        'imagePublicId': _imagePublicIdController.text,
        'imageUrl': _imageUrlController.text,
        'location': _locationController.text,
        'petType': _petTypeController.text,
        'price': _priceController.text,
        'sex': _sexController.text,
        'weight': _weightController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
    } catch (e) {
      print('Error saving changes: $e');
    }
  }

  Future<void> _deletePet() async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('pets')
          .doc(widget.petId)
          .delete();

      print('Pet deleted: ${widget.name}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet deleted successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Error deleting pet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting pet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Edit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deletePet,
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
                // Age Field
                _buildLabelTextField(
                  label: 'Age',
                  controller: _ageController,
                  editMode: ageEditMode,
                  onEditPressed: () {
                    setState(() {
                      ageEditMode = !ageEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Breed Field
                _buildLabelTextField(
                  label: 'Breed',
                  controller: _breedController,
                  editMode: breedEditMode,
                  onEditPressed: () {
                    setState(() {
                      breedEditMode = !breedEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Colour Field
                _buildLabelTextField(
                  label: 'Colour',
                  controller: _colourController,
                  editMode: colourEditMode,
                  onEditPressed: () {
                    setState(() {
                      colourEditMode = !colourEditMode;
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
                // Pet Type Field
                _buildLabelTextField(
                  label: 'Pet Type',
                  controller: _petTypeController,
                  editMode: petTypeEditMode,
                  onEditPressed: () {
                    setState(() {
                      petTypeEditMode = !petTypeEditMode;
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
                // Sex Field
                _buildLabelTextField(
                  label: 'Sex',
                  controller: _sexController,
                  editMode: sexEditMode,
                  onEditPressed: () {
                    setState(() {
                      sexEditMode = !sexEditMode;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Weight Field
                _buildLabelTextField(
                  label: 'Weight',
                  controller: _weightController,
                  editMode: weightEditMode,
                  onEditPressed: () {
                    setState(() {
                      weightEditMode = !weightEditMode;
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
