import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'lib/services/complete_reset_service.dart';

/// Command-line script to reset the app for client delivery
/// Run with: dart reset_app.dart
void main() async {
  print('🚀 Finance Tracker App Reset Tool');
  print('================================');
  print('');
  
  try {
    // Initialize Firebase (not needed for service calls)
    
    print('🧹 Clearing all data from Firebase...');
    
    // Use the complete reset service
    await CompleteResetService.nuclearReset();
    
    print('');
    print('✅ All data cleared successfully!');
    print('');
    
    // Add default scheme types
    print('🔄 Adding default scheme types...');
    await CompleteResetService.resetWithDefaults();
    
    print('');
    print('🎉 App reset complete!');
    print('📱 Your app is now ready for client delivery');
    print('');
    print('📋 Summary:');
    print('   • All user data deleted');
    print('   • All transactions deleted');
    print('   • All user schemes deleted');
    print('   • Default scheme types added');
    print('   • App ready for fresh start');
    
  } catch (e) {
    print('❌ Error during reset: $e');
    exit(1);
  }
}

