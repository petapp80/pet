import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/home.dart';

class BuyerAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if email exists in Firestore
  Future<bool> checkEmailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('user')
          .where('email', isEqualTo: email)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking email existence: $e');
      return false; // Consider the email does not exist if there's an error
    }
  }

  // Registration Function
  Future<void> registerUser({
    required BuildContext context,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Check if the email is already registered in Firestore
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        _showSnackBar(context, 'Email is already registered.');
        return;
      }

      // Create a new user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data to Firestore
      await _firestore.collection('user').doc(userCredential.user?.uid).set({
        'name': username,
        'email': email,
        'position': 'Buyer', // Default user position
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar(context, 'Registration successful.');
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthError(e);
      _showSnackBar(context, errorMessage);
    } catch (e) {
      _showSnackBar(context, 'An error occurred: ${e.toString()}');
    }
  }

  // Login Function
  Future<User?> loginUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate the user
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user exists in Firestore
      final userDoc = await _firestore
          .collection('user')
          .doc(userCredential.user?.uid)
          .get();

      if (!userDoc.exists) {
        _showSnackBar(context, 'User not found in Firestore.');
        return null;
      }

      _showSnackBar(context, 'Login successful.');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthError(e);
      _showSnackBar(context, errorMessage);
      return null;
    } catch (e) {
      _showSnackBar(context, 'An error occurred: ${e.toString()}');
      return null;
    }
  }

  // Utility Function: Show Snackbar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Utility Function: Handle Firebase Auth Errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'The email is already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
