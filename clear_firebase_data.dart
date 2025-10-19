import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple script to clear all Firebase data
/// Run with: dart clear_firebase_data.dart
void main() async {
  print('🧹 Clearing ALL Firebase data...');
  print('⚠️  This will delete EVERYTHING!');
  
  try {
    final firestore = FirebaseFirestore.instance;
    
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
        final collection = firestore.collection(collectionName);
        final snapshot = await collection.get();
        
        if (snapshot.docs.isNotEmpty) {
          // Delete in batches
          final batch = firestore.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          
          print('🗑️ Cleared $collectionName (${snapshot.docs.length} documents)');
          totalDeleted += snapshot.docs.length;
        } else {
          print('✅ $collectionName already empty');
        }
      } catch (e) {
        print('❌ Error clearing $collectionName: $e');
      }
    }
    
    print('');
    print('✅ CLEARING COMPLETE!');
    print('📊 Total documents deleted: $totalDeleted');
    print('📱 Firebase is now completely empty');
    print('🎯 App ready for fresh start');
    
  } catch (e) {
    print('❌ Error during clearing: $e');
  }
}
