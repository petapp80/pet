import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UserEdit extends StatefulWidget {
  final String name;
  final String description;
  final bool isUser; // Flag to check if it's a user or a pet
  final Map<String, String>? petData; // Pet data to pre-fill if editing a pet

  const UserEdit({
    super.key,
    required this.name,
    required this.description,
    required this.isUser,
    this.petData, // Optional pet data
  });

  @override
  State<UserEdit> createState() => _UserEditState();
}

class _UserEditState extends State<UserEdit> {
  String profileImageUrl =
      'https://www.w3schools.com/w3images/avatar2.png'; // Default image

  // Controllers for both user and pet fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Pet-specific fields
  final TextEditingController _petTypeController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  bool nameEditMode = false;
  bool descriptionEditMode = false;
  bool petEditMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize text fields with the data passed from the previous screen
    _nameController.text = widget.name;
    _descriptionController.text = widget.description;

    if (!widget.isUser && widget.petData != null) {
      // Pre-fill pet data if it's a pet
      _petTypeController.text = widget.petData?['type'] ?? '';
      _breedController.text = widget.petData?['breed'] ?? '';
      _ageController.text = widget.petData?['age'] ?? '';
      _sexController.text = widget.petData?['sex'] ?? '';
      _colorController.text = widget.petData?['color'] ?? '';
      _weightController.text = widget.petData?['weight'] ?? '';
      _locationController.text = widget.petData?['location'] ?? '';
      _priceController.text = widget.petData?['price'] ?? '';
      _aboutController.text = widget.petData?['about'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUser ? 'User Edit' : 'Edit Pet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteUser, // Action for deleting a user or pet
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
                // Profile Image (User or Pet Image)
                Center(
                  child: GestureDetector(
                    onTap: _selectProfileImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profileImageUrl),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                  maxLines: 5,
                ),
                const SizedBox(height: 20),

                // If it's a pet, show the pet-specific fields
                if (!widget.isUser) ...[
                  _buildLabelTextField(
                    label: 'Pet Type',
                    controller: _petTypeController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLabelTextField(
                    label: 'Breed',
                    controller: _breedController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLabelTextField(
                    label: 'Age',
                    controller: _ageController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLabelTextField(
                    label: 'Sex',
                    controller: _sexController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLabelTextField(
                    label: 'Color',
                    controller: _colorController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLabelTextField(
                    label: 'Weight',
                    controller: _weightController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLabelTextField(
                    label: 'Location',
                    controller: _locationController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLabelTextField(
                    label: 'Price',
                    controller: _priceController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLabelTextField(
                    label: 'About',
                    controller: _aboutController,
                    editMode: petEditMode,
                    onEditPressed: () {
                      setState(() {
                        petEditMode = !petEditMode;
                      });
                    },
                    maxLines: 5,
                  ),
                ],

                const SizedBox(height: 20),

                // Approve Button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text(widget.isUser ? 'Approve User' : 'Approve Pet'),
                    onPressed: _approveUser,
                  ),
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

  // Function to select a new profile image
  Future<void> _selectProfileImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      String filePath = result.files.single.path!;
      setState(() {
        profileImageUrl = filePath;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  // Function to delete the user or pet
  void _deleteUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Function to approve the user or pet
  void _approveUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Approved Successfully')),
    );
  }
}
