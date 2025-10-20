import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';

class RoleAuthService {
  static const String _userRoleKey = 'user_role';
  static const String _isLoggedInKey = 'is_logged_in';
  
  // Predefined credentials
  static const Map<String, Map<String, dynamic>> _credentials = {
    'admin': {
      'password': 'admin123',
      'role': 'admin',
      'name': 'Administrator',
    },
    'staff': {
      'password': 'staff123',
      'role': 'staff',
      'name': 'Staff Member',
    },
  };

  static Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_credentials.containsKey(username)) {
      final userData = _credentials[username]!;
      if (userData['password'] == password) {
        // Store login state
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userRoleKey, userData['role'] as String);
        await prefs.setString('user_name', userData['name']);
        return true;
      }
    }
    return false;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<UserRole?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_userRoleKey);
    if (roleString != null) {
      switch (roleString) {
        case 'admin':
          return UserRole.admin;
        case 'staff':
          return UserRole.staff;
        default:
          return UserRole.staff;
      }
    }
    return null;
  }

  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove('user_name');
  }

  static Map<String, String> getLoginCredentials() {
    return {
      'Admin Username': 'admin',
      'Admin Password': 'admin123',
      'Staff Username': 'staff',
      'Staff Password': 'staff123',
    };
  }
}
