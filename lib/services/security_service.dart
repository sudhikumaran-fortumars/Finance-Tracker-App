import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static SecurityService get instance => _instance;

  late Encrypter _encrypter;
  late Key _key;
  late IV _iv;

  // Initialize encryption
  Future<void> initialize() async {
    // Generate or retrieve encryption key
    final prefs = await SharedPreferences.getInstance();
    String? keyString = prefs.getString('encryption_key');
    
    if (keyString == null) {
      // Generate new key
      final key = Key.fromSecureRandom(32);
      keyString = key.base64;
      await prefs.setString('encryption_key', keyString);
    }
    
    _key = Key.fromBase64(keyString);
    _iv = IV.fromSecureRandom(16);
    _encrypter = Encrypter(AES(_key));
  }

  // Encrypt data
  String encryptData(String data) {
    final encrypted = _encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }

  // Decrypt data
  String decryptData(String encryptedData) {
    final encrypted = Encrypted.fromBase64(encryptedData);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  // Generate secure key
  String generateKey() {
    final key = Key.fromSecureRandom(32);
    return key.base64;
  }

  // Hash password
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify password
  bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  // Sanitize input
  String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll('<', '') // Remove potentially dangerous characters
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(RegExp(r'\s+'), ' '); // Replace multiple spaces with single space
  }

  // Sanitize user input
  Map<String, dynamic> sanitizeUserInput(Map<String, dynamic> input) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in input.entries) {
      if (entry.value is String) {
        sanitized[entry.key] = sanitizeInput(entry.value);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }

  // Validate email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number
  bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  // Generate secure token
  String generateSecureToken() {
    final random = Key.fromSecureRandom(32);
    return random.base64;
  }

  // Encrypt sensitive fields
  Map<String, dynamic> encryptSensitiveFields(Map<String, dynamic> data) {
    final encrypted = Map<String, dynamic>.from(data);
    
    // Encrypt sensitive fields
    const sensitiveFields = ['password', 'ssn', 'creditCard', 'bankAccount'];
    
    for (final field in sensitiveFields) {
      if (encrypted.containsKey(field) && encrypted[field] is String) {
        encrypted[field] = encryptData(encrypted[field]);
      }
    }
    
    return encrypted;
  }

  // Decrypt sensitive fields
  Map<String, dynamic> decryptSensitiveFields(Map<String, dynamic> data) {
    final decrypted = Map<String, dynamic>.from(data);
    
    // Decrypt sensitive fields
    const sensitiveFields = ['password', 'ssn', 'creditCard', 'bankAccount'];
    
    for (final field in sensitiveFields) {
      if (decrypted.containsKey(field) && decrypted[field] is String) {
        try {
          decrypted[field] = decryptData(decrypted[field]);
        } catch (e) {
          // If decryption fails, keep original value
          print('Failed to decrypt field $field: $e');
        }
      }
    }
    
    return decrypted;
  }

  // Check if data is encrypted
  bool isEncrypted(String data) {
    try {
      // Try to decode as base64
      base64Decode(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Secure data storage
  Future<void> storeSecureData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = encryptData(value);
    await prefs.setString('secure_$key', encrypted);
  }

  // Retrieve secure data
  Future<String?> getSecureData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString('secure_$key');
    
    if (encrypted != null) {
      try {
        return decryptData(encrypted);
      } catch (e) {
        print('Failed to decrypt secure data for key $key: $e');
        return null;
      }
    }
    
    return null;
  }

  // Clear secure data
  Future<void> clearSecureData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('secure_$key');
  }

  // Clear all secure data
  Future<void> clearAllSecureData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith('secure_')) {
        await prefs.remove(key);
      }
    }
  }

  // Security audit log
  Future<void> logSecurityEvent(String event, Map<String, dynamic>? details) async {
    final timestamp = DateTime.now().toIso8601String();
    // final logEntry = {
    //   'timestamp': timestamp,
    //   'event': event,
    //   'details': details,
    // };
    
    print('Security Event: $event at $timestamp');
    if (details != null) {
      print('Details: $details');
    }
  }

  // Validate data integrity
  bool validateDataIntegrity(Map<String, dynamic> data, String checksum) {
    final jsonString = jsonEncode(data);
    final calculatedChecksum = hashPassword(jsonString);
    return calculatedChecksum == checksum;
  }

  // Generate data checksum
  String generateDataChecksum(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return hashPassword(jsonString);
  }
}
