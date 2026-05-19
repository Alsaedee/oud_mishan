import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService extends GetxService {
  final _isActivated = false.obs;
  final _isLifetime = false.obs;
  final _expiryDate = Rxn<DateTime>();
  final _activationCode = ''.obs;

  bool get isActivated => _isActivated.value;
  bool get isLifetime => _isLifetime.value;
  DateTime? get expiryDate => _expiryDate.value;
  String get activationCode => _activationCode.value;

  static const String _salt = 'OUD_MISHAN_MHD_SAADI_2026';

  Future<ActivationService> init() async {
    await checkActivationStatus();
    return this;
  }

  Future<void> checkActivationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if activated
    final activated = prefs.getBool('app_activated') ?? false;
    final code = prefs.getString('app_activation_code') ?? '';
    final lifetime = prefs.getBool('app_is_lifetime') ?? false;
    final expiryStr = prefs.getString('app_expiry_date') ?? '';

    if (activated) {
      if (lifetime) {
        _isActivated.value = true;
        _isLifetime.value = true;
        _expiryDate.value = null;
        _activationCode.value = code;
      } else if (expiryStr.isNotEmpty) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null) {
          if (DateTime.now().isAfter(expiry)) {
            // Expired!
            await deactivate();
          } else {
            _isActivated.value = true;
            _isLifetime.value = false;
            _expiryDate.value = expiry;
            _activationCode.value = code;
          }
        } else {
          await deactivate();
        }
      } else {
        await deactivate();
      }
    } else {
      await deactivate();
    }
  }

  Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_activated', false);
    await prefs.setString('app_activation_code', '');
    await prefs.setBool('app_is_lifetime', false);
    await prefs.setString('app_expiry_date', '');

    _isActivated.value = false;
    _isLifetime.value = false;
    _expiryDate.value = null;
    _activationCode.value = '';
  }

  // Generate offline code
  String generateCode(bool isLifetime, {int days = 0}) {
    if (isLifetime) {
      final checksum = _generateChecksum('LIFE_$_salt');
      return 'OM-LIFE-$checksum';
    } else {
      final checksum = _generateChecksum('DAYS_${days}_$_salt');
      return 'OM-DAYS-$days-$checksum';
    }
  }

  // Verify code
  bool verifyAndActivate(String code) {
    code = code.trim().toUpperCase();
    if (!code.startsWith('OM-')) return false;

    final parts = code.split('-');
    if (parts.length < 3) return false;

    if (parts[1] == 'LIFE') {
      final checksum = parts[2];
      final expectedChecksum = _generateChecksum('LIFE_$_salt');
      if (checksum == expectedChecksum) {
        _saveActivation(true, code, null);
        return true;
      }
    } else if (parts[1] == 'DAYS') {
      if (parts.length < 4) return false;
      final daysStr = parts[2];
      final checksum = parts[3];
      final days = int.tryParse(daysStr);
      if (days == null || days <= 0) return false;

      final expectedChecksum = _generateChecksum('DAYS_${days}_$_salt');
      if (checksum == expectedChecksum) {
        final expiry = DateTime.now().add(Duration(days: days));
        _saveActivation(false, code, expiry);
        return true;
      }
    }

    return false;
  }

  Future<void> _saveActivation(bool lifetime, String code, DateTime? expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_activated', true);
    await prefs.setString('app_activation_code', code);
    await prefs.setBool('app_is_lifetime', lifetime);
    if (expiry != null) {
      await prefs.setString('app_expiry_date', expiry.toIso8601String());
    } else {
      await prefs.setString('app_expiry_date', '');
    }

    _isActivated.value = true;
    _isLifetime.value = lifetime;
    _expiryDate.value = expiry;
    _activationCode.value = code;
  }

  String _generateChecksum(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash * 31 + input.codeUnitAt(i)) & 0xFFFF;
    }
    return hash.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
