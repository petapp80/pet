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

  Future<void> _saveField(String fieldName, String value) async {
    try {
      var petDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('pets')
          .doc(widget.petId)
          .get();

      if (petDoc.exists) {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .collection('pets')
            .doc(widget.petId)
            .update({fieldName: value});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet document does not exist.')),
        );
      }
    } catch (e) {
      print('Error updating field: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating field: $e')),
      );
    }
  }

  Future<void> _deletePet() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this pet?'),
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
        // Deleting the pet document
        await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .collection('pets')
            .doc(widget.petId)
            .delete();

        // Deleting the user document
        await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .delete();

        print(
            'Pet and User documents deleted: ${widget.petId}, ${widget.userId}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet and User deleted successfully')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        print('Error deleting pet: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting pet: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Edit'),
        actions: [
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
                  label: 'About',
                  controller: _aboutController,
                  editMode: aboutEditMode,
                  onEditPressed: () {
                    setState(() {
                      aboutEditMode = !aboutEditMode;
                      if (!aboutEditMode) {
                        _saveField('about', _aboutController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Age',
                  controller: _ageController,
                  editMode: ageEditMode,
                  onEditPressed: () {
                    setState(() {
                      ageEditMode = !ageEditMode;
                      if (!ageEditMode) {
                        _saveField('age', _ageController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Breed',
                  controller: _breedController,
                  editMode: breedEditMode,
                  onEditPressed: () {
                    setState(() {
                      breedEditMode = !breedEditMode;
                      if (!breedEditMode) {
                        _saveField('breed', _breedController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Colour',
                  controller: _colourController,
                  editMode: colourEditMode,
                  onEditPressed: () {
                    setState(() {
                      colourEditMode = !colourEditMode;
                      if (!colourEditMode) {
                        _saveField('colour', _colourController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Image Public ID',
                  controller: _imagePublicIdController,
                  editMode: imagePublicIdEditMode,
                  onEditPressed: () {
                    setState(() {
                      imagePublicIdEditMode = !imagePublicIdEditMode;
                      if (!imagePublicIdEditMode) {
                        _saveField(
                            'imagePublicId', _imagePublicIdController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Image URL',
                  controller: _imageUrlController,
                  editMode: imageUrlEditMode,
                  onEditPressed: () {
                    setState(() {
                      imageUrlEditMode = !imageUrlEditMode;
                      if (!imageUrlEditMode) {
                        _saveField('imageUrl', _imageUrlController.text);
                      }
                    });
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Location',
                  controller: _locationController,
                  editMode: locationEditMode,
                  onEditPressed: () {
                    setState(() {
                      locationEditMode = !locationEditMode;
                      if (!locationEditMode) {
                        _saveField('location', _locationController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Pet Type',
                  controller: _petTypeController,
                  editMode: petTypeEditMode,
                  onEditPressed: () {
                    setState(() {
                      petTypeEditMode = !petTypeEditMode;
                      if (!petTypeEditMode) {
                        _saveField('petType', _petTypeController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Price',
                  controller: _priceController,
                  editMode: priceEditMode,
                  onEditPressed: () {
                    setState(() {
                      priceEditMode = !priceEditMode;
                      if (!priceEditMode) {
                        _saveField('price', _priceController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Sex',
                  controller: _sexController,
                  editMode: sexEditMode,
                  onEditPressed: () {
                    setState(() {
                      sexEditMode = !sexEditMode;
                      if (!sexEditMode) {
                        _saveField('sex', _sexController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildLabelTextField(
                  label: 'Weight',
                  controller: _weightController,
                  editMode: weightEditMode,
                  onEditPressed: () {
                    setState(() {
                      weightEditMode = !weightEditMode;
                      if (!weightEditMode) {
                        _saveField('weight', _weightController.text);
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
