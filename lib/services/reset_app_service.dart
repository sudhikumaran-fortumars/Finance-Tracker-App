import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to reset the app to a fresh state for client delivery
class ResetAppService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clear all data from Firebase collections
  static Future<void> clearAllData() async {
    try {
      print('🧹 Starting app reset...');
      
      // Clear all collections
      await _clearCollection('users');
      await _clearCollection('userSchemes');
      await _clearCollection('transactions');
      await _clearCollection('schemeTypes');
      
      print('✅ All Firebase data cleared successfully!');
      print('📱 App is now ready for client delivery');
    } catch (e) {
      print('❌ Error clearing data: $e');
      rethrow;
    }
  }

  /// Clear a specific collection
  static Future<void> _clearCollection(String collectionName) async {
    try {
      final collection = _firestore.collection(collectionName);
      final snapshot = await collection.get();
      
      if (snapshot.docs.isNotEmpty) {
        // Delete documents in batches
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('🗑️ Cleared $collectionName collection (${snapshot.docs.length} documents)');
      } else {
        print('✅ $collectionName collection already empty');
      }
    } catch (e) {
      print('❌ Error clearing $collectionName: $e');
      rethrow;
    }
  }

  /// Reset app with default scheme types
  static Future<void> resetWithDefaultSchemes() async {
    try {
      print('🔄 Setting up default scheme types...');
      
      // Add default scheme types
      final defaultSchemes = [
        {
          'id': 'scheme_1',
          'name': 'Weekly Savings',
          'amount': 1000.0,
          'frequency': 'weekly',
          'description': 'Weekly savings scheme',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'scheme_2', 
          'name': 'Monthly Investment',
          'amount': 5000.0,
          'frequency': 'monthly',
          'description': 'Monthly investment scheme',
          'createdAt': Timestamp.now(),
        },
        {
          'id': 'scheme_3',
          'name': 'Yearly Plan',
          'amount': 50000.0,
          'frequency': 'yearly', 
          'description': 'Yearly investment plan',
          'createdAt': Timestamp.now(),
        },
      ];

      final batch = _firestore.batch();
      for (var scheme in defaultSchemes) {
        final docRef = _firestore.collection('schemeTypes').doc(scheme['id'] as String);
        batch.set(docRef, scheme);
      }
      await batch.commit();
      
      print('✅ Default scheme types added');
    } catch (e) {
      print('❌ Error setting up default schemes: $e');
      rethrow;
    }
  }

  /// Complete app reset for client delivery
  static Future<void> resetForClient() async {
    try {
      print('🚀 Preparing app for client delivery...');
      
      // Clear all existing data
      await clearAllData();
      
      // Add default scheme types
      await resetWithDefaultSchemes();
      
      print('🎉 App reset complete! Ready for client delivery.');
      print('📋 Summary:');
      print('   • All user data cleared');
      print('   • All transactions cleared'); 
      print('   • All user schemes cleared');
      print('   • Default scheme types added');
      print('   • App ready for fresh start');
      
    } catch (e) {
      print('❌ Error during app reset: $e');
      rethrow;
    }
  }
}
