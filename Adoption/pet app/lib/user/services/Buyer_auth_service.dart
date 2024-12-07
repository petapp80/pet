import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/home.dart';

class BuyerAuthService {
  final firebaseAuth = FirebaseAuth.instance;
  final firestoredb = FirebaseFirestore.instance;

  // Registration Function
  Future<void> userregister({
    required BuildContext context,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final user = await firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      await firestoredb
          .collection('user')
          .doc(user.user?.uid)
          .set({'name': username, 'email': email});

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration Successful')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration Failed')));
    }
  }

  // Login Function
  Future<void> userLogin({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      // Query Firestore to find a user document with the matching email
      final userDoc = await firestoredb
          .collection('user')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isEmpty) {
        // If no matching email is found in Firestore
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Email not registered')));
        return;
      }

      // If the email exists, proceed to authenticate the password
      final user = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login Successful')));
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}')));
    }
  }
}
