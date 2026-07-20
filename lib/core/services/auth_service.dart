import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. SIGN UP (WITH SECURITY QUESTION)
  Future<void> registerUser({
    required String email,
    required String password,
    required String securityAnswer,
  }) async {
    try {
      // Create account in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Save user email & security answer (in lowercase for easy matching) in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email.trim().toLowerCase(),
          'securityAnswer': securityAnswer.trim().toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Registration failed.";
    } catch (e) {
      throw "An unexpected error occurred.";
    }
  }

  // 2. LOG IN
  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Login failed.";
    }
  }

  // 3. VERIFY SECURITY ANSWER & RESET PASSWORD
  Future<void> verifyAnswerAndResetPassword({
    required String email,
    required String securityAnswer,
  }) async {
    try {
      // Find user document by email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw "No user account found with this email.";
      }

      final userData = querySnapshot.docs.first.data();
      final storedAnswer = userData['securityAnswer'] as String?;

      // Check if provided answer matches stored answer
      if (storedAnswer == null ||
          storedAnswer.trim().toLowerCase() !=
              securityAnswer.trim().toLowerCase()) {
        throw "Incorrect security answer. Please try again.";
      }

      // If answer is correct, send password reset link via Firebase Auth
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Failed to send reset request.";
    }
  }
}
