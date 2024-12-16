import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'editProfile.dart';
import 'forgetScreen.dart';
import 'login screen.dart';
import 'reviewScreen.dart';
import 'settings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImagePath;
  bool _isDarkTheme = false;
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initializeUserStream();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = value;
    });
    prefs.setBool('isDarkTheme', value);
  }

  void _initializeUserStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userStream =
          FirebaseFirestore.instance.collection('user').doc(uid).snapshots();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeUserStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: _isDarkTheme ? Colors.black : Colors.teal,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          } else if (snapshot.hasError) {
            return _buildErrorScreen();
          } else if (snapshot.hasData && snapshot.data != null) {
            final profileData = snapshot.data!.data() as Map<String, dynamic>?;

            if (profileData == null) {
              return Center(
                child: Text(
                  'Profile data not found',
                  style: TextStyle(
                    color: _isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              );
            }

            return _buildProfileContent(profileData);
          } else {
            return Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  color: _isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: _isDarkTheme
          ? Colors.black.withOpacity(0.6)
          : Colors.white.withOpacity(0.6),
      child: Center(
        child: Lottie.asset(
          'asset/image/loading.json',
          width: 150,
          height: 150,
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: _isDarkTheme
          ? Colors.black.withOpacity(0.6)
          : Colors.white.withOpacity(0.6),
      child: Center(
        child: Lottie.asset(
          'asset/image/error.json',
          width: 150,
          height: 150,
        ),
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> profileData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          CircleAvatar(
            radius: 60,
            backgroundImage: _profileImagePath != null
                ? FileImage(
                    File(_profileImagePath!)) // Show local image before upload
                : (profileData['profileImage'] != null &&
                            profileData['profileImage'].isNotEmpty
                        ? NetworkImage(
                            profileData['profileImage']) // Show uploaded image
                        : AssetImage(
                            'asset/image/care.jpg') // Placeholder image
                    ) as ImageProvider,
          ),
          const SizedBox(height: 20),
          Text(
            profileData['name'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            profileData['email'] ?? 'Email not available',
            style: TextStyle(
              fontSize: 16,
              color: _isDarkTheme ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          _buildProfileOptions(),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _isDarkTheme ? Colors.grey[850] : Colors.white,
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
            isDarkTheme: _isDarkTheme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfile(),
                ),
              );
            },
          ),
          const Divider(),
          ProfileOption(
            icon: Icons.password,
            title: 'Edit Password',
            isDarkTheme: _isDarkTheme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForgetScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ProfileOption(
            icon: Icons.settings,
            title: 'Settings',
            isDarkTheme: _isDarkTheme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ProfileOption(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            isDarkTheme: _isDarkTheme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReviewsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ProfileOption(
            icon: Icons.logout,
            title: 'Logout',
            isDarkTheme: _isDarkTheme,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDarkTheme;
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: isDarkTheme ? Colors.white : Colors.blue),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
