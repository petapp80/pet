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
  final String? navigationSource;

  const ProfileScreen({super.key, this.navigationSource});

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
      setState(() {
        _userStream =
            FirebaseFirestore.instance.collection('user').doc(uid).snapshots();
      });
    }
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
          Widget profileContent;
          if (snapshot.connectionState == ConnectionState.waiting) {
            profileContent = _buildLoadingScreen();
          } else if (snapshot.hasError) {
            profileContent = _buildErrorScreen();
          } else if (snapshot.hasData && snapshot.data != null) {
            final profileData = snapshot.data!.data() as Map<String, dynamic>?;
            profileContent = profileData != null
                ? _buildProfileDetails(profileData)
                : _handleMissingProfileData();
          } else {
            profileContent = _handleMissingProfileData();
          }

          return Stack(
            children: [
              profileContent,
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildProfileOptions(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _handleMissingProfileData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    });
    return _buildNoProfileData();
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

  Widget _buildNoProfileData() {
    return Center(
      child: Text(
        'Profile data not found. Please try again later.',
        style: TextStyle(
          color: _isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildProfileDetails(Map<String, dynamic> profileData) {
    final userName = profileData['name'];
    final userEmail = profileData['email'];

    if (userName == null ||
        userEmail == null ||
        userName.isEmpty ||
        userEmail.isEmpty) {
      return _handleMissingProfileData();
    }

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 60,
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : (profileData['profileImage'] != null &&
                              profileData['profileImage'].isNotEmpty
                          ? NetworkImage(profileData['profileImage'])
                          : const AssetImage('asset/image/default_profile.png'))
                      as ImageProvider,
            ),
            const SizedBox(height: 20),
            Text(
              userName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              userEmail,
              style: TextStyle(
                fontSize: 16,
                color: _isDarkTheme ? Colors.white70 : Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileOption(
            icon: Icons.edit,
            title: 'Edit Profile',
            isDarkTheme: _isDarkTheme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfile()),
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
                MaterialPageRoute(builder: (context) => const ForgetScreen()),
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
                MaterialPageRoute(builder: (context) => const SettingScreen()),
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
                MaterialPageRoute(builder: (context) => const ReviewsScreen()),
              );
            },
          ),
          const Divider(),
          ProfileOption(
            icon: Icons.logout,
            title: 'Logout',
            isDarkTheme: _isDarkTheme,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
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
