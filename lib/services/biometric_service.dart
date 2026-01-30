import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Keys for SharedPreferences
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _pinHashKey = 'pin_hash';
  static const String _loginBiometricKey = 'login_biometric_enabled';
  static const String _transactionBiometricKey =
      'transaction_biometric_enabled';

  // ============================================
  // CHECK BIOMETRIC AVAILABILITY
  // ============================================
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // ============================================
  // GET AVAILABLE BIOMETRICS
  // ============================================
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // ============================================
  // AUTHENTICATE WITH BIOMETRIC
  // ============================================
  static Future<bool> authenticateWithBiometric({
    required String reason,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(cancelButton: 'Cancel'),
        ],
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  // ============================================
  // PIN MANAGEMENT
  // ============================================

  // Hash PIN using SHA-256
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Set PIN
  static Future<bool> setPin(String pin) async {
    try {
      if (pin.length != 4 && pin.length != 6) {
        return false; // PIN must be 4 or 6 digits
      }

      final prefs = await SharedPreferences.getInstance();
      final hashedPin = _hashPin(pin);

      await prefs.setString(_pinHashKey, hashedPin);
      await prefs.setBool(_pinEnabledKey, true);

      return true;
    } catch (e) {
      print('Error setting PIN: $e');
      return false;
    }
  }

  // Verify PIN
  static Future<bool> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_pinHashKey);

      if (storedHash == null) {
        return false;
      }

      final inputHash = _hashPin(pin);
      return storedHash == inputHash;
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  // Check if PIN is set
  static Future<bool> isPinSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pinEnabledKey) ?? false;
    } catch (e) {
      print('Error checking PIN status: $e');
      return false;
    }
  }

  // Remove PIN
  static Future<bool> removePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinHashKey);
      await prefs.setBool(_pinEnabledKey, false);
      return true;
    } catch (e) {
      print('Error removing PIN: $e');
      return false;
    }
  }

  // Change PIN
  static Future<bool> changePin(String oldPin, String newPin) async {
    try {
      final isValid = await verifyPin(oldPin);

      if (!isValid) {
        return false;
      }

      return await setPin(newPin);
    } catch (e) {
      print('Error changing PIN: $e');
      return false;
    }
  }

  // ============================================
  // BIOMETRIC SETTINGS
  // ============================================

  // Enable biometric for login
  static Future<bool> enableBiometricLogin() async {
    try {
      final isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loginBiometricKey, true);
      await prefs.setBool(_biometricEnabledKey, true);

      return true;
    } catch (e) {
      print('Error enabling biometric login: $e');
      return false;
    }
  }

  // Disable biometric for login
  static Future<bool> disableBiometricLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loginBiometricKey, false);

      // If transaction biometric is also disabled, disable biometric completely
      final transactionEnabled = await isBiometricEnabledForTransactions();
      if (!transactionEnabled) {
        await prefs.setBool(_biometricEnabledKey, false);
      }

      return true;
    } catch (e) {
      print('Error disabling biometric login: $e');
      return false;
    }
  }

  // Enable biometric for transactions
  static Future<bool> enableBiometricForTransactions() async {
    try {
      final isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_transactionBiometricKey, true);
      await prefs.setBool(_biometricEnabledKey, true);

      return true;
    } catch (e) {
      print('Error enabling biometric for transactions: $e');
      return false;
    }
  }

  // Disable biometric for transactions
  static Future<bool> disableBiometricForTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_transactionBiometricKey, false);

      // If login biometric is also disabled, disable biometric completely
      final loginEnabled = await isBiometricEnabledForLogin();
      if (!loginEnabled) {
        await prefs.setBool(_biometricEnabledKey, false);
      }

      return true;
    } catch (e) {
      print('Error disabling biometric for transactions: $e');
      return false;
    }
  }

  // Check if biometric is enabled for login
  static Future<bool> isBiometricEnabledForLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_loginBiometricKey) ?? false;
    } catch (e) {
      print('Error checking biometric login status: $e');
      return false;
    }
  }

  // Check if biometric is enabled for transactions
  static Future<bool> isBiometricEnabledForTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_transactionBiometricKey) ?? false;
    } catch (e) {
      print('Error checking biometric transaction status: $e');
      return false;
    }
  }

  // Check if any biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      print('Error checking biometric status: $e');
      return false;
    }
  }

  // ============================================
  // AUTHENTICATE FOR TRANSACTION
  // ============================================
  static Future<bool> authenticateForTransaction() async {
    try {
      // Check if biometric is enabled for transactions
      final biometricEnabled = await isBiometricEnabledForTransactions();
      final pinEnabled = await isPinSet();

      // If neither is enabled, return true (no authentication required)
      if (!biometricEnabled && !pinEnabled) {
        return true;
      }

      // Try biometric first if enabled
      if (biometricEnabled) {
        final success = await authenticateWithBiometric(
          reason: 'Authenticate to confirm transaction',
        );

        if (success) {
          return true;
        }

        // If biometric fails and PIN is not set, return false
        if (!pinEnabled) {
          return false;
        }
      }

      // If biometric is not enabled or failed, use PIN if available
      // This will be handled by the UI showing PIN dialog
      return false;
    } catch (e) {
      print('Error in transaction authentication: $e');
      return false;
    }
  }

  // ============================================
  // AUTHENTICATE FOR LOGIN
  // ============================================
  static Future<bool> authenticateForLogin() async {
    try {
      final biometricEnabled = await isBiometricEnabledForLogin();

      if (!biometricEnabled) {
        return false;
      }

      return await authenticateWithBiometric(reason: 'Authenticate to login');
    } catch (e) {
      print('Error in login authentication: $e');
      return false;
    }
  }

  // ============================================
  // RESET ALL SECURITY SETTINGS
  // ============================================
  static Future<bool> resetAllSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_pinEnabledKey);
      await prefs.remove(_pinHashKey);
      await prefs.remove(_loginBiometricKey);
      await prefs.remove(_transactionBiometricKey);

      return true;
    } catch (e) {
      print('Error resetting security settings: $e');
      return false;
    }
  }

  // ============================================
  // GET BIOMETRIC TYPE NAME
  // ============================================
  static Future<String> getBiometricTypeName() async {
    try {
      final biometrics = await getAvailableBiometrics();

      if (biometrics.isEmpty) {
        return 'None';
      }

      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris';
      } else {
        return 'Biometric';
      }
    } catch (e) {
      return 'None';
    }
  }
}
