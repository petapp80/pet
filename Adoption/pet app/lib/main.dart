import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/forgetScreen.dart';
import 'package:flutter_application_1/user/screens/login%20screen.dart';
import 'package:flutter_application_1/user/screens/productScreen.dart';
import 'package:flutter_application_1/user/screens/profile.dart';
import 'package:flutter_application_1/user/screens/reg.dart';
import 'package:flutter_application_1/user/screens/selectUser.dart';
import 'package:flutter_application_1/user/screens/splashScreen.dart';
import 'package:flutter_application_1/user/screens/veterinary.dart';
import 'package:firebase_core/firebase_core.dart'; // Ensure Firebase is imported
import 'firebase_options.dart'; // Import Firebase options

void main() async {
  // Ensure all bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignUpPage(),
    ),
  );
}
