import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BuyerAuthService {
  final firebaseAuth = FirebaseAuth.instance;
  final firestoredb = FirebaseFirestore.instance;
  void userregister({
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
}
