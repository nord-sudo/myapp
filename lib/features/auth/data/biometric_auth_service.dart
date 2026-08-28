import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _pinKey = 'prestamistas_user_pin';
  static const String _lockEnabledKey = 'prestamistas_lock_enabled';

  /// Track last unlock time to avoid infinite loop prompts
  static DateTime? lastUnlockedTime;

  /// Check if hardware supports biometrics or device credentials
  static Future<bool> canCheckBiometrics() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Triggers OS native Face ID / Touch ID / Biometrics prompt
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Desbloquear Prestamistas Pro RD',
  }) async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: reason,
      );
      if (authenticated) {
        lastUnlockedTime = DateTime.now();
      }
      return authenticated;
    } on PlatformException catch (e) {
      print('Biometric auth platform exception: ${e.message}');
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if app security lock is enabled (Default: FALSE - OPTIONAL as requested)
  static Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  /// Toggle security lock on/off
  static Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, enabled);
  }

  /// Check if session requires unlocking (avoids loop prompts)
  static Future<bool> shouldPromptLock() async {
    final enabled = await isLockEnabled();
    if (!enabled) return false;

    if (lastUnlockedTime != null) {
      // If unlocked less than 3 minutes ago, do not prompt again (prevents loop)
      final diff = DateTime.now().difference(lastUnlockedTime!).inMinutes;
      if (diff < 3) return false;
    }
    return true;
  }

  /// Record successful unlock
  static void markUnlocked() {
    lastUnlockedTime = DateTime.now();
  }

  /// Get stored 4-digit PIN (default '1234')
  static Future<String> getSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) ?? '1234';
  }

  /// Save new 4-digit PIN
  static Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await setLockEnabled(true);
    markUnlocked();
  }

  /// Verify entered PIN
  static Future<bool> verifyPin(String enteredPin) async {
    final savedPin = await getSavedPin();
    final isCorrect = (enteredPin == savedPin);
    if (isCorrect) {
      markUnlocked();
    }
    return isCorrect;
  }
}
