import 'package:flutter/material.dart';

class ForgetScreen extends StatefulWidget {
  const ForgetScreen({super.key});

  @override
  State<ForgetScreen> createState() => _ForgetScreenState();
}

class _ForgetScreenState extends State<ForgetScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordChangeVisible =
      false; // To control the visibility of password change fields
  bool _isLoading = false; // To control the loading state

  // Validator functions
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    const emailPattern = r'^[^@]+@[^@]+\.[^@]+';
    final regExp = RegExp(emailPattern);
    if (!regExp.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    } else if (value.length != 5) {
      return 'OTP must be 5 digits';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required';
    } else if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _changePasswordHandler() {
    setState(() {
      _isPasswordChangeVisible = true; // Show the new password fields
    });
  }

  void _updatePassword() async {
    if (_newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      // Simulate a password update process (replace with real logic)
      await Future.delayed(const Duration(seconds: 3)); // Simulate delay

      setState(() {
        _isLoading =
            false; // Hide loading indicator after the operation is complete
      });

      // You can implement the password update logic here.
      print("Password updated successfully");
      // After updating the password, you can navigate to another screen or display a success message.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forget Password'),
        backgroundColor:
            const Color(0xFFFFA726), // Consistent color theme for the AppBar
      ),
      backgroundColor: const Color(0xFFFFD194), // Set background color for the entire screen
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFD194), // Light orange
              Color(0xFFFFC3A0), // Soft peach
              Color(0xFFF8A170), // Warm sunset
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Email TextField
                  if (!_isPasswordChangeVisible)
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: _validateEmail,
                    ),
                  const SizedBox(height: 20),

                  // OTP TextField (only visible before password change)
                  if (!_isPasswordChangeVisible)
                    TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'Enter OTP',
                        hintText: 'Enter 5-digit OTP',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLength: 5,
                      keyboardType: TextInputType.number,
                      validator: _validateOtp,
                    ),
                  const SizedBox(height: 20),

                  // Change Password Button
                  if (!_isPasswordChangeVisible)
                    ElevatedButton(
                      onPressed: _changePasswordHandler,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 32),
                        backgroundColor: const Color(0xFF2196F3), // Blue color
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Change Password'),
                    ),

                  // New Password TextField (visible after clicking "Change Password")
                  if (_isPasswordChangeVisible) ...[
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password TextField
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter new password',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      obscureText: true,
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 20),

                    // Update Button
                    ElevatedButton(
                      onPressed: _updatePassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 32),
                        backgroundColor: const Color(0xFF4CAF50), // Green color
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Update'),
                    ),
                  ],

                  // Loading Indicator
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
