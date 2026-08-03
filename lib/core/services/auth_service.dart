import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final UserCredential? userCredential;
  final Map<String, dynamic> userData;

  const AuthResult({this.userCredential, required this.userData});

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
    required String sex,
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
        'sex': sex,
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

  // 2. Login User
  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);

      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'User profile not found.';
      }

      final userData = querySnapshot.docs.first.data();

      // Check hashed password
      final inputPasswordHash = _hashPassword(password);
      final storedPasswordHash = userData['passwordHash'] as String?;

      if (storedPasswordHash != null &&
          storedPasswordHash != inputPasswordHash) {
        throw 'Incorrect email or password.';
      }

      // Check account status
      final status = (userData['status'] as String? ?? 'pending').toLowerCase();
      if (status != 'approved') {
        await _auth.signOut();
        if (status == 'pending') {
          throw 'Your account is pending admin approval.';
        }
        throw 'Your access has been revoked. Please contact an administrator.';
      }

      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } catch (_) {
        // Fallback to Firestore password validation if Firebase Auth is out of sync
      }

      return AuthResult(userCredential: userCredential, userData: userData);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed. Please check your credentials.';
    } catch (e) {
      throw e.toString();
    }
  }

  // 3. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. Verify Security Answer (Optimized for Firestore Rules)
  Future<String> verifySecurityAnswer({
    required String email,
    required String securityQuestion,
    required String securityAnswer,
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

      final userData = querySnapshot.docs.first.data();
      final storedQuestion = userData['securityQuestion'] as String?;
      final storedAnswer = userData['securityAnswer'] as String?;

      if (storedQuestion != securityQuestion) {
        throw 'Incorrect security question selected.';
      }

      if (storedAnswer != securityAnswer.trim().toLowerCase()) {
        throw 'Incorrect answer to the security question.';
      }

      return normalizedEmail;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw 'Permission denied. Please ensure your Firestore Security Rules are published.';
      }
      rethrow;
    }
  }

  // 5. Reset Password for Verified Email
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

      final docId = querySnapshot.docs.first.id;
      final passwordHash = _hashPassword(newPassword);

      // Direct document update by ID bypasses collection query restriction
      await _firestore.collection('users').doc(docId).update({
        'passwordHash': passwordHash,
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
