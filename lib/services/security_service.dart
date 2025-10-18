import 'dart:convert';
import 'dart:typed_data';
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
    await _initializeEncryptionKey();
    
    // Initialize encrypter
    _encrypter = Encrypter(AES(_key));
  }

  // Initialize encryption key
  Future<void> _initializeEncryptionKey() async {
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
  }

  // ==================== ENCRYPTION ====================

  /// Encrypt sensitive data
  String encryptData(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt sensitive data
  String decryptData(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Encrypt user data
  Map<String, dynamic> encryptUserData(Map<String, dynamic> userData) {
    final encryptedData = <String, dynamic>{};
    
    // Encrypt sensitive fields
    final sensitiveFields = ['name', 'mobileNumber', 'address'];
    
    for (final entry in userData.entries) {
      if (sensitiveFields.contains(entry.key)) {
        encryptedData[entry.key] = encryptData(entry.value.toString());
      } else {
        encryptedData[entry.key] = entry.value;
      }
    }
    
    return encryptedData;
  }

  /// Decrypt user data
  Map<String, dynamic> decryptUserData(Map<String, dynamic> encryptedData) {
    final decryptedData = <String, dynamic>{};
    
    // Decrypt sensitive fields
    final sensitiveFields = ['name', 'mobileNumber', 'address'];
    
    for (final entry in encryptedData.entries) {
      if (sensitiveFields.contains(entry.key)) {
        try {
          decryptedData[entry.key] = decryptData(entry.value.toString());
        } catch (e) {
          // If decryption fails, use original value (might be unencrypted)
          decryptedData[entry.key] = entry.value;
        }
      } else {
        decryptedData[entry.key] = entry.value;
      }
    }
    
    return decryptedData;
  }

  // ==================== HASHING ====================

  /// Hash password
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash sensitive data
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure token
  String generateSecureToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  // ==================== VALIDATION ====================

  /// Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  /// Validate password strength
  bool isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  /// Validate amount format
  bool isValidAmount(String amount) {
    final amountRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    return amountRegex.hasMatch(amount);
  }

  // ==================== SANITIZATION ====================

  /// Sanitize input data
  String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>"\']'), '') // Remove potentially dangerous characters
        .replaceAll(RegExp(r'\s+'), ' '); // Replace multiple spaces with single space
  }

  /// Sanitize user input
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

  // ==================== SECURITY CHECKS ====================

  /// Check for SQL injection patterns
  bool containsSQLInjection(String input) {
    final sqlPatterns = [
      r'(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)',
      r'(\b(OR|AND)\s+\d+\s*=\s*\d+)',
      r'(\b(OR|AND)\s+\w+\s*=\s*\w+)',
      r'(\b(OR|AND)\s+\w+\s*LIKE\s*[\'"])',
      r'(\b(OR|AND)\s+\w+\s*IN\s*[\'"])',
      r'(\b(OR|AND)\s+\w+\s*BETWEEN\s+\d+\s+AND\s+\d+)',
      r'(\b(OR|AND)\s+\w+\s*IS\s+NULL)',
      r'(\b(OR|AND)\s+\w+\s*IS\s+NOT\s+NULL)',
    ];
    
    for (final pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return true;
      }
    }
    
    return false;
  }

  /// Check for XSS patterns
  bool containsXSS(String input) {
    final xssPatterns = [
      r'<script[^>]*>.*?</script>',
      r'<iframe[^>]*>.*?</iframe>',
      r'<object[^>]*>.*?</object>',
      r'<embed[^>]*>.*?</embed>',
      r'<link[^>]*>.*?</link>',
      r'<meta[^>]*>.*?</meta>',
      r'javascript:',
      r'vbscript:',
      r'onload\s*=',
      r'onerror\s*=',
      r'onclick\s*=',
      r'onmouseover\s*=',
    ];
    
    for (final pattern in xssPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return true;
      }
    }
    
    return false;
  }

  /// Validate input security
  bool isSecureInput(String input) {
    return !containsSQLInjection(input) && !containsXSS(input);
  }

  // ==================== AUDIT LOGGING ====================

  /// Log security event
  Future<void> logSecurityEvent({
    required String eventType,
    required String userId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final auditLog = {
      'event_type': eventType,
      'user_id': userId,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };
    
    // Store audit log securely
    final prefs = await SharedPreferences.getInstance();
    final existingLogs = prefs.getStringList('audit_logs') ?? [];
    existingLogs.add(jsonEncode(auditLog));
    
    // Keep only last 1000 logs
    if (existingLogs.length > 1000) {
      existingLogs.removeRange(0, existingLogs.length - 1000);
    }
    
    await prefs.setStringList('audit_logs', existingLogs);
  }

  /// Get audit logs
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('audit_logs') ?? [];
    
    return logs.map((log) => jsonDecode(log) as Map<String, dynamic>).toList();
  }

  // ==================== DATA PROTECTION ====================

  /// Mask sensitive data for display
  String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    
    final visible = data.substring(0, visibleChars);
    final masked = '*' * (data.length - visibleChars);
    return visible + masked;
  }

  /// Mask phone number
  String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 4) {
      return '*' * phoneNumber.length;
    }
    
    final visible = phoneNumber.substring(phoneNumber.length - 4);
    final masked = '*' * (phoneNumber.length - 4);
    return masked + visible;
  }

  /// Mask email
  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return '*' * username.length + '@' + domain;
    }
    
    final visible = username.substring(0, 2);
    final masked = '*' * (username.length - 2);
    return visible + masked + '@' + domain;
  }

  // ==================== SECURITY POLICIES ====================

  /// Check password policy
  Map<String, bool> checkPasswordPolicy(String password) {
    return {
      'length': password.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'number': RegExp(r'\d').hasMatch(password),
      'special': RegExp(r'[@$!%*?&]').hasMatch(password),
    };
  }

  /// Check session security
  bool isSessionSecure() {
    // Check if session is still valid
    // This would typically check against a server-side session store
    return true; // Simplified for now
  }

  /// Generate secure session token
  String generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (DateTime.now().microsecondsSinceEpoch % 1000000).toString();
    final data = timestamp + random;
    return hashData(data);
  }
}
