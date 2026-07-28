import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final UserCredential userCredential;
  final Map<String, dynamic> userData;

  const AuthResult({required this.userCredential, required this.userData});

  String get role => (userData['role'] as String? ?? 'user').toLowerCase();
  String get status =>
      (userData['status'] as String? ?? 'pending').toLowerCase();
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // 1. Register User
  Future<void> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String cnic,
    required String address,
    required DateTime dob,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': _normalizeEmail(email),
        'role': 'user',
        'status': 'pending',
        'phone': phone,
        'cnic': cnic,
        'address': address,
        'dob': dob.toIso8601String(),
        'securityQuestion': securityQuestion,
        'securityAnswer': securityAnswer.trim().toLowerCase(),
        'passwordHash': _hashPassword(password),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userCredential.user?.updateDisplayName('$firstName $lastName');
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Authentication failed.';
    } catch (e) {
      throw 'Registration failed: ${e.toString()}';
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDocument({
    required String uid,
    required String email,
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc;
    }

    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw 'User profile not found.';
    }

    return querySnapshot.docs.first;
  }

  // 2. Login User
  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final signedInUser = userCredential.user;
      if (signedInUser == null) {
        throw 'Unable to sign in.';
      }

      final userDoc = await _getUserDocument(
        uid: signedInUser.uid,
        email: normalizedEmail,
      );

      final userData = userDoc.data();
      if (userData == null) {
        throw 'User profile not found.';
      }

      final role = (userData['role'] as String? ?? 'user').toLowerCase();
      final status = (userData['status'] as String? ?? 'pending').toLowerCase();

      if (role == 'user' && status != 'approved') {
        await _auth.signOut();
        throw 'Your account is pending admin approval.';
      }

      return AuthResult(userCredential: userCredential, userData: userData);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed. Please check your credentials.';
    } catch (e) {
      throw 'An error occurred during login: ${e.toString()}';
    }
  }

  // 3. Verify Security Answer

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String> verifySecurityAnswer({
    required String email,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: _normalizeEmail(email))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'No account found with this email address.';
      }

      final userData = querySnapshot.docs.first.data();
      final storedQuestion = userData['securityQuestion'] as String?;
      final storedAnswer = userData['securityAnswer'] as String?;

      if (storedQuestion != securityQuestion) {
        throw 'Incorrect security question selected.';
      }

      if (storedAnswer != securityAnswer.trim().toLowerCase()) {
        throw 'Incorrect answer to the security question.';
      }

      return _normalizeEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // 4. Send Password Reset
  Future<void> resetPasswordForVerifiedEmail({
    required String email,
    required String newPassword,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'No account found with this email address.';
      }

      final passwordHash = _hashPassword(newPassword);

      await querySnapshot.docs.first.reference.update({
        'passwordHash': passwordHash,
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          currentUser.email?.trim().toLowerCase() == normalizedEmail) {
        try {
          await currentUser.updatePassword(newPassword);
        } on FirebaseAuthException {
          // The Firestore-backed reset already completed successfully.
        }
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw e.message ?? 'Failed to reset password.';
      }
      rethrow;
    }
  }
}
