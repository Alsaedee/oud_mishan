import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService extends GetxService {
  final usdToIqd = 1500.0.obs; // Default exchange rate (e.g., 1500 IQD per 1 USD)

  Future<ExchangeRateService> init() async {
    final prefs = await SharedPreferences.getInstance();
    usdToIqd.value = prefs.getDouble('usdToIqd') ?? 1500.0;
    return this;
  }

  Future<void> updateRate(double rate) async {
    usdToIqd.value = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('usdToIqd', rate);
  }

  double convertUsdToIqd(double usd) {
    return usd * usdToIqd.value;
  }
}
