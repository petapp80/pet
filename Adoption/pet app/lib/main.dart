import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/user/screens/appointmentScreen.dart';
import 'package:flutter_application_1/user/screens/login%20screen.dart';
import 'package:flutter_application_1/user/screens/profile.dart';
import 'package:flutter_application_1/user/screens/reg.dart';
import 'package:flutter_application_1/user/screens/veterinary.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart'; // Import for ChangeNotifierProvider
import 'package:shared_preferences/shared_preferences.dart';

import 'user/screens/editProfile.dart';
import 'user/screens/floatingbttn.dart';
import 'user/screens/productScreen.dart';
import 'user/screens/home.dart';
import 'user/screens/splashScreen.dart';
import 'user/screens/themeProvider.dart'; // Import the ThemeProvider

void main() async {
  // Ensure all bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Get saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDarkTheme = prefs.getBool('isDarkTheme') ?? false;

  // Run the app with the selected theme
  runApp(MyApp(isDarkTheme: isDarkTheme));
}

class MyApp extends StatelessWidget {
  final bool isDarkTheme;

  const MyApp({super.key, required this.isDarkTheme});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ThemeProvider(isDarkTheme), // Provide the theme state
      child: Consumer<ThemeProvider>(
        // Rebuild the app when theme changes
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.isDarkTheme
                ? ThemeData.dark()
                : ThemeData.light(),
            home: const SignUpPage(), // Replace with your starting page
          );
        },
      ),
    );
  }
}
