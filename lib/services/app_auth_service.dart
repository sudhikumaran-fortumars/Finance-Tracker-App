import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

class AppAuthService {
  static final AppAuthService _instance = AppAuthService._internal();
  factory AppAuthService() => _instance;
  AppAuthService._internal();

  static AppAuthService get instance => _instance;

  AppUser? _currentUser;
  bool _isLoggedIn = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  UserRole? get currentUserRole => _currentUser?.role;

  // ==================== AUTHENTICATION ====================

  /// Initialize the app with default users
  Future<void> initializeApp() async {
    try {
      // Check if users exist, if not create default users
      final users = await getAppUsers();
      if (users.isEmpty) {
        await _createDefaultUsers();
      }
    } catch (e) {
      print('Error initializing app: $e');
    }
  }

  /// Create default owner and staff users
  Future<void> _createDefaultUsers() async {
    final owner = AppUser(
      id: 'owner_001',
      username: 'owner',
      email: 'owner@financetracker.com',
      password: 'owner123', // In production, hash this
      role: UserRole.owner,
      fullName: 'Business Owner',
      phoneNumber: '+1234567890',
      createdAt: DateTime.now(),
    );

    final staff = AppUser(
      id: 'staff_001',
      username: 'staff',
      email: 'staff@financetracker.com',
      password: 'staff123', // In production, hash this
      role: UserRole.staff,
      fullName: 'Staff Member',
      phoneNumber: '+1234567891',
      createdAt: DateTime.now(),
    );

    await saveAppUser(owner);
    await saveAppUser(staff);
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    try {
      final users = await getAppUsers();
      final user = users.firstWhere(
        (user) => user.username == username && user.password == password,
        orElse: () => throw Exception('User not found'),
      );

      if (!user.isActive) {
        throw Exception('User account is deactivated');
      }

      // Update last login
      final updatedUser = user.copyWith(
        lastLoginAt: DateTime.now(),
      );
      await saveAppUser(updatedUser);

      _currentUser = updatedUser;
      _isLoggedIn = true;

      // Save login state
      await _saveLoginState(updatedUser);

      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    await _clearLoginState();
  }

  /// Check if user is logged in from saved state
  Future<bool> checkLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        final userData = json.decode(userJson);
        final user = AppUser.fromJson(userData);
        
        // Verify user still exists and is active
        final users = await getAppUsers();
        final currentUser = users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => throw Exception('User not found'),
        );

        if (currentUser.isActive) {
          _currentUser = currentUser;
          _isLoggedIn = true;
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking login state: $e');
      return false;
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Save app user to storage
  Future<void> saveAppUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await getAppUsers();
      
      // Update existing user or add new user
      final existingIndex = users.indexWhere((u) => u.id == user.id);
      if (existingIndex != -1) {
        users[existingIndex] = user;
      } else {
        users.add(user);
      }
      
      final usersJson = users.map((u) => u.toJson()).toList();
      await prefs.setString('app_users', json.encode(usersJson));
    } catch (e) {
      print('Error saving app user: $e');
    }
  }

  /// Get all app users
  Future<List<AppUser>> getAppUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('app_users');
      
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        return usersList.map((userData) => AppUser.fromJson(userData)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting app users: $e');
      return [];
    }
  }

  /// Get user by ID
  Future<AppUser?> getAppUserById(String id) async {
    try {
      final users = await getAppUsers();
      return users.firstWhere(
        (user) => user.id == id,
        orElse: () => throw Exception('User not found'),
      );
    } catch (e) {
      print('Error getting app user by ID: $e');
      return null;
    }
  }

  /// Update user password
  Future<bool> updatePassword(String userId, String oldPassword, String newPassword) async {
    try {
      final user = await getAppUserById(userId);
      if (user == null || user.password != oldPassword) {
        return false;
      }

      final updatedUser = user.copyWith(password: newPassword);
      await saveAppUser(updatedUser);
      
      // Update current user if it's the same user
      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
      }
      
      return true;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(String userId, {
    String? fullName,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final user = await getAppUserById(userId);
      if (user == null) return false;

      final updatedUser = user.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
      );
      
      await saveAppUser(updatedUser);
      
      // Update current user if it's the same user
      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
      }
      
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // ==================== ROLE-BASED ACCESS ====================

  /// Check if current user can perform action
  bool canPerformAction(String action) {
    if (!_isLoggedIn || _currentUser == null) return false;

    switch (action) {
      case 'manage_users':
        return _currentUser!.role.canManageUsers;
      case 'view_reports':
        return _currentUser!.role.canViewReports;
      case 'manage_schemes':
        return _currentUser!.role.canManageSchemes;
      case 'send_whatsapp':
        return _currentUser!.role.canSendWhatsApp;
      case 'view_analytics':
        return _currentUser!.role.canViewAnalytics;
      default:
        return false;
    }
  }

  /// Check if current user is owner
  bool get isOwner => _currentUser?.role == UserRole.owner;

  /// Check if current user is staff
  bool get isStaff => _currentUser?.role == UserRole.staff;

  // ==================== PRIVATE METHODS ====================

  /// Save login state to storage
  Future<void> _saveLoginState(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(user.toJson()));
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      print('Error saving login state: $e');
    }
  }

  /// Clear login state from storage
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.setBool('is_logged_in', false);
    } catch (e) {
      print('Error clearing login state: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get user display name
  String getUserDisplayName() {
    if (_currentUser == null) return 'Unknown User';
    return _currentUser!.fullName ?? _currentUser!.username;
  }

  /// Get user role display name
  String getUserRoleDisplayName() {
    if (_currentUser == null) return 'Unknown Role';
    return _currentUser!.role.displayName;
  }

  /// Check if user has specific role
  bool hasRole(UserRole role) {
    return _currentUser?.role == role;
  }

  /// Get user permissions summary
  Map<String, bool> getUserPermissions() {
    if (_currentUser == null) return {};

    return {
      'manage_users': _currentUser!.role.canManageUsers,
      'view_reports': _currentUser!.role.canViewReports,
      'manage_schemes': _currentUser!.role.canManageSchemes,
      'send_whatsapp': _currentUser!.role.canSendWhatsApp,
      'view_analytics': _currentUser!.role.canViewAnalytics,
    };
  }
}

