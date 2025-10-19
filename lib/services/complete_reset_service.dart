import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to completely reset the app and clear ALL data
class CompleteResetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clear ALL data from Firebase - complete reset
  static Future<void> clearAllData() async {
    try {
      print('🧹 Starting COMPLETE app reset...');
      print('⚠️  This will delete EVERYTHING!');
      
      // Clear all collections in order
      await _clearCollection('transactions');
      await _clearCollection('userSchemes');
      await _clearCollection('users');
      await _clearCollection('schemeTypes');
      
      // Clear any other collections that might exist
      await _clearCollection('reports');
      await _clearCollection('notifications');
      await _clearCollection('analytics');
      await _clearCollection('logs');
      await _clearCollection('backups');
      
      print('✅ ALL data cleared successfully!');
      print('📱 App is now completely empty and ready for fresh start');
    } catch (e) {
      print('❌ Error clearing data: $e');
      rethrow;
    }
  }

  /// Clear a specific collection completely
  static Future<void> _clearCollection(String collectionName) async {
    try {
      final collection = _firestore.collection(collectionName);
      final snapshot = await collection.get();
      
      if (snapshot.docs.isNotEmpty) {
        // Delete documents in batches of 500 (Firestore limit)
        final batch = _firestore.batch();
        int batchCount = 0;
        
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
          batchCount++;
          
          // Commit batch when it reaches 500 documents
          if (batchCount >= 500) {
            await batch.commit();
            batchCount = 0;
            // Continue with current batch
          }
        }
        
        // Commit remaining documents
        if (batchCount > 0) {
          await batch.commit();
        }
        
        print('🗑️ Cleared $collectionName collection (${snapshot.docs.length} documents)');
      } else {
        print('✅ $collectionName collection already empty');
      }
    } catch (e) {
      print('❌ Error clearing $collectionName: $e');
      rethrow;
    }
  }

  /// Complete app reset - nuclear option
  static Future<void> nuclearReset() async {
    try {
      print('💥 NUCLEAR RESET INITIATED');
      print('⚠️  This will delete EVERYTHING from Firebase!');
      
      // Get all collections
      final collections = await _getAllCollections();
      
      print('📋 Found ${collections.length} collections to clear:');
      for (var collection in collections) {
        print('   • $collection');
      }
      
      // Clear each collection
      for (var collectionName in collections) {
        await _clearCollection(collectionName);
      }
      
      print('');
      print('💥 NUCLEAR RESET COMPLETE!');
      print('📱 App is now completely empty');
      print('🎯 Ready for fresh start with zero data');
      
    } catch (e) {
      print('❌ Error during nuclear reset: $e');
      rethrow;
    }
  }

  /// Get all collection names from Firestore
  static Future<List<String>> _getAllCollections() async {
    try {
      // This is a simplified approach - in practice, you'd need to know your collections
      // or use Firestore admin SDK to list them
      return [
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
    } catch (e) {
      print('❌ Error getting collections: $e');
      return [];
    }
  }

  /// Reset with default data only
  static Future<void> resetWithDefaults() async {
    try {
      print('🔄 Setting up fresh app with defaults...');
      
      // Clear everything first
      await nuclearReset();
      
      // Add default scheme types
      await _addDefaultSchemes();
      
      print('✅ Fresh app setup complete!');
      print('📱 App ready with default schemes only');
      
    } catch (e) {
      print('❌ Error setting up fresh app: $e');
      rethrow;
    }
  }

  /// Add default scheme types
  static Future<void> _addDefaultSchemes() async {
    try {
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
      
      print('✅ Added ${defaultSchemes.length} default scheme types');
    } catch (e) {
      print('❌ Error adding default schemes: $e');
      rethrow;
    }
  }
}
