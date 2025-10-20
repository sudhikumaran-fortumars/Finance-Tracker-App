import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/transaction.dart' as app_models;
import '../models/scheme_type.dart';
import '../models/user_scheme.dart';
import '../models/dashboard_stats.dart';
import '../services/cloud_storage_service.dart';

class FirebaseDataProvider extends ChangeNotifier {
  final CloudStorageService _storageService = CloudStorageService.instance;

  List<User> _users = [];
  List<app_models.Transaction> _transactions = [];
  List<SchemeType> _schemeTypes = [];
  List<UserScheme> _userSchemes = [];
  bool _isLoading = false;

  // Getters
  List<User> get users => _users;
  List<app_models.Transaction> get transactions => _transactions;
  List<SchemeType> get schemeTypes => _schemeTypes;
  List<UserScheme> get userSchemes => _userSchemes;
  bool get isLoading => _isLoading;

  // Initialize data from Firebase
  Future<void> initializeData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadUsers(),
        _loadTransactions(),
        _loadSchemeTypes(),
        _loadUserSchemes(),
      ]);
    } catch (e) {
      print('Error initializing data from Firebase: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load users from Firebase
  Future<void> _loadUsers() async {
    try {
      _users = await _storageService.getUsers();
      // Users loaded successfully
      notifyListeners();
    } catch (e) {
      print('Error loading users from Firebase: $e');
    }
  }

  // Load transactions from Firebase
  Future<void> _loadTransactions() async {
    try {
      _transactions = await _storageService.getTransactions();
      // Transactions loaded successfully
      notifyListeners();
    } catch (e) {
      print('Error loading transactions from Firebase: $e');
    }
  }

  // Load scheme types from Firebase
  Future<void> _loadSchemeTypes() async {
    try {
      _schemeTypes = await _storageService.getSchemeTypes();
      notifyListeners();
    } catch (e) {
      print('Error loading scheme types from Firebase: $e');
    }
  }

  // Load user schemes from Firebase
  Future<void> _loadUserSchemes() async {
    try {
      _userSchemes = await _storageService.getUserSchemes();
      notifyListeners();
    } catch (e) {
      print('Error loading user schemes from Firebase: $e');
    }
  }

  // Refresh all data from Firebase
  Future<void> refreshData() async {
    await initializeData();
  }

  // ==================== USER OPERATIONS ====================

  /// Add user to Firebase
  Future<void> addUser(User user) async {
    try {
      await _storageService.saveUser(user);
      _users.add(user);
      notifyListeners();
    } catch (e) {
      print('Error adding user to Firebase: $e');
      rethrow;
    }
  }

  /// Update user in Firebase
  Future<void> updateUser(User user) async {
    try {
      await _storageService.updateUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating user in Firebase: $e');
      rethrow;
    }
  }

  /// Delete user from Firebase
  Future<void> deleteUser(String userId) async {
    try {
      await _storageService.deleteUser(userId);
      
      // Remove user from local lists
      _users.removeWhere((user) => user.id == userId);
      _userSchemes.removeWhere((scheme) => scheme.userId == userId);
      _transactions.removeWhere((transaction) => transaction.userId == userId);
      
      notifyListeners();
      // User and associated data deleted from local state
    } catch (e) {
      print('Error deleting user from Firebase: $e');
      rethrow;
    }
  }

  // ==================== TRANSACTION OPERATIONS ====================

  /// Add transaction to Firebase
  Future<void> addTransaction(app_models.Transaction transaction) async {
    try {
      await _storageService.saveTransaction(transaction);
      _transactions.add(transaction);
      notifyListeners();
    } catch (e) {
      print('Error adding transaction to Firebase: $e');
      rethrow;
    }
  }

  /// Update transaction in Firebase
  Future<void> updateTransaction(app_models.Transaction transaction) async {
    try {
      await _storageService.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating transaction in Firebase: $e');
      rethrow;
    }
  }

  /// Delete transaction from Firebase
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _storageService.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
    } catch (e) {
      print('Error deleting transaction from Firebase: $e');
      rethrow;
    }
  }

  // ==================== USER SCHEME OPERATIONS ====================

  /// Add user scheme to Firebase
  Future<void> addUserScheme(UserScheme userScheme) async {
    try {
      await _storageService.saveUserScheme(userScheme);
      _userSchemes.add(userScheme);
      notifyListeners();
    } catch (e) {
      print('Error adding user scheme to Firebase: $e');
      rethrow;
    }
  }

  /// Update user scheme in Firebase
  Future<void> updateUserScheme(UserScheme userScheme) async {
    try {
      await _storageService.updateUserScheme(userScheme);
      final index = _userSchemes.indexWhere((s) => s.id == userScheme.id);
      if (index != -1) {
        _userSchemes[index] = userScheme;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating user scheme in Firebase: $e');
      rethrow;
    }
  }

  /// Delete user scheme from Firebase
  Future<void> deleteUserScheme(String schemeId) async {
    try {
      await _storageService.deleteUserScheme(schemeId);
      _userSchemes.removeWhere((s) => s.id == schemeId);
      notifyListeners();
    } catch (e) {
      print('Error deleting user scheme from Firebase: $e');
      rethrow;
    }
  }

  // ==================== REAL-TIME LISTENERS ====================

  /// Listen to users changes in real-time
  Stream<List<User>> listenToUsers() {
    return _storageService.listenToUsers();
  }

  /// Listen to transactions changes in real-time
  Stream<List<app_models.Transaction>> listenToTransactions() {
    return _storageService.listenToTransactions();
  }

  /// Listen to user schemes changes in real-time
  Stream<List<UserScheme>> listenToUserSchemes() {
    return _storageService.listenToUserSchemes();
  }

  // ==================== DASHBOARD METHODS ====================

  /// Get dashboard stats
  DashboardStats getDashboardStats() {
    try {
      // Calculate stats from current data
      final totalCustomers = _users.length;
      
      // Get list of existing user IDs
      final existingUserIds = _users.map((user) => user.id).toSet();
      
      // Always show 3 available schemes
      final activeSchemes = 3;
      
      // Calculate total scheme amounts (what users should pay in total)
      // Only include schemes for existing users
      final totalSchemeAmounts = _userSchemes
          .where((scheme) => existingUserIds.contains(scheme.userId))
          .fold(0.0, (sum, scheme) => sum + scheme.totalAmount);
      
      // Calculate total amount collected from transactions
      // Only include transactions for existing users
      final totalAmountCollected = _transactions
          .where((transaction) => existingUserIds.contains(transaction.userId))
          .fold(0.0, (sum, t) => sum + t.amount);
      
      // Calculate remaining amount (total scheme amounts - amount collected)
      final remainingAmount = totalSchemeAmounts - totalAmountCollected;
      
      // Weekly collection logic: Show only the current week's outstanding amount
      // This ensures that payments from previous weeks are not included
      // and only the current week's due amount is displayed
      
      final now = DateTime.now();
      double weeklyCollectionAmount = 0.0;

      for (final scheme in _userSchemes.where((s) => existingUserIds.contains(s.userId))) {
        // Skip schemes that haven't started yet
        if (scheme.startDate.isAfter(now)) {
          continue;
        }

        // Weekly amount for this scheme (total amount / 52 weeks)
        final weeklyAmount = scheme.totalAmount / 52;

        // Calculate which week we're currently in for this scheme
        final daysSinceStart = now.difference(scheme.startDate).inDays;
        final currentWeekNumber = (daysSinceStart ~/ 7) + 1; // Week 1, 2, 3, etc.
        
        // Only show amount for current week (don't include future weeks)
        if (currentWeekNumber <= 52) {
          // Find the current week's date range for this scheme
          final currentWeekStart = scheme.startDate.add(Duration(days: (currentWeekNumber - 1) * 7));
          final currentWeekEnd = currentWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          
          // Only include if we're within the current week's date range
          if (now.isAfter(currentWeekStart.subtract(const Duration(seconds: 1))) && 
              now.isBefore(currentWeekEnd.add(const Duration(seconds: 1)))) {
            
            // Amount collected for this scheme in the current week only
            // Include historical transactions that may have been saved without
            // the proper schemeId (fallback to userId match). This avoids
            // over-counting weekly dues after we fixed schemeId wiring.
            final collectedThisWeek = _transactions
                .where((t) => (t.schemeId == scheme.id || t.userId == scheme.userId) &&
                              t.date.isAfter(currentWeekStart.subtract(const Duration(seconds: 1))) &&
                              t.date.isBefore(currentWeekEnd.add(const Duration(seconds: 1))))
                .fold(0.0, (sum, t) => sum + t.amount);

            // Only show outstanding amount for current week (weekly amount - collected this week)
            // If already collected this week, show 0
            final outstandingThisWeek = (weeklyAmount - collectedThisWeek).clamp(0.0, weeklyAmount);
            
            // Only add to total if there's still an outstanding amount
            if (outstandingThisWeek > 0) {
              weeklyCollectionAmount += outstandingThisWeek;
            }
          }
        }
      }
      
      final todayCollection = _transactions
          .where((t) => existingUserIds.contains(t.userId) &&
                       t.date.day == DateTime.now().day)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      return DashboardStats(
        totalCustomers: totalCustomers,
        activeSchemes: activeSchemes,
        totalInvestment: remainingAmount, // Show remaining amount instead of collected amount
        pendingDues: weeklyCollectionAmount, // Show weekly collection amount
        completedCycles: 0, // TODO: Calculate completed cycles
        todayCollection: todayCollection,
        monthlyGrowth: 0.0, // TODO: Calculate monthly growth
      );
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return DashboardStats(
        totalCustomers: 0,
        activeSchemes: 0,
        totalInvestment: 0.0,
        pendingDues: 0.0,
        completedCycles: 0,
        todayCollection: 0.0,
        monthlyGrowth: 0.0,
      );
    }
  }

  /// Get recent transactions
  List<app_models.Transaction> getRecentTransactions() {
    return _transactions.take(5).toList();
  }

  /// Get user by ID
  User? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Generate next serial number
  Future<String> generateNextSerialNumber() async {
    try {
      // Get the highest serial number from existing users
      int maxNumber = 0;
      for (final user in _users) {
        final serialNumber = user.serialNumber;
        if (serialNumber.startsWith('c_')) {
          final number = int.tryParse(serialNumber.substring(2)) ?? 0;
          if (number > maxNumber) {
            maxNumber = number;
          }
        }
      }
      return 'c_${(maxNumber + 1).toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error generating serial number: $e');
      return 'c_01';
    }
  }

  // ==================== USER SCHEME METHODS ====================

  /// Get user schemes
  Future<List<UserScheme>> getUserSchemes() async {
    try {
      return await _storageService.getUserSchemes();
    } catch (e) {
      print('Error getting user schemes: $e');
      return [];
    }
  }

  /// Get transactions
  Future<List<app_models.Transaction>> getTransactions() async {
    try {
      return await _storageService.getTransactions();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get users by name (search)
  List<User> searchUsers(String query) {
    if (query.isEmpty) return _users;
    return _users.where((user) => 
      user.name.toLowerCase().contains(query.toLowerCase()) ||
      user.mobileNumber.contains(query)
    ).toList();
  }

  /// Get transactions by user ID
  List<app_models.Transaction> getTransactionsByUserId(String userId) {
    return _transactions.where((t) => t.userId == userId).toList();
  }

  /// Get user schemes by user ID
  List<UserScheme> getUserSchemesByUserId(String userId) {
    return _userSchemes.where((s) => s.userId == userId).toList();
  }

  /// Get total amount paid by user
  double getTotalPaidByUser(String userId) {
    return _transactions
        .where((t) => t.userId == userId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get remaining amount for user
  double getRemainingAmountForUser(String userId) {
    final userSchemes = getUserSchemesByUserId(userId);
    if (userSchemes.isEmpty) return 0.0;
    
    final totalAmount = userSchemes.first.totalAmount;
    final totalPaid = getTotalPaidByUser(userId);
    return totalAmount - totalPaid;
  }

  /// Get remaining weeks for user
  int getRemainingWeeksForUser(String userId) {
    final userSchemes = getUserSchemesByUserId(userId);
    if (userSchemes.isEmpty) return 52;
    
    final totalAmount = userSchemes.first.totalAmount;
    final totalPaid = getTotalPaidByUser(userId);
    final weeklyAmount = totalAmount / 52;
    final paidWeeks = (totalPaid / weeklyAmount).floor();
    final remainingWeeks = 52 - paidWeeks;
    
    return remainingWeeks > 0 ? remainingWeeks : 0;
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      await _storageService.clearAllData();
      _users.clear();
      _transactions.clear();
      _schemeTypes.clear();
      _userSchemes.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }

  /// Initialize with sample data
  Future<void> initializeWithSampleData() async {
    try {
      await _storageService.initializeWithSampleData();
      await refreshData();
    } catch (e) {
      print('Error initializing with sample data: $e');
      rethrow;
    }
  }

  // ==================== PRIVATE METHODS ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

