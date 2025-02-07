import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:PetApp/user/screens/splashScreen.dart';
import 'package:PetApp/user/screens/themeProvider.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final isDarkTheme = prefs.getBool('isDarkTheme') ?? false;

  // For testing purposes: Clear shared preferences
  // await prefs.clear();

  if (prefs.getBool('isLoggedIn') == null) {
    await prefs.setBool('isLoggedIn', false);
  }

  runApp(MyApp(isDarkTheme: isDarkTheme));
}

class MyApp extends StatelessWidget {
  final bool isDarkTheme;

  const MyApp({super.key, required this.isDarkTheme});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(isDarkTheme),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.isDarkTheme
                ? ThemeData.dark()
                : ThemeData.light(),
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}