import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/reg.dart';
import 'dart:async';

import 'home.dart'; // Update this import to match your actual file location.

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showText = false; // To control when to show the text
  bool _isGifFinished = false; // To track if the GIF has finished
  double _opacity = 0.0; // To control the opacity of the text

  @override
  void initState() {
    super.initState();

    // Simulate the GIF finish after 3 seconds (adjust this duration as needed)
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _showText = true;
      });

      // Animate the text opacity
      Future.delayed(Duration(milliseconds: 100), () {
        setState(() {
          _opacity = 1.0; // Fade in the text
        });
      });

      // Simulate GIF finish and navigate to the next screen
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          _isGifFinished = true;
        });

        // Navigate to the next screen after a delay
        Future.delayed(Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignUpPage()),
          );
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to pure white
      body: Stack(
        children: [
          // Fullscreen GIF
          Positioned.fill(
            child: Center(
              child: Image.asset(
                'asset/image/intro.gif', // Make sure your GIF file is located here
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Text with cool animation
          AnimatedOpacity(
            opacity: _opacity,
            duration: Duration(seconds: 2), // Animation duration
            child: Align(
              alignment:
                  Alignment(0.0, -0.4), // Adjust vertical position of text
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  color: Colors.white.withOpacity(
                      0.6), // Semi-transparent white background for the text
                  child: Text(
                    'PetApp!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          Colors.black, // Set text color to black for contrast
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.6),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
