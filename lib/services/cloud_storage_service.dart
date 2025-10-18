import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scheme_type.dart';
import '../models/user.dart';
import '../models/user_scheme.dart';
import '../models/transaction.dart';
import '../models/dashboard_stats.dart';
import '../models/notification_config.dart';
import '../models/notification.dart';
import '../models/report_filter.dart';

class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  static CloudStorageService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Initialize with offline support
  Future<void> initialize() async {
    // Enable offline persistence
    await _firestore.enablePersistence();
  }

  // ==================== USERS ====================

  /// Save user to Firestore with offline backup
  Future<void> saveUser(User user) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('customers')
          .doc(user.id)
          .set(user.toJson());

      // Backup to local storage
      await _saveUserLocally(user);
    } catch (e) {
      // Fallback to local storage
      await _saveUserLocally(user);
      throw Exception('Failed to save user: $e');
    }
  }

  /// Get users from Firestore with offline fallback
  Future<List<User>> getUsers() async {
    try {
      if (!isAuthenticated) {
        return await _getUsersLocally();
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('customers')
          .get();

      final users = snapshot.docs
          .map((doc) => User.fromJson(doc.data()))
          .toList();

      // Update local cache
      await _saveUsersLocally(users);
      return users;
    } catch (e) {
      // Fallback to local storage
      return await _getUsersLocally();
    }
  }

  /// Real-time users stream
  Stream<List<User>> getUsersStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('customers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromJson(doc.data()))
            .toList());
  }

  // ==================== TRANSACTIONS ====================

  /// Save transaction to Firestore with offline backup
  Future<void> saveTransaction(Transaction transaction) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());

      // Backup to local storage
      await _saveTransactionLocally(transaction);
    } catch (e) {
      // Fallback to local storage
      await _saveTransactionLocally(transaction);
      throw Exception('Failed to save transaction: $e');
    }
  }

  /// Get transactions from Firestore with offline fallback
  Future<List<Transaction>> getTransactions() async {
    try {
      if (!isAuthenticated) {
        return await _getTransactionsLocally();
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      final transactions = snapshot.docs
          .map((doc) => Transaction.fromJson(doc.data()))
          .toList();

      // Update local cache
      await _saveTransactionsLocally(transactions);
      return transactions;
    } catch (e) {
      // Fallback to local storage
      return await _getTransactionsLocally();
    }
  }

  /// Real-time transactions stream
  Stream<List<Transaction>> getTransactionsStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromJson(doc.data()))
            .toList());
  }

  // ==================== USER SCHEMES ====================

  /// Save user scheme to Firestore with offline backup
  Future<void> saveUserScheme(UserScheme scheme) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('schemes')
          .doc(scheme.id)
          .set(scheme.toJson());

      // Backup to local storage
      await _saveUserSchemeLocally(scheme);
    } catch (e) {
      // Fallback to local storage
      await _saveUserSchemeLocally(scheme);
      throw Exception('Failed to save scheme: $e');
    }
  }

  /// Get user schemes from Firestore with offline fallback
  Future<List<UserScheme>> getUserSchemes() async {
    try {
      if (!isAuthenticated) {
        return await _getUserSchemesLocally();
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('schemes')
          .get();

      final schemes = snapshot.docs
          .map((doc) => UserScheme.fromJson(doc.data()))
          .toList();

      // Update local cache
      await _saveUserSchemesLocally(schemes);
      return schemes;
    } catch (e) {
      // Fallback to local storage
      return await _getUserSchemesLocally();
    }
  }

  /// Real-time user schemes stream
  Stream<List<UserScheme>> getUserSchemesStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('schemes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserScheme.fromJson(doc.data()))
            .toList());
  }

  // ==================== SCHEME TYPES ====================

  /// Get scheme types (these are global, not user-specific)
  Future<List<SchemeType>> getSchemeTypes() async {
    try {
      final snapshot = await _firestore
          .collection('scheme_types')
          .get();

      if (snapshot.docs.isEmpty) {
        // Initialize with default scheme types
        await _initializeSchemeTypes();
        return await getSchemeTypes();
      }

      return snapshot.docs
          .map((doc) => SchemeType.fromJson(doc.data()))
          .toList();
    } catch (e) {
      // Return default scheme types
      return _getDefaultSchemeTypes();
    }
  }

  // ==================== ANALYTICS ====================

  /// Get dashboard stats with real-time updates
  Future<DashboardStats> getDashboardStats() async {
    try {
      final users = await getUsers();
      final transactions = await getTransactions();
      final schemes = await getUserSchemes();

      return DashboardStats(
        totalUsers: users.length,
        activeUsers: users.where((u) => u.status == UserStatus.active).length,
        totalTransactions: transactions.length,
        totalAmount: transactions.fold(0.0, (sum, t) => sum + t.amount),
        totalSchemes: schemes.length,
        activeSchemes: schemes.where((s) => s.status == SchemeStatus.active).length,
      );
    } catch (e) {
      return DashboardStats(
        totalUsers: 0,
        activeUsers: 0,
        totalTransactions: 0,
        totalAmount: 0.0,
        totalSchemes: 0,
        activeSchemes: 0,
      );
    }
  }

  // ==================== SERIAL NUMBER GENERATION ====================

  /// Generate next serial number
  Future<String> generateNextSerialNumber() async {
    try {
      final users = await getUsers();
      if (users.isEmpty) {
        return 'C_001';
      }

      final lastNumber = users
          .map((u) => int.tryParse(u.serialNumber.split('_').last) ?? 0)
          .reduce((a, b) => a > b ? a : b);

      return 'C_${(lastNumber + 1).toString().padLeft(3, '0')}';
    } catch (e) {
      return 'C_001';
    }
  }

  // ==================== LOCAL STORAGE BACKUP ====================

  Future<void> _saveUserLocally(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getUsersLocally();
    users.removeWhere((u) => u.id == user.id);
    users.add(user);
    await prefs.setString('users', jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<void> _saveUsersLocally(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users', jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<List<User>> _getUsersLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users');
    if (usersJson != null) {
      final List<dynamic> usersList = jsonDecode(usersJson);
      return usersList.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> _saveTransactionLocally(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await _getTransactionsLocally();
    transactions.removeWhere((t) => t.id == transaction.id);
    transactions.add(transaction);
    await prefs.setString('transactions', jsonEncode(transactions.map((t) => t.toJson()).toList()));
  }

  Future<void> _saveTransactionsLocally(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transactions', jsonEncode(transactions.map((t) => t.toJson()).toList()));
  }

  Future<List<Transaction>> _getTransactionsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      final List<dynamic> transactionsList = jsonDecode(transactionsJson);
      return transactionsList.map((json) => Transaction.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> _saveUserSchemeLocally(UserScheme scheme) async {
    final prefs = await SharedPreferences.getInstance();
    final schemes = await _getUserSchemesLocally();
    schemes.removeWhere((s) => s.id == scheme.id);
    schemes.add(scheme);
    await prefs.setString('user_schemes', jsonEncode(schemes.map((s) => s.toJson()).toList()));
  }

  Future<void> _saveUserSchemesLocally(List<UserScheme> schemes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_schemes', jsonEncode(schemes.map((s) => s.toJson()).toList()));
  }

  Future<List<UserScheme>> _getUserSchemesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final schemesJson = prefs.getString('user_schemes');
    if (schemesJson != null) {
      final List<dynamic> schemesList = jsonDecode(schemesJson);
      return schemesList.map((json) => UserScheme.fromJson(json)).toList();
    }
    return [];
  }

  // ==================== DEFAULT DATA ====================

  List<SchemeType> _getDefaultSchemeTypes() {
    return [
      SchemeType(
        id: '1',
        name: 'Savings',
        description: 'Regular savings scheme with competitive interest rates',
        interestRate: 8.5,
        amount: 10000,
        duration: 365,
        frequency: Frequency.monthly,
      ),
      SchemeType(
        id: '2',
        name: 'Gold',
        description: 'Gold investment scheme with flexible payment options',
        interestRate: 10.2,
        amount: 50000,
        duration: 365,
        frequency: Frequency.monthly,
      ),
      SchemeType(
        id: '3',
        name: 'Furniture',
        description: 'Furniture purchase scheme with installment options',
        interestRate: 12.0,
        amount: 100000,
        duration: 365,
        frequency: Frequency.monthly,
      ),
    ];
  }

  Future<void> _initializeSchemeTypes() async {
    final schemeTypes = _getDefaultSchemeTypes();
    for (final scheme in schemeTypes) {
      await _firestore
          .collection('scheme_types')
          .doc(scheme.id)
          .set(scheme.toJson());
    }
  }
}
