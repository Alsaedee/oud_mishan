import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends GetxService {
  final currency = 'SAR (ر.س)'.obs;

  Future<CurrencyService> init() async {
    final prefs = await SharedPreferences.getInstance();
    currency.value = prefs.getString('currency') ?? 'SAR (ر.س)';
    return this;
  }

  void updateCurrency(String newCurrency) {
    currency.value = newCurrency;
  }

  String get symbol {
    final match = RegExp(r'\((.*?)\)').firstMatch(currency.value);
    return match != null ? match.group(1) ?? 'ر.س' : 'ر.س';
  }
}
