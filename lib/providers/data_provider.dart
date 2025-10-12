import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/scheme_type.dart';
import '../models/user_scheme.dart';
import '../services/storage_service.dart';

class DataProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;

  List<User> _users = [];
  List<Transaction> _transactions = [];
  List<SchemeType> _schemeTypes = [];
  List<UserScheme> _userSchemes = [];
  bool _isLoading = false;

  // Getters
  List<User> get users => _users;
  List<Transaction> get transactions => _transactions;
  List<SchemeType> get schemeTypes => _schemeTypes;
  List<UserScheme> get userSchemes => _userSchemes;
  bool get isLoading => _isLoading;

  // Initialize data
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
      // Continue with empty data rather than crashing
      // Error is handled silently to prevent app crashes
    } finally {
      _setLoading(false);
    }
  }

  // Clear all data manually
  Future<void> clearAllData() async {
    _setLoading(true);
    try {
      await _storageService.clearAllData();
      _users = [];
      _transactions = [];
      _userSchemes = [];
      notifyListeners();
    } catch (e) {
      // Handle error silently
    } finally {
      _setLoading(false);
    }
  }

  // Load users
  Future<void> _loadUsers() async {
    try {
      _users = await _storageService.getUsers();
      notifyListeners();
    } catch (e) {
      // Handle error silently and continue with empty list
      _users = [];
    }
  }

  // Load transactions
  Future<void> _loadTransactions() async {
    try {
      _transactions = await _storageService.getTransactions();
      notifyListeners();
    } catch (e) {
      // Handle error silently and continue with empty list
      _transactions = [];
    }
  }

  // Load scheme types
  Future<void> _loadSchemeTypes() async {
    try {
      _schemeTypes = await _storageService.getSchemeTypes();
      notifyListeners();
    } catch (e) {
      // Handle error silently and continue with empty list
      _schemeTypes = [];
    }
  }

  // Load user schemes
  Future<void> _loadUserSchemes() async {
    try {
      _userSchemes = await _storageService.getUserSchemes();
      notifyListeners();
    } catch (e) {
      // Handle error silently and continue with empty list
      _userSchemes = [];
    }
  }

  // Add new transaction
  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _storageService.saveTransaction(transaction);
      _transactions.add(transaction);
      notifyListeners();
    } catch (e) {
      // Re-throw so the UI can handle it
      rethrow;
    }
  }

  // Add new user
  Future<void> addUser(User user) async {
    await _storageService.saveUser(user);
    _users.add(user);
    notifyListeners();
  }

  // Get transactions by user ID
  List<Transaction> getTransactionsByUserId(String userId) {
    return _transactions.where((t) => t.userId == userId).toList();
  }

  // Get recent transactions (last 5)
  List<Transaction> getRecentTransactions({int limit = 5}) {
    final sortedTransactions = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedTransactions.take(limit).toList();
  }

  // Get user by ID
  User? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Get total amount for user
  double getTotalAmountForUser(String userId) {
    return _transactions
        .where((t) => t.userId == userId)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Get dashboard statistics
  Map<String, dynamic> getDashboardStats() {
    final totalTransactions = _transactions.length;
    final totalAmount = _transactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalUsers = _users.length;

    // Calculate total amount from user schemes (weekly amounts × 52 weeks)
    double totalSchemeAmount = 0.0;
    try {
      // Get all user schemes and calculate total amount
      for (final user in _users) {
        // Find user's scheme
        final userSchemes = _userSchemes.where((scheme) => scheme.userId == user.id);
        if (userSchemes.isNotEmpty) {
          final userScheme = userSchemes.first;
          totalSchemeAmount += userScheme.totalAmount;
        }
      }
    } catch (e) {
      // If error, fall back to transaction amount
      totalSchemeAmount = totalAmount;
    }

    // Today's transactions
    final today = DateTime.now();
    final todayTransactions = _transactions
        .where(
          (t) =>
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .toList();

    final todayAmount = todayTransactions.fold(0.0, (sum, t) => sum + t.amount);

    // Calculate pending dues (current week + overdue amounts)
    double pendingDues = 0.0;
    try {
      for (final user in _users) {
        final userSchemes = _userSchemes.where((scheme) => scheme.userId == user.id);
        if (userSchemes.isNotEmpty) {
          final userScheme = userSchemes.first;
          final userPendingDues = _calculateUserPendingDues(user.id, userScheme);
          pendingDues += userPendingDues;
        }
      }
    } catch (e) {
    }

    // Calculate remaining amount (total scheme amount - collected amount)
    double remainingAmount = totalSchemeAmount - totalAmount;

    // Calculate this week's total collectable amount
    double thisWeekCollectable = 0.0;
    try {
      for (final user in _users) {
        final userSchemes = _userSchemes.where((scheme) => scheme.userId == user.id);
        if (userSchemes.isNotEmpty) {
          final userScheme = userSchemes.first;
          final weeklyAmount = userScheme.totalAmount / 52;
          thisWeekCollectable += weeklyAmount;
        }
      }
    } catch (e) {
      thisWeekCollectable = 0.0;
    }

    // Calculate completed cycles (users who have completed all 52 weeks)
    int completedCycles = 0;
    try {
      for (final user in _users) {
        final userSchemes = _userSchemes.where((scheme) => scheme.userId == user.id);
        if (userSchemes.isNotEmpty) {
          final userScheme = userSchemes.first;
          final joiningDate = userScheme.startDate;
          final now = DateTime.now();
          final daysSinceJoining = now.difference(joiningDate).inDays;
          final weeksCompleted = (daysSinceJoining / 7).floor();
          
          // Check if user has completed all 52 weeks
          if (weeksCompleted >= 52) {
            completedCycles++;
          }
        }
      }
    } catch (e) {
      completedCycles = 0;
    }

    // Get available schemes count
    int availableSchemes = _schemeTypes.length;

    return {
      'totalTransactions': totalTransactions,
      'totalAmount': remainingAmount, // Show remaining amount after collections
      'totalUsers': totalUsers,
      'todayTransactions': todayTransactions.length,
      'todayAmount': todayAmount,
      'pendingDues': thisWeekCollectable, // Show this week's collectable amount
      'completedCycles': completedCycles, // Show completed cycles
      'availableSchemes': availableSchemes, // Show available schemes count
    };
  }

  // Calculate pending dues for a specific user
  double _calculateUserPendingDues(String userId, UserScheme userScheme) {
    try {
      final joiningDate = userScheme.startDate;
      final now = DateTime.now();
      final daysSinceJoining = now.difference(joiningDate).inDays;
      final weeklyAmount = userScheme.totalAmount / 52;
      
      // Calculate current week number
      final currentWeek = (daysSinceJoining / 7).floor();
      
      // Get all transactions for this user
      final userTransactions = _transactions.where((t) => t.userId == userId).toList();
      
      // Calculate how many weeks have passed since joining
      final weeksPassed = currentWeek + 1;
      
      // Calculate overdue weeks and current week dues
      double pendingAmount = 0.0;
      
      // Check each week to see if payment is missing
      for (int week = 0; week < weeksPassed; week++) {
        final weekStartDate = joiningDate.add(Duration(days: week * 7));
        final weekEndDate = weekStartDate.add(const Duration(days: 6));
        final daysSinceWeekEnd = now.difference(weekEndDate).inDays;
        
        // Check if payment was made for this week
        final hasPaymentForWeek = userTransactions.any((transaction) {
          final transactionDate = transaction.date;
          return transactionDate.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
                 transactionDate.isBefore(weekEndDate.add(const Duration(days: 1)));
        });
        
        // Only add to pending dues if:
        // 1. No payment was made for this week, AND
        // 2. The week has ended (more than 6 days since week start)
        if (!hasPaymentForWeek && daysSinceWeekEnd >= 0) {
          pendingAmount += weeklyAmount;
        }
      }
      
      return pendingAmount;
    } catch (e) {
      return 0.0;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await initializeData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
