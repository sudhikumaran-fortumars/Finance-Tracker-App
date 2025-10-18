import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/user_scheme.dart';
import '../utils/calculations.dart';

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  static WhatsAppService get instance => _instance;

  // ==================== PAYMENT CONFIRMATION MESSAGES ====================

  /// Send payment confirmation message
  Future<bool> sendPaymentConfirmation({
    required User user,
    required Transaction transaction,
    required UserScheme? userScheme,
    required double pendingAmount,
    required double totalBonus,
    required DateTime? nextDueDate,
  }) async {
    try {
      final message = _buildPaymentConfirmationMessage(
        user: user,
        transaction: transaction,
        userScheme: userScheme,
        pendingAmount: pendingAmount,
        totalBonus: totalBonus,
        nextDueDate: nextDueDate,
      );

      return await sendWhatsAppMessage(
        phoneNumber: user.mobileNumber,
        message: message,
      );
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      return false;
    }
  }

  /// Build payment confirmation message
  String _buildPaymentConfirmationMessage({
    required User user,
    required Transaction transaction,
    required UserScheme? userScheme,
    required double pendingAmount,
    required double totalBonus,
    required DateTime? nextDueDate,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('🎉 *Payment Received Successfully!*');
    buffer.writeln('');
    
    // Customer details
    buffer.writeln('👤 *Customer Details:*');
    buffer.writeln('Name: ${user.name}');
    buffer.writeln('ID: ${user.serialNumber}');
    buffer.writeln('');
    
    // Payment details
    buffer.writeln('💰 *Payment Details:*');
    buffer.writeln('Amount: ₹${transaction.amount.toStringAsFixed(0)}');
    buffer.writeln('Date: ${Calculations.formatDate(transaction.date)}');
    buffer.writeln('Mode: ${_getPaymentModeDisplayName(transaction.paymentMode)}');
    buffer.writeln('Receipt: ${transaction.receiptNumber ?? 'N/A'}');
    buffer.writeln('');
    
    // Scheme information
    if (userScheme != null) {
      buffer.writeln('📋 *Scheme Information:*');
      buffer.writeln('Scheme: ${userScheme.schemeType.name}');
      buffer.writeln('Weekly Amount: ₹${(userScheme.totalAmount / 52).toStringAsFixed(0)}');
      buffer.writeln('Total Amount: ₹${userScheme.totalAmount.toStringAsFixed(0)}');
      buffer.writeln('');
    }
    
    // Financial summary
    buffer.writeln('📊 *Financial Summary:*');
    buffer.writeln('Pending Amount: ₹${pendingAmount.toStringAsFixed(0)}');
    if (totalBonus > 0) {
      buffer.writeln('Total Bonus Earned: ₹${totalBonus.toStringAsFixed(0)}');
    }
    buffer.writeln('');
    
    // Next due date
    if (nextDueDate != null) {
      buffer.writeln('📅 *Next Due Date:*');
      buffer.writeln('${Calculations.formatDate(nextDueDate)}');
      buffer.writeln('');
    }
    
    // Footer
    buffer.writeln('Thank you for your payment! 🙏');
    buffer.writeln('');
    buffer.writeln('_This is an automated message from Finance Tracker App_');
    
    return buffer.toString();
  }

  // ==================== REMINDER MESSAGES ====================

  /// Send payment reminder message
  Future<bool> sendPaymentReminder({
    required User user,
    required double weeklyAmount,
    required double overdueAmount,
    required int overdueWeeks,
    required DateTime nextDueDate,
  }) async {
    try {
      final message = _buildPaymentReminderMessage(
        user: user,
        weeklyAmount: weeklyAmount,
        overdueAmount: overdueAmount,
        overdueWeeks: overdueWeeks,
        nextDueDate: nextDueDate,
      );

      return await sendWhatsAppMessage(
        phoneNumber: user.mobileNumber,
        message: message,
      );
    } catch (e) {
      print('Error sending WhatsApp reminder: $e');
      return false;
    }
  }

  /// Build payment reminder message
  String _buildPaymentReminderMessage({
    required User user,
    required double weeklyAmount,
    required double overdueAmount,
    required int overdueWeeks,
    required DateTime nextDueDate,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('⏰ *Payment Reminder*');
    buffer.writeln('');
    
    // Customer details
    buffer.writeln('👤 *Customer Details:*');
    buffer.writeln('Name: ${user.name}');
    buffer.writeln('ID: ${user.serialNumber}');
    buffer.writeln('');
    
    // Payment details
    buffer.writeln('💰 *Payment Details:*');
    buffer.writeln('Weekly Amount: ₹${weeklyAmount.toStringAsFixed(0)}');
    
    if (overdueAmount > 0) {
      buffer.writeln('⚠️ Overdue Amount: ₹${overdueAmount.toStringAsFixed(0)}');
      buffer.writeln('📅 Overdue Weeks: $overdueWeeks weeks');
      buffer.writeln('');
      buffer.writeln('Total Due: ₹${(weeklyAmount + overdueAmount).toStringAsFixed(0)}');
    }
    
    buffer.writeln('Next Due Date: ${Calculations.formatDate(nextDueDate)}');
    buffer.writeln('');
    
    // Footer
    buffer.writeln('Please make your payment at the earliest convenience.');
    buffer.writeln('');
    buffer.writeln('Thank you! 🙏');
    buffer.writeln('');
    buffer.writeln('_This is an automated reminder from Finance Tracker App_');
    
    return buffer.toString();
  }

  // ==================== SCHEME COMPLETION MESSAGES ====================

  /// Send scheme completion message
  Future<bool> sendSchemeCompletionMessage({
    required User user,
    required UserScheme scheme,
    required double totalBonus,
  }) async {
    try {
      final message = _buildSchemeCompletionMessage(
        user: user,
        scheme: scheme,
        totalBonus: totalBonus,
      );

      return await sendWhatsAppMessage(
        phoneNumber: user.mobileNumber,
        message: message,
      );
    } catch (e) {
      print('Error sending scheme completion message: $e');
      return false;
    }
  }

  /// Build scheme completion message
  String _buildSchemeCompletionMessage({
    required User user,
    required UserScheme scheme,
    required double totalBonus,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('🎉 *Congratulations! Scheme Completed!*');
    buffer.writeln('');
    
    // Customer details
    buffer.writeln('👤 *Customer Details:*');
    buffer.writeln('Name: ${user.name}');
    buffer.writeln('ID: ${user.serialNumber}');
    buffer.writeln('');
    
    // Scheme details
    buffer.writeln('📋 *Scheme Details:*');
    buffer.writeln('Scheme: ${scheme.schemeType.name}');
    buffer.writeln('Total Amount: ₹${scheme.totalAmount.toStringAsFixed(0)}');
    buffer.writeln('Interest Rate: ${scheme.interestRate}%');
    buffer.writeln('Duration: 52 weeks');
    buffer.writeln('');
    
    // Bonus information
    if (totalBonus > 0) {
      buffer.writeln('🎁 *Bonus Earned:*');
      buffer.writeln('Total Bonus: ₹${totalBonus.toStringAsFixed(0)}');
      buffer.writeln('');
    }
    
    // Footer
    buffer.writeln('Thank you for completing the scheme! 🙏');
    buffer.writeln('');
    buffer.writeln('_This is an automated message from Finance Tracker App_');
    
    return buffer.toString();
  }

  // ==================== WHATSAPP INTEGRATION ====================

  /// Send WhatsApp message
  Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      print('DEBUG: WhatsApp service - Phone: $phoneNumber');
      print('DEBUG: WhatsApp service - Message length: ${message.length}');
      
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhoneNumber = _cleanPhoneNumber(phoneNumber);
      print('DEBUG: WhatsApp service - Cleaned phone: $cleanPhoneNumber');
      
      // Create WhatsApp link
      final whatsappLink = WhatsAppUnilink(
        phoneNumber: cleanPhoneNumber,
        text: message,
      );
      
      // Launch WhatsApp
      final uri = whatsappLink.asUri();
      print('DEBUG: WhatsApp service - URI: $uri');
      
      try {
        // Try to launch WhatsApp directly
        print('DEBUG: WhatsApp service - Attempting to launch WhatsApp...');
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('DEBUG: WhatsApp service - Launch result: $launched');
        
        if (launched) {
          print('DEBUG: WhatsApp service - Successfully launched WhatsApp');
          return true;
        } else {
          print('DEBUG: WhatsApp service - First attempt failed, trying fallback...');
          // Fallback: try with different launch mode
          final fallbackLaunched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          print('DEBUG: WhatsApp service - Fallback result: $fallbackLaunched');
          return fallbackLaunched;
        }
      } catch (e) {
        print('DEBUG: WhatsApp service - Error launching WhatsApp: $e');
        return false;
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      return false;
    }
  }

  /// Clean phone number for WhatsApp
  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add country code if not present (assuming India +91)
    if (cleaned.length == 10) {
      return '91$cleaned';
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      return cleaned;
    } else if (cleaned.startsWith('+91') && cleaned.length == 13) {
      return cleaned.substring(1);
    }
    
    return cleaned;
  }

  /// Get payment mode display name
  String _getPaymentModeDisplayName(dynamic paymentMode) {
    switch (paymentMode.toString()) {
      case 'PaymentMode.offline':
        return 'Cash/Offline';
      case 'PaymentMode.card':
        return 'Card Payment';
      case 'PaymentMode.upi':
        return 'UPI';
      case 'PaymentMode.netbanking':
        return 'Net Banking';
      default:
        return 'Other';
    }
  }

  // ==================== CONTACT MANAGEMENT ====================

  /// Get user's WhatsApp contact
  Future<Contact?> getUserWhatsAppContact(String phoneNumber) async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      final cleanPhone = _cleanPhoneNumber(phoneNumber);
      
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          if (_cleanPhoneNumber(phone.number) == cleanPhone) {
            return contact;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting WhatsApp contact: $e');
      return null;
    }
  }

  /// Check if WhatsApp is installed
  Future<bool> isWhatsAppInstalled() async {
    try {
      final uri = Uri.parse('whatsapp://send');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  // ==================== BULK MESSAGING ====================

  /// Send bulk payment reminders
  Future<Map<String, bool>> sendBulkPaymentReminders({
    required List<User> users,
    required Map<String, double> weeklyAmounts,
    required Map<String, double> overdueAmounts,
    required Map<String, int> overdueWeeks,
    required Map<String, DateTime> nextDueDates,
  }) async {
    final results = <String, bool>{};
    
    for (final user in users) {
      try {
        final success = await sendPaymentReminder(
          user: user,
          weeklyAmount: weeklyAmounts[user.id] ?? 0.0,
          overdueAmount: overdueAmounts[user.id] ?? 0.0,
          overdueWeeks: overdueWeeks[user.id] ?? 0,
          nextDueDate: nextDueDates[user.id] ?? DateTime.now(),
        );
        
        results[user.id] = success;
        
        // Add delay between messages to avoid rate limiting
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        results[user.id] = false;
        print('Error sending reminder to ${user.name}: $e');
      }
    }
    
    return results;
  }

  // ==================== MESSAGE TEMPLATES ====================

  /// Get available message templates
  List<String> getMessageTemplates() {
    return [
      'Payment Confirmation',
      'Payment Reminder',
      'Scheme Completion',
      'Overdue Payment Alert',
      'Weekly Reminder',
    ];
  }

  /// Get custom message template
  String getCustomMessageTemplate({
    required String templateName,
    required Map<String, dynamic> variables,
  }) {
    switch (templateName) {
      case 'Payment Confirmation':
        return _buildPaymentConfirmationMessage(
          user: variables['user'],
          transaction: variables['transaction'],
          userScheme: variables['userScheme'],
          pendingAmount: variables['pendingAmount'],
          totalBonus: variables['totalBonus'],
          nextDueDate: variables['nextDueDate'],
        );
      case 'Payment Reminder':
        return _buildPaymentReminderMessage(
          user: variables['user'],
          weeklyAmount: variables['weeklyAmount'],
          overdueAmount: variables['overdueAmount'],
          overdueWeeks: variables['overdueWeeks'],
          nextDueDate: variables['nextDueDate'],
        );
      case 'Scheme Completion':
        return _buildSchemeCompletionMessage(
          user: variables['user'],
          scheme: variables['scheme'],
          totalBonus: variables['totalBonus'],
        );
      default:
        return 'Template not found';
    }
  }
}
