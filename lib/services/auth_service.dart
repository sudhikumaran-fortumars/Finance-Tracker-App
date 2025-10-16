import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Check if email is verified
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Send email verification
      await credential.user?.sendEmailVerification();

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user?.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
      } else {
        throw Exception('No user logged in or email already verified');
      }
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Update password
  static Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser != null) {
        await currentUser!.updatePassword(newPassword);
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Update display name
  static Future<void> updateDisplayName(String displayName) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        
        // Update in Firestore
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'displayName': displayName,
        });
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }

  // Delete user account
  static Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(currentUser!.uid).delete();
        
        // Delete user account
        await currentUser!.delete();
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'invalid-credential':
        return 'Invalid credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        if (doc.exists) {
          return doc.data();
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data in Firestore
  static Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(data);
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }
}


