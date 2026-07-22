import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Register User (Matches all fields from RegisterScreen)
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
      // Create Authentication User
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final String uid = userCredential.user!.uid;

      // Save complete profile data directly to Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email.trim(),
        'phone': phone,
        'cnic': cnic,
        'address': address,
        'dob': dob.toIso8601String(),
        'securityQuestion': securityQuestion,
        'securityAnswer': securityAnswer.trim().toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update Display Name in Firebase Auth Profile
      await userCredential.user?.updateDisplayName('$firstName $lastName');
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Authentication failed.';
    } catch (e) {
      throw 'Registration failed: ${e.toString()}';
    }
  }

  // 2. Login User
  Future<UserCredential> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed. Please check your credentials.';
    } catch (e) {
      throw 'An error occurred during login: ${e.toString()}';
    }
  }

  // 3. Verify Security Answer for Password Reset
  Future<String> verifySecurityAnswer({
    required String email,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
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

      return email.trim();
    } catch (e) {
      rethrow;
    }
  }

  // 4. Send Password Reset Email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to send password reset email.';
    } catch (e) {
      rethrow;
    }
  }

  // 5. Update Password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw 'User session expired. Please log in again.';
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to update password.';
    } catch (e) {
      rethrow;
    }
  }
}
