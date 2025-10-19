import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to automatically clear all data on app startup
class AutoResetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clear all data automatically
  static Future<void> clearAllDataOnStartup() async {
    try {
      print('🧹 AUTO-RESET: Clearing all Firebase data...');
      
      // List of all collections to clear
      final collections = [
        'users',
        'userSchemes', 
        'transactions',
        'schemeTypes',
        'reports',
        'notifications',
        'analytics',
        'logs',
        'backups',
        'settings',
        'auditLogs',
        'userSessions',
        'paymentHistory',
        'bonusRecords',
        'reminderLogs'
      ];
      
      int totalDeleted = 0;
      
      for (String collectionName in collections) {
        try {
          final collection = _firestore.collection(collectionName);
          final snapshot = await collection.get();
          
          if (snapshot.docs.isNotEmpty) {
            // Delete in batches
            final batch = _firestore.batch();
            for (var doc in snapshot.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
            
            print('🗑️ Cleared $collectionName (${snapshot.docs.length} documents)');
            totalDeleted += snapshot.docs.length;
          }
        } catch (e) {
          print('❌ Error clearing $collectionName: $e');
        }
      }
      
      print('✅ AUTO-RESET COMPLETE!');
      print('📊 Total documents deleted: $totalDeleted');
      print('📱 All data cleared - app ready for fresh start');
      
    } catch (e) {
      print('❌ Error during auto-reset: $e');
    }
  }
}
