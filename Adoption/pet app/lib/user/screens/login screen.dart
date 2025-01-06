import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/forgetScreen.dart';
import 'package:flutter_application_1/user/screens/home.dart';
import 'package:flutter_application_1/user/screens/productScreen.dart';
import 'package:flutter_application_1/user/screens/veterinary.dart';
import 'package:flutter_application_1/user/services/Buyer_auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adminScreen.dart'; // Import your AdminPage
import 'reg.dart'; // Import your SignUpPage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Validate email format
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

  // Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> loginHandler() async {
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        loading = true;
      });

      String email = _emailController.text.trim();
      String password = _passwordController.text;

      try {
        // Check if the email belongs to an admin
        QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('email', isEqualTo: email)
            .get();

        if (adminSnapshot.docs.isNotEmpty) {
          // Admin credentials
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
          if (userCredential.user != null) {
            setState(() {
              loading = false;
            });

            // Save login state
            final prefs = await SharedPreferences.getInstance();
            prefs.setBool('isLoggedIn', true);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminPage()),
              (route) => false,
            );
            return;
          }
        }

        // Authenticate user using BuyerAuthService
        final User? user = await BuyerAuthService().loginUser(
          context: context,
          email: email,
          password: password,
        );
        if (user != null) {
          // Fetch user document from Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('user')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            // Get position field from Firestore
            String? position = userDoc['position'];

            setState(() {
              loading = false;
            });

            // Save login state
            final prefs = await SharedPreferences.getInstance();
            prefs.setBool('isLoggedIn', true);

            // Redirect based on user position
            if (position == 'Buyer') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (position == 'Seller') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProductsScreen()),
              );
            } else if (position == 'Veterinary') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const VeterinaryScreen()),
              );
            } else if (position == 'Buyer-Seller') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (position == 'Buyer-Veterinary') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unknown user position')),
              );
            }
          } else {
            setState(() {
              loading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User data not found in Firestore')),
            );
          }
        } else {
          setState(() {
            loading = false;
          });
        }
      } catch (e) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Here, we wrap the LoginPage with a Theme widget to bypass the system's theme
    return Theme(
      data: ThemeData(
        brightness: Brightness.light, // Ensure light theme is used
        primaryColor: const Color(0xFF512DA8),
        scaffoldBackgroundColor:
            const Color(0xFFE1BEE7), // Background color for the screen
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(),
          prefixIconColor: Colors.black,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF512DA8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          ),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE1BEE7), // Light orange
                    Color(0xFFCE93D8), // Soft peach
                    Color(0xFFBA68C8), // Warm sunset
                  ],
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          backgroundImage: AssetImage('asset/image/intro.gif'),
                          radius: 60,
                        ),
                        const SizedBox(height: 30),

                        // Email TextField with validation
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email, color: Colors.black),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 20),

                        // Password TextField with validation
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.lock, color: Colors.black),
                          ),
                          obscureText: true,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 20),

                        // Sign In Button
                        ElevatedButton(
                          onPressed: loginHandler,
                          child: const Text('Sign In'),
                        ),
                        const SizedBox(height: 20),

                        // "Forgot Password?" Text
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ForgetScreen()),
                            );
                          },
                          child: const Text('Forgot Password?'),
                        ),
                        const SizedBox(height: 20),

                        // "Don't have an account? Sign Up" link
                        RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
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
                                              const SignUpPage()),
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
            // Loading Overlay
            if (loading)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Lottie.asset('asset/image/loading.json'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
