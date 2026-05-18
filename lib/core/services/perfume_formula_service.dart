import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CapacityPreset {
  final String name;       // e.g. "30 ml"
  final double capacity;   // e.g. 30.0
  final double oilMl;      // e.g. 15.0
  final double bottlePrice; // in USD or local currency (let's keep USD or IQD)
  final double alcoholMl;  // e.g. 15.0
  final double defaultSalePrice; // Default final price in local currency, e.g. 3000

  CapacityPreset({
    required this.name,
    required this.capacity,
    required this.oilMl,
    required this.bottlePrice,
    required this.alcoholMl,
    required this.defaultSalePrice,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'capacity': capacity,
    'oilMl': oilMl,
    'bottlePrice': bottlePrice,
    'alcoholMl': alcoholMl,
    'defaultSalePrice': defaultSalePrice,
  };

  factory CapacityPreset.fromJson(Map<String, dynamic> json) => CapacityPreset(
    name: json['name'] ?? '',
    capacity: (json['capacity'] as num).toDouble(),
    oilMl: (json['oilMl'] as num).toDouble(),
    bottlePrice: (json['bottlePrice'] as num).toDouble(),
    alcoholMl: (json['alcoholMl'] as num).toDouble(),
    defaultSalePrice: (json['defaultSalePrice'] ?? 0.0 as num).toDouble(),
  );
}

class PerfumeFormulaService extends GetxService {
  final presets = <CapacityPreset>[].obs;

  Future<PerfumeFormulaService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('capacity_presets');
    if (data != null) {
      final List decoded = jsonDecode(data);
      presets.assignAll(decoded.map((x) => CapacityPreset.fromJson(x)).toList());
    } else {
      // Default presets
      presets.assignAll([
        CapacityPreset(name: "10 مل", capacity: 10, oilMl: 4, bottlePrice: 0.5, alcoholMl: 6, defaultSalePrice: 3000),
        CapacityPreset(name: "30 مل", capacity: 30, oilMl: 15, bottlePrice: 1.0, alcoholMl: 15, defaultSalePrice: 8000),
        CapacityPreset(name: "50 مل", capacity: 50, oilMl: 25, bottlePrice: 1.5, alcoholMl: 25, defaultSalePrice: 12000),
        CapacityPreset(name: "75 مل", capacity: 75, oilMl: 30, bottlePrice: 2.0, alcoholMl: 45, defaultSalePrice: 18000),
        CapacityPreset(name: "100 مل", capacity: 100, oilMl: 40, bottlePrice: 2.5, alcoholMl: 60, defaultSalePrice: 25000),
      ]);
      await savePresets();
    }
    return this;
  }

  Future<void> savePresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('capacity_presets', jsonEncode(presets.map((x) => x.toJson()).toList()));
  }

  void addPreset(CapacityPreset preset) {
    presets.add(preset);
    savePresets();
  }

  void deletePreset(int index) {
    presets.removeAt(index);
    savePresets();
  }

  void updatePreset(int index, CapacityPreset preset) {
    presets[index] = preset;
    savePresets();
  }
}
