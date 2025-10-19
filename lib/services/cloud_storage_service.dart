import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/scheme_type.dart';
import '../models/user.dart';
import '../models/user_scheme.dart';
import '../models/transaction.dart' as app_models;
import '../models/dashboard_stats.dart';
import '../models/address.dart';

class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  static CloudStorageService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // ==================== USER OPERATIONS ====================

  /// Save user to Firestore
  Future<void> saveUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'name': user.name,
        'mobileNumber': user.mobileNumber,
        'permanentAddress': user.permanentAddress.toJson(),
        'temporaryAddress': user.temporaryAddress?.toJson(),
        'serialNumber': user.serialNumber,
        'selectedScheme': user.selectedScheme,
        'status': user.status.toString().split('.').last,
        'createdAt': user.createdAt.toIso8601String(),
        'schemes': user.schemes.map((scheme) => scheme.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user to Firestore: $e');
      rethrow;
    }
  }

  /// Get all users from Firestore
  Future<List<User>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? '',
          mobileNumber: data['mobileNumber'] ?? '',
          permanentAddress: Address.fromJson(data['permanentAddress'] ?? {}),
          temporaryAddress: data['temporaryAddress'] != null 
              ? Address.fromJson(data['temporaryAddress']) 
              : null,
          serialNumber: data['serialNumber'] ?? '',
          selectedScheme: data['selectedScheme'],
          status: UserStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
            orElse: () => UserStatus.active,
          ),
          createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
          schemes: (data['schemes'] as List<dynamic>?)
              ?.map((scheme) => UserScheme.fromJson(scheme))
              .toList() ?? [],
        );
      }).toList();
    } catch (e) {
      print('Error getting users from Firestore: $e');
      return [];
    }
  }

  /// Update user in Firestore
  Future<void> updateUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'name': user.name,
        'mobileNumber': user.mobileNumber,
        'permanentAddress': user.permanentAddress.toJson(),
        'temporaryAddress': user.temporaryAddress?.toJson(),
        'serialNumber': user.serialNumber,
        'selectedScheme': user.selectedScheme,
        'status': user.status.toString().split('.').last,
        'schemes': user.schemes.map((scheme) => scheme.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user in Firestore: $e');
      rethrow;
    }
  }

  /// Delete user from Firestore
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user schemes first
      final userSchemesQuery = await _firestore
          .collection('userSchemes')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in userSchemesQuery.docs) {
        await doc.reference.delete();
      }
      
      // Delete user transactions
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in transactionsQuery.docs) {
        await doc.reference.delete();
      }
      
      // Finally delete the user
      await _firestore.collection('users').doc(userId).delete();
      
      // User and associated data deleted successfully
    } catch (e) {
      print('Error deleting user and associated data from Firestore: $e');
      rethrow;
    }
  }

  // ==================== USER SCHEME OPERATIONS ====================

  /// Save user scheme to Firestore
  Future<void> saveUserScheme(UserScheme userScheme) async {
    try {
      await _firestore.collection('userSchemes').doc(userScheme.id).set({
        'id': userScheme.id,
        'userId': userScheme.userId,
        'schemeType': userScheme.schemeType.toJson(),
        'totalAmount': userScheme.totalAmount,
        'currentBalance': userScheme.currentBalance,
        'startDate': userScheme.startDate.toIso8601String(),
        'duration': userScheme.duration,
        'status': userScheme.status.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user scheme to Firestore: $e');
      rethrow;
    }
  }

  /// Get all user schemes from Firestore
  Future<List<UserScheme>> getUserSchemes() async {
    try {
      final snapshot = await _firestore.collection('userSchemes').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserScheme(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          schemeType: SchemeType.fromJson(data['schemeType'] ?? {}),
          totalAmount: (data['totalAmount'] ?? 0).toDouble(),
          currentBalance: (data['currentBalance'] ?? 0).toDouble(),
          startDate: DateTime.parse(data['startDate'] ?? DateTime.now().toIso8601String()),
          duration: data['duration'] ?? 365,
          interestRate: (data['interestRate'] ?? 0).toDouble(),
          status: SchemeStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
            orElse: () => SchemeStatus.active,
          ),
        );
      }).toList();
    } catch (e) {
      print('Error getting user schemes from Firestore: $e');
      return [];
    }
  }

  /// Get user schemes by user ID
  Future<List<UserScheme>> getUserSchemesByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('userSchemes')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserScheme(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          schemeType: SchemeType.fromJson(data['schemeType'] ?? {}),
          totalAmount: (data['totalAmount'] ?? 0).toDouble(),
          currentBalance: (data['currentBalance'] ?? 0).toDouble(),
          startDate: DateTime.parse(data['startDate'] ?? DateTime.now().toIso8601String()),
          duration: data['duration'] ?? 365,
          interestRate: (data['interestRate'] ?? 0).toDouble(),
          status: SchemeStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
            orElse: () => SchemeStatus.active,
          ),
        );
      }).toList();
    } catch (e) {
      print('Error getting user schemes by user ID from Firestore: $e');
      return [];
    }
  }

  /// Update user scheme in Firestore
  Future<void> updateUserScheme(UserScheme userScheme) async {
    try {
      await _firestore.collection('userSchemes').doc(userScheme.id).update({
        'schemeType': userScheme.schemeType.toJson(),
        'totalAmount': userScheme.totalAmount,
        'currentBalance': userScheme.currentBalance,
        'startDate': userScheme.startDate.toIso8601String(),
        'duration': userScheme.duration,
        'status': userScheme.status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user scheme in Firestore: $e');
      rethrow;
    }
  }

  /// Delete user scheme from Firestore
  Future<void> deleteUserScheme(String schemeId) async {
    try {
      await _firestore.collection('userSchemes').doc(schemeId).delete();
    } catch (e) {
      print('Error deleting user scheme from Firestore: $e');
      rethrow;
    }
  }

  // ==================== TRANSACTION OPERATIONS ====================

  /// Save transaction to Firestore
  Future<void> saveTransaction(app_models.Transaction transaction) async {
    try {
      await _firestore.collection('transactions').doc(transaction.id).set({
        'id': transaction.id,
        'userId': transaction.userId,
        'schemeId': transaction.schemeId,
        'amount': transaction.amount,
        'paymentMode': transaction.paymentMode.toString(),
        'date': transaction.date.toIso8601String(),
        'interest': transaction.interest,
        'remarks': transaction.remarks,
        'receiptNumber': transaction.receiptNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving transaction to Firestore: $e');
      rethrow;
    }
  }

  /// Get all transactions from Firestore
  Future<List<app_models.Transaction>> getTransactions() async {
    try {
      final snapshot = await _firestore.collection('transactions').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_models.Transaction(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          schemeId: data['schemeId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          paymentMode: app_models.PaymentMode.values.firstWhere(
            (e) => e.toString() == data['paymentMode'],
            orElse: () => app_models.PaymentMode.offline,
          ),
          date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
          interest: (data['interest'] ?? 0).toDouble(),
          remarks: data['remarks'] ?? '',
          receiptNumber: data['receiptNumber'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error getting transactions from Firestore: $e');
      return [];
    }
  }

  /// Get transactions by user ID
  Future<List<app_models.Transaction>> getTransactionsByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_models.Transaction(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          schemeId: data['schemeId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          paymentMode: app_models.PaymentMode.values.firstWhere(
            (e) => e.toString() == data['paymentMode'],
            orElse: () => app_models.PaymentMode.offline,
          ),
          date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
          interest: (data['interest'] ?? 0).toDouble(),
          remarks: data['remarks'] ?? '',
          receiptNumber: data['receiptNumber'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error getting transactions by user ID from Firestore: $e');
      return [];
    }
  }

  /// Update transaction in Firestore
  Future<void> updateTransaction(app_models.Transaction transaction) async {
    try {
      await _firestore.collection('transactions').doc(transaction.id).update({
        'amount': transaction.amount,
        'paymentMode': transaction.paymentMode.toString(),
        'date': transaction.date.toIso8601String(),
        'interest': transaction.interest,
        'remarks': transaction.remarks,
        'receiptNumber': transaction.receiptNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating transaction in Firestore: $e');
      rethrow;
    }
  }

  /// Delete transaction from Firestore
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
    } catch (e) {
      print('Error deleting transaction from Firestore: $e');
      rethrow;
    }
  }

  // ==================== SCHEME TYPE OPERATIONS ====================

  /// Get all scheme types from Firestore
  Future<List<SchemeType>> getSchemeTypes() async {
    try {
      final snapshot = await _firestore.collection('schemes').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SchemeType(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          interestRate: (data['interestRate'] ?? 0).toDouble(),
          amount: (data['amount'] ?? 0).toDouble(),
          duration: data['duration'] ?? 365,
          frequency: Frequency.values.firstWhere(
            (e) => e.toString() == data['frequency'],
            orElse: () => Frequency.monthly,
          ),
        );
      }).toList();
    } catch (e) {
      print('Error getting scheme types from Firestore: $e');
      return [];
    }
  }

  /// Save scheme type to Firestore
  Future<void> saveSchemeType(SchemeType schemeType) async {
    try {
      await _firestore.collection('schemes').doc(schemeType.id).set({
        'id': schemeType.id,
        'name': schemeType.name,
        'description': schemeType.description,
        'interestRate': schemeType.interestRate,
        'amount': schemeType.amount,
        'duration': schemeType.duration,
        'frequency': schemeType.frequency.toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving scheme type to Firestore: $e');
      rethrow;
    }
  }

  // ==================== DASHBOARD STATS ====================

  /// Get dashboard stats from Firestore
  Future<DashboardStats> getDashboardStats() async {
    try {
      final users = await getUsers();
      final transactions = await getTransactions();
      final userSchemes = await getUserSchemes();

      final totalUsers = users.length;
      // final activeUsers = users.where((user) => user.status == UserStatus.active).length;
      // final totalTransactions = transactions.length;
      final totalAmount = transactions.fold(0.0, (total, t) => total + t.amount);
      final activeSchemes = userSchemes.where((scheme) => scheme.status == SchemeStatus.active).length;

      return DashboardStats(
        totalCustomers: totalUsers,
        activeSchemes: activeSchemes,
        totalInvestment: totalAmount,
        pendingDues: 0.0,
        completedCycles: 0,
        todayCollection: 0.0,
        monthlyGrowth: 0.0,
      );
    } catch (e) {
      print('Error getting dashboard stats from Firestore: $e');
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

  // ==================== REAL-TIME LISTENERS ====================

  /// Listen to users changes in real-time
  Stream<List<User>> listenToUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? '',
          mobileNumber: data['mobileNumber'] ?? '',
          permanentAddress: Address.fromJson(data['permanentAddress'] ?? {}),
          temporaryAddress: data['temporaryAddress'] != null 
              ? Address.fromJson(data['temporaryAddress']) 
              : null,
          serialNumber: data['serialNumber'] ?? '',
          selectedScheme: data['selectedScheme'],
          status: UserStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
            orElse: () => UserStatus.active,
          ),
          createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
          schemes: (data['schemes'] as List<dynamic>?)
              ?.map((scheme) => UserScheme.fromJson(scheme))
              .toList() ?? [],
        );
      }).toList();
    });
  }

  /// Listen to transactions changes in real-time
  Stream<List<app_models.Transaction>> listenToTransactions() {
    return _firestore.collection('transactions').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_models.Transaction(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          schemeId: data['schemeId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          paymentMode: app_models.PaymentMode.values.firstWhere(
            (e) => e.toString() == data['paymentMode'],
            orElse: () => app_models.PaymentMode.offline,
          ),
          date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
          interest: (data['interest'] ?? 0).toDouble(),
          remarks: data['remarks'] ?? '',
          receiptNumber: data['receiptNumber'] ?? '',
        );
      }).toList();
    });
  }

  /// Listen to user schemes changes in real-time
  Stream<List<UserScheme>> listenToUserSchemes() {
    return _firestore.collection('userSchemes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserScheme(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          schemeType: SchemeType.fromJson(data['schemeType'] ?? {}),
          totalAmount: (data['totalAmount'] ?? 0).toDouble(),
          currentBalance: (data['currentBalance'] ?? 0).toDouble(),
          startDate: DateTime.parse(data['startDate'] ?? DateTime.now().toIso8601String()),
          duration: data['duration'] ?? 365,
          interestRate: (data['interestRate'] ?? 0).toDouble(),
          status: SchemeStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
            orElse: () => SchemeStatus.active,
          ),
        );
      }).toList();
    });
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      // Delete all collections
      final collections = ['users', 'transactions', 'userSchemes', 'schemes'];
      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Error clearing all data from Firestore: $e');
      rethrow;
    }
  }

  /// Initialize with sample data
  Future<void> initializeWithSampleData() async {
    try {
      // Add sample scheme types
      final sampleSchemes = [
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

      for (final scheme in sampleSchemes) {
        await saveSchemeType(scheme);
      }
    } catch (e) {
      print('Error initializing with sample data: $e');
      rethrow;
    }
  }
}
