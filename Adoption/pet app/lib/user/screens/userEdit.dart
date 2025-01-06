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
  bool isApproved = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _positionController.text = widget.position;
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('name', isEqualTo: widget.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docData = querySnapshot.docs.first.data();
        if (docData.containsKey('approved') && docData['approved'] == true) {
          setState(() {
            isApproved = true;
          });
        }
      }
    } catch (e) {
      print('Error checking approval status: $e');
    }
  }

  // Function to save changes to a specific field
  Future<void> _saveField(String fieldName, String value) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('name', isEqualTo: widget.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('user')
            .doc(docId)
            .update({fieldName: value});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      print('Error updating field: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating field: $e')),
      );
    }
  }

  // Function to delete the user
  Future<void> _deleteUser() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this user?'),
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
        final querySnapshot = await FirebaseFirestore.instance
            .collection('user')
            .where('name', isEqualTo: widget.name)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docId = querySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('user')
              .doc(docId)
              .delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );

          Navigator.pop(context, true);
        } else {
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
  }

  // Function to approve the user
  Future<void> _approveUser() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('name', isEqualTo: widget.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('user')
            .doc(docId)
            .update({'approved': true});
        setState(() {
          isApproved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      print('Error approving user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving user: $e')),
      );
    }
  }

  // Function to revoke user approval
  Future<void> _revokeApproval() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('name', isEqualTo: widget.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('user')
            .doc(docId)
            .update({'approved': false});
        setState(() {
          isApproved = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approval revoked successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      print('Error revoking user approval: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error revoking user approval: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Edit'),
        actions: [
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
                  label: 'Position',
                  controller: _positionController,
                  editMode: positionEditMode,
                  onEditPressed: () {
                    setState(() {
                      positionEditMode = !positionEditMode;
                      if (!positionEditMode) {
                        _saveField('position', _positionController.text);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: isApproved
                        ? const Text('Revoke Approval')
                        : const Text('Approve User'),
                    onPressed: isApproved ? _revokeApproval : _approveUser,
                  ),
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
