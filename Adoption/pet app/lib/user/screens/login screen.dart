import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/forgetScreen.dart';
import 'package:flutter_application_1/user/screens/home.dart';
import 'package:flutter_application_1/user/services/Buyer_auth_service.dart';
import 'package:lottie/lottie.dart';
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
  final TextEditingController _otpController =
      TextEditingController(); // OTP controller
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Helper function to validate email format
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

  // Helper function to validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  // Helper function to validate OTP
  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    } else if (value.length != 5) {
      return 'OTP must be 5 digits';
    }
    return null;
  }

  void login_Handler() async {
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        loading = true;
      });
      String email = _emailController.text.trim();
      String password = _passwordController.text;

      // Check for specific credentials
      if (email == 'p@gmail.com' && password == '1') {
        // Redirect to AdminPage if credentials match
        await Future.delayed(const Duration(seconds: 2)); // Simulate delay
        setState(() {
          loading = false;
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminPage(),
          ),
          (route) => false,
        );
      } else {
        // Redirect to HomePage for all other credentials
        await BuyerAuthService().userLogin(
            context: context,
            email: _emailController.text,
            password: _passwordController.text);

        setState(() {
          loading = false;
        });
      }
    }
  }

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
                      const Center(
                        child: CircleAvatar(
                          backgroundImage: AssetImage('asset/image/intro.gif'),
                          radius: 60,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // OTP TextField with 5 digit validation

                      const SizedBox(height: 20),

                      // Email TextField with validation
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
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20),

                      // Password TextField with validation
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 20),

                      // Sign In Button with credential check
                      ElevatedButton(
                        onPressed: login_Handler,
                        style: ElevatedButton.styleFrom(
                          shadowColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 32),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Sign In'),
                      ),
                      const SizedBox(height: 20),

                      // "Forgot Password?" Text
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ForgetScreen()));
                          print('Forgot Password? clicked');
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // "Don't have an account? Sign Up" link
                      Center(
                        child: RichText(
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
              color: Colors.black.withOpacity(0.6), // Dark overlay
              child: Center(
                child: SizedBox(
                  width: 350,
                  height: 350,
                  child: Lottie.asset(
                      'asset/image/loading.json'), // Replace with your Lottie JSON file path
                ),
              ),
            ),
        ],
      ),
    );
  }
}
