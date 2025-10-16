class SimpleAuthService {
  // Predefined users for the app
  static const Map<String, Map<String, String>> _users = {
    'shrivishnudigital@gmail.com': {
      'password': 'admin123',
      'name': 'Shrivi Shnu Digital',
      'role': 'admin',
    },
    'user2@example.com': {
      'password': 'user123',
      'name': 'User Two',
      'role': 'user',
    },
  };

  static String? _currentUser;
  static String? _currentUserName;
  static String? _currentUserRole;

  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;

  // Get current user email
  static String? get currentUser => _currentUser;

  // Get current user name
  static String? get currentUserName => _currentUserName;

  // Get current user role
  static String? get currentUserRole => _currentUserRole;

  // Sign in with email and password
  static bool signIn(String email, String password) {
    final user = _users[email.toLowerCase()];
    
    if (user != null && user['password'] == password) {
      _currentUser = email.toLowerCase();
      _currentUserName = user['name'];
      _currentUserRole = user['role'];
      return true;
    }
    return false;
  }

  // Sign out
  static void signOut() {
    _currentUser = null;
    _currentUserName = null;
    _currentUserRole = null;
  }

  // Get all users (for admin purposes)
  static Map<String, Map<String, String>> get allUsers => _users;

  // Check if current user is admin
  static bool get isAdmin => _currentUserRole == 'admin';
}


