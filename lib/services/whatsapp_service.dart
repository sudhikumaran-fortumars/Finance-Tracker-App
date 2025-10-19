import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/user_scheme.dart';

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  static WhatsAppService get instance => _instance;

  /// Send payment confirmation message
  Future<bool> sendPaymentConfirmation({
    required User user,
    required Transaction transaction,
    required UserScheme userScheme,
    required double pendingAmount,
    required double totalBonus,
    DateTime? nextDueDate,
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

  /// Send payment reminder message
  Future<bool> sendPaymentReminder({
    required User user,
    required UserScheme userScheme,
    required double pendingAmount,
    required DateTime nextDueDate,
  }) async {
    try {
      final message = _buildPaymentReminderMessage(
        user: user,
        userScheme: userScheme,
        pendingAmount: pendingAmount,
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

  /// Send custom message
  Future<bool> sendCustomMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      return await sendWhatsAppMessage(
        phoneNumber: phoneNumber,
        message: message,
      );
    } catch (e) {
      print('Error sending custom WhatsApp message: $e');
      return false;
    }
  }

  // ==================== WHATSAPP INTEGRATION ====================

  /// Send WhatsApp message
  Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      
      // Create WhatsApp link
      final whatsappLink = WhatsAppUnilink(
        phoneNumber: cleanNumber,
        text: message,
      );

      // Launch WhatsApp
      final uri = whatsappLink.asUri();
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Try to launch WhatsApp directly
        final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}');
        
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          return true;
        } else {
          print('WhatsApp not available');
          return false;
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      return false;
    }
  }

  /// Clean phone number for WhatsApp
  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add country code if not present (assuming India +91)
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }
    
    return cleaned;
  }

  /// Build payment confirmation message
  String _buildPaymentConfirmationMessage({
    required User user,
    required Transaction transaction,
    required UserScheme userScheme,
    required double pendingAmount,
    required double totalBonus,
    DateTime? nextDueDate,
  }) {
    final nextDue = nextDueDate != null 
        ? '${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}'
        : 'TBD';
    
    // Calculate weekly amount
    final weeklyAmount = userScheme.totalAmount / 52;
    
    return '''
*Payment Received Successfully!*

  *Customer Details:*
Name: ${user.name}
ID: ${user.serialNumber}

  *Payment Details:*
Amount: ₹${transaction.amount.toStringAsFixed(0)}
Date: ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}
Mode: ${transaction.paymentMode.name == 'offline' ? 'Cash/Offline' : transaction.paymentMode.name.toUpperCase()}
Receipt: RCP${transaction.id}

  *Scheme Information:*
Scheme: ${userScheme.schemeType.name}
Weekly Amount: ₹${weeklyAmount.toStringAsFixed(0)}
Total Amount: ₹${userScheme.totalAmount.toStringAsFixed(0)}

  *Financial Summary:*
Pending Amount: ₹${pendingAmount.toStringAsFixed(0)}
Total Bonus Earned: ₹${totalBonus.toStringAsFixed(0)}

  *Next Due Date:*
$nextDue

Thank you for your payment!  

This is an automated message from Finance Tracker App
    ''';
  }

  /// Build payment reminder message
  String _buildPaymentReminderMessage({
    required User user,
    required UserScheme userScheme,
    required double pendingAmount,
    required DateTime nextDueDate,
  }) {
    return '''
🔔 *Payment Reminder*

Hello ${user.name},

This is a friendly reminder about your upcoming payment:

📋 *Scheme:* ${userScheme.schemeType.name}
💵 *Pending Amount:* ₹${pendingAmount.toStringAsFixed(2)}
📅 *Due Date:* ${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}

Please make your payment on time to avoid any inconvenience.

Thank you! 🙏

_Finance Tracker App_
    ''';
  }

  /// Get user's WhatsApp contact
  Future<Contact?> getUserWhatsAppContact(String phoneNumber) async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
        );
        
        final cleanNumber = _cleanPhoneNumber(phoneNumber);
        
        for (final contact in contacts) {
          for (final phone in contact.phones) {
            if (_cleanPhoneNumber(phone.number) == cleanNumber) {
              return contact;
            }
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
}
