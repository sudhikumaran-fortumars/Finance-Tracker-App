import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    AuthService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.signIn(
        email: email,
        password: password,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Sign out
  Future<bool> signOut() async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.signOut();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.sendEmailVerification();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.sendPasswordResetEmail(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.updatePassword(newPassword);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Update display name
  Future<bool> updateDisplayName(String displayName) async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.updateDisplayName(displayName);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.deleteAccount();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await AuthService.getUserData();
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Update user data
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError(null);

      await AuthService.updateUserData(data);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }
}


