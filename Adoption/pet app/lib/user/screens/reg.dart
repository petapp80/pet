import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/services/Buyer_auth_service.dart';
import 'login screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool visible1 = true;
  bool visible2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
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
          ),

          // Main content with app bar and form
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.transparent,
                  child: Center(
                    child: Text(
                      'Sign Up',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circle Avatar with image
                            const Center(
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: AssetImage('asset/image/im.jpg'),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Username Field
                            TextFormField(
                              controller: _userNameController,
                              decoration: const InputDecoration(
                                labelText: 'User Name',
                                hintText: 'Enter your user name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email';
                                } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      visible1 = !visible1;
                                    });
                                  },
                                  icon: Icon(
                                    visible1
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              obscureText: visible1,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                } else if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmController,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Confirm password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.password),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      visible2 = !visible2;
                                    });
                                  },
                                  icon: Icon(
                                    visible2
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              obscureText: visible2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                } else if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),

                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  String email = _emailController.text;
                                  String password = _passwordController.text;
                                  print(
                                      'Sign up with email: $email, password: $password');

                                  BuyerAuthService().userregister(
                                    context: context,
                                    username: _userNameController.text,
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                    255, 255, 254, 253),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // "Already have an account?" text link
                            RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Login',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage(),
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
