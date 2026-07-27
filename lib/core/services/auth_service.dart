import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 2. Login User
  Future<void> loginUser({
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
        throw 'No account found with this email address.';
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final storedPasswordHash = userData['passwordHash'] as String?;
      final providedPasswordHash = _hashPassword(password);

      if (storedPasswordHash == null || storedPasswordHash.isEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );

        await userDoc.reference.update({
          'passwordHash': providedPasswordHash,
          'passwordUpdatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      if (storedPasswordHash != providedPasswordHash) {
        throw 'Invalid email or password.';
      }

      return;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed. Please check your credentials.';
    } catch (e) {
      throw 'An error occurred during login: ${e.toString()}';
    }
  }

  // 3. Verify Security Answer
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
