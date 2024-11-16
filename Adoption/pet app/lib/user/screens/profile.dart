import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/login%20screen.dart';
import 'package:file_picker/file_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User profile details (initial data)
  String _name = 'John Doe';
  String _email = 'johndoe@example.com';
  String _password = '********';
  String? _profileImagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Profile Icon
            CircleAvatar(
              radius: 60,
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : const AssetImage('asset/image/dog1.png') as ImageProvider,
            ),
            const SizedBox(height: 20),
            // Username
            Text(
              _name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            // Email
            Text(
              _email,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            // Options Box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ProfileOption(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    onTap: () {
                      // Open Edit Profile Dialog
                      showDialog(
                        context: context,
                        builder: (context) => EditProfileDialog(
                          name: _name,
                          email: _email,
                          profileImagePath: _profileImagePath,
                          onSave: (newName, newEmail, newPassword,
                              newProfileImagePath) {
                            setState(() {
                              _name = newName;
                              _email = newEmail;
                              _password = newPassword;
                              _profileImagePath = newProfileImagePath;
                            });
                            Navigator.pop(context); // Close dialog
                          },
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ProfileOption(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      // Handle Settings Tap
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings clicked')),
                      );
                    },
                  ),
                  const Divider(),
                  ProfileOption(
                    icon: Icons.support_agent,
                    title: 'Support',
                    onTap: () {
                      // Handle Support Tap
                    },
                  ),
                  const Divider(),
                  ProfileOption(
                    icon: Icons.feedback_outlined,
                    title: 'Feedback',
                    onTap: () {
                      // Open Feedback Dialog
                      showDialog(
                        context: context,
                        builder: (context) => FeedbackDialog(),
                      );
                    },
                  ),
                  const Divider(),
                  ProfileOption(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      // Handle Logout and navigate to Login page, remove all routes
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                        (route) => false, // This removes all previous routes
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Edit Profile Dialog
class EditProfileDialog extends StatefulWidget {
  final String name;
  final String email;
  final String? profileImagePath;
  final Function(String, String, String, String?) onSave;

  const EditProfileDialog({
    super.key,
    required this.name,
    required this.email,
    required this.profileImagePath,
    required this.onSave,
  });

  @override
  _EditProfileDialogState createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _selectedProfileImagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController();
    _selectedProfileImagePath = widget.profileImagePath;
  }

  Future<void> _pickImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        _selectedProfileImagePath = result.files.single.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Image Selection
            if (_selectedProfileImagePath != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(
                    File(_selectedProfileImagePath!),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedProfileImagePath = null;
                      });
                    },
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Select Profile Picture'),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              _nameController.text,
              _emailController.text,
              _passwordController.text,
              _selectedProfileImagePath,
            );
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

// Feedback Dialog
class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  double _rating = 3.0; // Default rating
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Feedback'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rate our app:'),
            const SizedBox(height: 10),
            // Rating Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 10),
            // Comment Input Field
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Leave a comment...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final feedback = {
              'rating': _rating,
              'comment': _commentController.text,
            };
            // Print feedback to console (replace with actual submission logic)
            print('Feedback submitted: $feedback');
            Navigator.pop(context);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
