import 'package:flutter/foundation.dart';

/// Service to manage encrypted camera passwords
/// This is a simple in-memory storage for demo purposes.
/// In production, you might want to use secure storage like flutter_secure_storage
class EncryptionStorageService {
  static final EncryptionStorageService _instance =
      EncryptionStorageService._internal();
  factory EncryptionStorageService() => _instance;
  EncryptionStorageService._internal();

  // In-memory storage for demo purposes
  final Map<String, String> _encryptionPasswords = {};

  /// Store encryption password for a device
  void storePassword(String deviceSerial, String password) {
    if (password.isNotEmpty) {
      _encryptionPasswords[deviceSerial] = password;
      if (kDebugMode) {
        print('EncryptionStorage: Stored password for device $deviceSerial');
      }
    }
  }

  /// Get stored encryption password for a device
  String? getPassword(String deviceSerial) {
    final password = _encryptionPasswords[deviceSerial];
    if (kDebugMode && password != null) {
      print('EncryptionStorage: Retrieved password for device $deviceSerial');
    }
    return password;
  }

  /// Check if device has stored password
  bool hasPassword(String deviceSerial) {
    return _encryptionPasswords.containsKey(deviceSerial);
  }

  /// Remove stored password for a device
  void removePassword(String deviceSerial) {
    _encryptionPasswords.remove(deviceSerial);
    if (kDebugMode) {
      print('EncryptionStorage: Removed password for device $deviceSerial');
    }
  }

  /// Clear all stored passwords
  void clearAllPasswords() {
    _encryptionPasswords.clear();
    if (kDebugMode) {
      print('EncryptionStorage: Cleared all passwords');
    }
  }

  /// Get all devices with stored passwords
  List<String> getDevicesWithPasswords() {
    return _encryptionPasswords.keys.toList();
  }

  /// Export passwords (for backup/debugging - use with caution)
  Map<String, String> exportPasswords() {
    return Map.from(_encryptionPasswords);
  }

  /// Import passwords (for restore/testing - use with caution)
  void importPasswords(Map<String, String> passwords) {
    _encryptionPasswords.clear();
    _encryptionPasswords.addAll(passwords);
    if (kDebugMode) {
      print('EncryptionStorage: Imported ${passwords.length} passwords');
    }
  }
}