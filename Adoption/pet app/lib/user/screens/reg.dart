import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/login%20screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Create controllers for the text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // GlobalKey for form validation
  final _formKey = GlobalKey<FormState>();

  bool visible1 = true;
  bool visible2 = true;

  void SignUpHandler() {
    // If form is valid, you can process the sign-up logic
    if (_formKey.currentState!.validate()) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return MyLoginScreen();
        },
      ));
      String email = _emailController.text;
      String password = _passwordController.text;
      String username = _userNameController.text;
      print(
          'Sign Up with Username: $username, Email: $email, Password: $password');
      // Call your sign-up logic here, e.g., API call
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey, // Key for the form to manage state
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Centered Circle Avatar with the image
                Center(
                  child: CircleAvatar(
                    radius: 60, // Size of the avatar
                    backgroundImage:
                        AssetImage('asset/image/logo-png.png'), // Correct path
                  ),
                ),
                const SizedBox(height: 20), // Space between image and form

                // UserName Field with validation
                TextFormField(
                  controller: _userNameController,
                  decoration: const InputDecoration(
                    labelText: 'User Name',
                    hintText: 'Enter your user name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field with validation
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // Space between fields

                // Password Field with validation
                TextFormField(
                  controller: _passwordController,
                  obscureText: visible1,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          visible1 = !visible1;
                        });
                      },
                      icon: Icon(
                          visible1 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password Field with validation
                TextFormField(
                  controller: _confirmController,
                  obscureText: visible2,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.password),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          visible2 = !visible2;
                        });
                      },
                      icon: Icon(
                          visible2 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Sign Up Button
                ElevatedButton(
                  onPressed: SignUpHandler,
                  child: const Text('Sign Up'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
