import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserEdit extends StatefulWidget {
  final String name;
  final String position;

  const UserEdit({
    super.key,
    required this.name,
    required this.position,
  });

  @override
  State<UserEdit> createState() => _UserEditState();
}

class _UserEditState extends State<UserEdit> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  bool nameEditMode = false;
  bool positionEditMode = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _positionController.text = widget.position;
  }

  // Function to save changes
  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.name)
          .update({
        'name': _nameController.text,
        'position': _positionController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
    } catch (e) {
      print('Error saving changes: $e');
    }
  }

  // Function to delete the user
  Future<void> _deleteUser() async {
    try {
      // Find the document ID using the user name
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('name', isEqualTo: widget.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document ID
        final docId = querySnapshot.docs.first.id;

        // Delete the user document using the document ID
        await FirebaseFirestore.instance.collection('user').doc(docId).delete();
        print('User deleted: ${widget.name}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );

        // Close the current screen and return true to indicate success
        Navigator.pop(context, true);
      } else {
        print('User not found: ${widget.name}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      print('Error deleting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  // Function to approve the user
  Future<void> _approveUser() async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.name)
          .update({'approved': true});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved successfully!')),
      );
    } catch (e) {
      print('Error approving user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Edit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteUser,
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
                // Position Field
                _buildLabelTextField(
                  label: 'Position',
                  controller: _positionController,
                  editMode: positionEditMode,
                  onEditPressed: () {
                    setState(() {
                      positionEditMode = !positionEditMode;
                    });
                  },
                ),
                const SizedBox(height: 20),
                // Approve Button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve User'),
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
}
