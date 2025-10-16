import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scheme_type.dart';
import '../models/user.dart';
import '../models/user_scheme.dart';
import '../models/transaction.dart';
import '../models/dashboard_stats.dart';
import '../models/notification_config.dart';
import '../models/notification.dart';
import '../models/report_filter.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static StorageService get instance => _instance;

  // Mock data for demonstration - Only 3 schemes: Savings, Gold, Furniture
  final List<SchemeType> _mockSchemeTypes = [
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

  final List<User> _mockUsers = [];

  final List<Transaction> _mockTransactions = [];

  // Users
  Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('fst_users');
    if (stored != null) {
      final List<dynamic> jsonList = jsonDecode(stored);
      return jsonList.map((json) => User.fromJson(json)).toList();
    }
    return _mockUsers; // Returns empty list
  }

  Future<String> generateNextSerialNumber() async {
    final users = await getUsers();
    int maxNumber = 0;

    for (final user in users) {
      if (user.serialNumber.startsWith('c_')) {
        try {
          final number = int.parse(user.serialNumber.substring(2));
          if (number > maxNumber) {
            maxNumber = number;
          }
        } catch (e) {
          // Skip invalid serial numbers
        }
      }
    }

    return 'c_${(maxNumber + 1).toString().padLeft(2, '0')}';
  }

  Future<void> saveUser(User user) async {
    final users = await getUsers();
    final existingIndex = users.indexWhere((u) => u.id == user.id);

    if (existingIndex >= 0) {
      users[existingIndex] = user;
    } else {
      users.add(user);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fst_users',
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<User?> getUserById(String id) async {
    final users = await getUsers();
    try {
      return users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Transactions
  Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('fst_transactions');
    if (stored != null) {
      final List<dynamic> jsonList = jsonDecode(stored);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    }
    return _mockTransactions;
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    
    // Check if transaction already exists to prevent duplicates
    final existingTransaction = transactions.any((t) => t.id == transaction.id);
    if (existingTransaction) {
      return; // Transaction already exists, don't save duplicate
    }
    
    transactions.add(transaction);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fst_transactions',
      jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );
  }

  Future<List<Transaction>> getTransactionsByUserId(String userId) async {
    final transactions = await getTransactions();
    return transactions.where((t) => t.userId == userId).toList();
  }

  Future<List<Transaction>> getTransactionsBySchemeId(String schemeId) async {
    final transactions = await getTransactions();
    return transactions.where((t) => t.schemeId == schemeId).toList();
  }

  // Schemes
  Future<List<SchemeType>> getSchemeTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('fst_scheme_types');
    if (stored != null) {
      final List<dynamic> jsonList = jsonDecode(stored);
      return jsonList.map((json) => SchemeType.fromJson(json)).toList();
    }
    return _mockSchemeTypes;
  }

  Future<void> saveSchemeType(SchemeType schemeType) async {
    final schemes = await getSchemeTypes();
    final existingIndex = schemes.indexWhere((s) => s.id == schemeType.id);

    if (existingIndex >= 0) {
      schemes[existingIndex] = schemeType;
    } else {
      schemes.add(schemeType);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fst_scheme_types',
      jsonEncode(schemes.map((s) => s.toJson()).toList()),
    );
  }

  Future<List<UserScheme>> getUserSchemes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('fst_user_schemes');
    if (stored != null) {
      final List<dynamic> jsonList = jsonDecode(stored);
      return jsonList.map((json) => UserScheme.fromJson(json)).toList();
    }

    // Return empty list - no mock user schemes
    return [];
  }

  Future<void> saveUserScheme(UserScheme scheme) async {
    final schemes = await getUserSchemes();
    final existingIndex = schemes.indexWhere((s) => s.id == scheme.id);

    if (existingIndex >= 0) {
      schemes[existingIndex] = scheme;
    } else {
      schemes.add(scheme);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fst_user_schemes',
      jsonEncode(schemes.map((s) => s.toJson()).toList()),
    );
  }


  Future<List<UserScheme>> getUserSchemesByUserId(String userId) async {
    final schemes = await getUserSchemes();
    return schemes.where((s) => s.userId == userId).toList();
  }

  Future<UserScheme?> addSchemeToUser({
    required String userId,
    required String schemeTypeId,
    DateTime? startDate,
    int? duration,
    double? dailyAmount,
    double? totalAmount,
    double? interestRate,
  }) async {
    final types = await getSchemeTypes();
    final schemeType = types.where((t) => t.id == schemeTypeId).firstOrNull;
    if (schemeType == null) return null;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final finalDuration = duration ?? schemeType.duration;
    final finalInterestRate = interestRate ?? schemeType.interestRate;
    final finalStartDate = startDate ?? DateTime.now();
    final finalTotalAmount =
        totalAmount ??
        (dailyAmount != null
            ? dailyAmount * finalDuration
            : schemeType.amount * finalDuration);

    final newScheme = UserScheme(
      id: id,
      userId: userId,
      schemeType: schemeType,
      startDate: finalStartDate,
      duration: finalDuration,
      dailyAmount: dailyAmount,
      totalAmount: finalTotalAmount,
      interestRate: finalInterestRate,
      currentBalance: 0,
      status: SchemeStatus.active,
    );

    await saveUserScheme(newScheme);
    return newScheme;
  }

  // Dashboard Stats
  Future<DashboardStats> getDashboardStats() async {
    final users = await getUsers();
    final transactions = await getTransactions();
    final schemes = await getUserSchemes();

    final today = DateTime.now();
    final todayTransactions = transactions.where((t) {
      final transactionDate = t.date;
      return transactionDate.year == today.year &&
          transactionDate.month == today.month &&
          transactionDate.day == today.day;
    }).toList();

    final totalInvestment = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final todayCollection = todayTransactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    return DashboardStats(
      totalCustomers: users.where((u) => u.status == UserStatus.active).length,
      activeSchemes: schemes
          .where((s) => s.status == SchemeStatus.active)
          .length,
      totalInvestment: totalInvestment,
      pendingDues: 0, // This would need more complex calculation
      completedCycles: schemes
          .where((s) => s.status == SchemeStatus.completed)
          .length,
      todayCollection: todayCollection,
      monthlyGrowth: 12.5, // Mock data
    );
  }

  // Search and Filter
  Future<List<User>> searchUsers(String query) async {
    final users = await getUsers();
    final lowerQuery = query.toLowerCase();

    return users
        .where(
          (user) =>
              user.name.toLowerCase().contains(lowerQuery) ||
              user.mobileNumber.contains(query) ||
              user.serialNumber.toLowerCase().contains(lowerQuery) ||
              (user.selectedScheme?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              user.permanentAddress.city.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  Future<List<Transaction>> filterTransactionsByPeriod(
    ReportPeriod period,
  ) async {
    final transactions = await getTransactions();
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case ReportPeriod.weekly:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriod.yearly:
        startDate = DateTime(now.year, 1, 1);
        break;
      case ReportPeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }

    return transactions
        .where(
          (t) =>
              t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate),
        )
        .toList();
  }

  // Notifications
  Future<List<Notification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('fst_notifications');
    if (stored != null) {
      final List<dynamic> jsonList = jsonDecode(stored);
      return jsonList.map((json) => Notification.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> saveNotification(Notification notification) async {
    final notifications = await getNotifications();
    notifications.add(notification);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fst_notifications',
      jsonEncode(notifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> markNotificationAsRead(String id) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      notifications[index] = notifications[index].copyWith(read: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'fst_notifications',
        jsonEncode(notifications.map((n) => n.toJson()).toList()),
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fst_notifications',
      jsonEncode(notifications.map((n) => n.toJson()).toList()),
    );
  }

  // Notification Config
  Future<NotificationConfig> getNotificationConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('fst_notification_config');
    if (stored != null) {
      return NotificationConfig.fromJson(jsonDecode(stored));
    }
    return NotificationConfig(
      emailEnabled: true,
      whatsappEnabled: true,
      reminderDays: [1, 3, 7],
      escalationDays: [7, 14],
      reportSchedule: '19:00',
    );
  }

  Future<void> saveNotificationConfig(NotificationConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fst_notification_config',
      jsonEncode(config.toJson()),
    );
  }

  // Clear all data - for fresh start
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fst_users');
    await prefs.remove('fst_transactions');
    await prefs.remove('fst_user_schemes');
    await prefs.remove('fst_notifications');
  }

}
