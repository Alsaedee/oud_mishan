import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/providers/local_database.dart';
import '../products/products_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/perfume_formula_service.dart';

class SettingsController extends GetxController {
  final shopNameController = TextEditingController(text: 'Luxury Perfume');
  final selectedCurrency = 'SAR (ر.س)'.obs;
  final Rx<File?> shopLogo = Rx<File?>(null);

  // Barcode Settings
  final barcodeWidth = 50.0.obs;
  final barcodeHeight = 30.0.obs;
  final barcodeFontSize = 10.0.obs;
  final barcodeAlignment = 'Center'.obs;

  final List<String> worldCurrencies = [
    'SAR (ر.س)', 'IQD (د.ع)', 'USD (\$)', 'EUR (€)', 'GBP (£)', 'AED (د.إ)',
    'KWD (د.ك)', 'BHD (د.ب)', 'OMR (ر.ع)', 'QAR (ر.ق)', 'EGP (ج.م)',
    'JOD (د.ا)', 'TRY (₺)', 'JPY (¥)', 'CNY (¥)', 'INR (₹)'
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    shopNameController.text = prefs.getString('shopName') ?? 'Luxury Perfume';
    selectedCurrency.value = prefs.getString('currency') ?? 'SAR (ر.س)';
    barcodeWidth.value = prefs.getDouble('barcodeWidth') ?? 50.0;
    barcodeHeight.value = prefs.getDouble('barcodeHeight') ?? 30.0;
    barcodeFontSize.value = prefs.getDouble('barcodeFontSize') ?? 10.0;
    barcodeAlignment.value = prefs.getString('barcodeAlignment') ?? 'Center';
    
    String? logoPath = prefs.getString('shopLogo');
    if (logoPath != null && File(logoPath).existsSync()) {
      shopLogo.value = File(logoPath);
    }
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      shopLogo.value = File(pickedFile.path);
    }
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', shopNameController.text);
    await prefs.setString('currency', selectedCurrency.value);
    await prefs.setDouble('barcodeWidth', barcodeWidth.value);
    await prefs.setDouble('barcodeHeight', barcodeHeight.value);
    await prefs.setDouble('barcodeFontSize', barcodeFontSize.value);
    await prefs.setString('barcodeAlignment', barcodeAlignment.value);
    
    Get.find<CurrencyService>().updateCurrency(selectedCurrency.value);

    if (shopLogo.value != null) {
      await prefs.setString('shopLogo', shopLogo.value!.path);
    }

    Get.snackbar(
      'تم الحفظ',
      'تم حفظ الإعدادات بنجاح',
      backgroundColor: AppColors.success,
      colorText: AppColors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> exportDatabase() async {
    try {
      final dbPath = await LocalDatabase.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        Get.snackbar(
          'خطأ',
          'لا يوجد قاعدة بيانات لتصديرها!',
          backgroundColor: AppColors.error,
          colorText: AppColors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      if (Platform.isWindows || Platform.isMacOS) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final backupPath = '${downloadsDir.path}/luxury_pos_backup.db';
          await dbFile.copy(backupPath);
          Get.snackbar(
            'نجاح التصدير',
            'تم تصدير النسخة الاحتياطية بنجاح إلى مجلد التنزيلات:\n$backupPath',
            backgroundColor: AppColors.success,
            colorText: AppColors.white,
            duration: const Duration(seconds: 5),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
          );
        } else {
          final result = await FilePicker.platform.saveFile(
            dialogTitle: 'احفظ قاعدة البيانات',
            fileName: 'luxury_pos_backup.db',
          );
          if (result != null) {
            await dbFile.copy(result);
            Get.snackbar(
              'نجاح التصدير',
              'تم حفظ النسخة الاحتياطية بنجاح!',
              backgroundColor: AppColors.success,
              colorText: AppColors.white,
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            );
          }
        }
      } else {
        final xFile = XFile(dbPath, mimeType: 'application/x-sqlite3', name: 'luxury_pos_backup.db');
        await Share.shareXFiles([xFile], text: 'نسخة احتياطية لقاعدة بيانات العطور');
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تصدير البيانات: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> importDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await LocalDatabase.instance.importDatabaseFromFile(path);

        // Reload data if ProductsController is registered
        try {
          if (Get.isRegistered<ProductsController>()) {
            await Get.find<ProductsController>().loadProducts();
          }
        } catch (_) {}

        Get.defaultDialog(
          title: 'نجاح الاستيراد',
          backgroundColor: AppColors.black,
          titleStyle: const TextStyle(color: AppColors.gold),
          middleText: 'تم استيراد قاعدة البيانات وتحديثها بنجاح دون الحاجة لإعادة تشغيل التطبيق!',
          middleTextStyle: const TextStyle(color: AppColors.white),
          textConfirm: 'رائع',
          buttonColor: AppColors.gold,
          confirmTextColor: AppColors.black,
          onConfirm: () {
            Get.back();
          }
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء استيراد البيانات: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SettingsController());
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات - Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إعدادات المتجر الأساسية', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, color: AppColors.gold)),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildShopInfoCard(context),
                      const SizedBox(height: 24),
                      _buildCurrencyCard(context),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildBarcodeSettingsCard(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCapacityPresetsCard(context),
            const SizedBox(height: 24),
            _buildBackupRestoreCard(context),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: controller.saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('حفظ الإعدادات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بيانات المحل', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.shopNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المحل',
                      prefixIcon: Icon(Icons.store, color: AppColors.gold),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Obx(() {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.deepBlack,
                          border: Border.all(color: AppColors.gold),
                          borderRadius: BorderRadius.circular(12),
                          image: controller.shopLogo.value != null
                              ? DecorationImage(image: FileImage(controller.shopLogo.value!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: controller.shopLogo.value == null
                            ? const Icon(Icons.image, color: AppColors.grey, size: 40)
                            : null,
                      );
                    }),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: controller.pickLogo,
                      icon: const Icon(Icons.upload_file, color: AppColors.gold),
                      label: const Text('تغيير اللوجو', style: TextStyle(color: AppColors.gold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إعدادات العملة', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
              initialValue: controller.selectedCurrency.value,
              decoration: const InputDecoration(
                labelText: 'العملة الافتراضية',
                prefixIcon: Icon(Icons.monetization_on, color: AppColors.gold),
              ),
              dropdownColor: AppColors.black,
              items: controller.worldCurrencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(currency, style: const TextStyle(color: AppColors.white)),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.selectedCurrency.value = newValue;
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeSettingsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إعدادات طباعة الباركود', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Obx(() => Column(
              children: [
                _sliderRow('عرض الورق (mm)', controller.barcodeWidth.value, 20, 100, (v) => controller.barcodeWidth.value = v),
                _sliderRow('ارتفاع الورق (mm)', controller.barcodeHeight.value, 15, 80, (v) => controller.barcodeHeight.value = v),
                _sliderRow('حجم خط النص', controller.barcodeFontSize.value, 6, 24, (v) => controller.barcodeFontSize.value = v),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: controller.barcodeAlignment.value,
                  decoration: const InputDecoration(
                    labelText: 'محاذاة النص',
                    prefixIcon: Icon(Icons.format_align_center, color: AppColors.gold),
                  ),
                  dropdownColor: AppColors.black,
                  items: ['Left', 'Center', 'Right'].map((String align) {
                    return DropdownMenuItem<String>(
                      value: align,
                      child: Text(align == 'Center' ? 'منتصف' : align == 'Left' ? 'يسار' : 'يمين', style: const TextStyle(color: AppColors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) controller.barcodeAlignment.value = newValue;
                  },
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.grey)),
              Text(value.toStringAsFixed(1), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.gold,
            inactiveColor: AppColors.darkGrey,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityPresetsCard(BuildContext context) {
    final formulaService = Get.find<PerfumeFormulaService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إعدادات سعات العطور والتسعير الافتراضي للزبون', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddPresetDialog(context, formulaService),
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('إضافة سعة جديدة'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('من هنا يمكنك تحديد كمية الزيت العطري وسعر البيع النهائي للزبون (شاملاً زجاجة العطر والكحول) لكل سعة.', style: TextStyle(color: AppColors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Obx(() {
              if (formulaService.presets.isEmpty) {
                return const Center(child: Text('لا توجد سعات مضافة', style: TextStyle(color: AppColors.grey)));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: formulaService.presets.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.darkGrey),
                itemBuilder: (context, index) {
                  final preset = formulaService.presets[index];
                  return ListTile(
                    leading: const Icon(Icons.science, color: AppColors.gold),
                    title: Text(preset.name, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('زيت عطري: ${preset.oilMl} مل | كحول: ${preset.alcoholMl} مل', style: const TextStyle(color: AppColors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'السعر النهائي: ${preset.defaultSalePrice.toStringAsFixed(0)} د.ع',
                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.info),
                          onPressed: () => _showEditPresetDialog(context, formulaService, index, preset),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => formulaService.deletePreset(index),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddPresetDialog(BuildContext context, PerfumeFormulaService service) {
    final nameCtrl = TextEditingController();
    final oilCtrl = TextEditingController();
    final alcoholCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    Get.defaultDialog(
      title: 'إضافة سعة جديدة',
      backgroundColor: AppColors.black,
      titleStyle: const TextStyle(color: AppColors.gold),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'اسم السعة (مثال: 10 مل)', labelStyle: TextStyle(color: AppColors.grey)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: oilCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'كمية الزيت العطري (مل)', labelStyle: TextStyle(color: AppColors.grey)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alcoholCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'كمية الكحول (مل)', labelStyle: TextStyle(color: AppColors.grey)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'سعر البيع النهائي للزبون (د.ع)', labelStyle: TextStyle(color: AppColors.grey)),
            ),
          ],
        ),
      ),
      textConfirm: 'حفظ وإضافة',
      textCancel: 'إلغاء',
      buttonColor: AppColors.gold,
      confirmTextColor: AppColors.black,
      cancelTextColor: AppColors.grey,
      onConfirm: () {
        if (nameCtrl.text.isNotEmpty) {
          final oil = double.tryParse(oilCtrl.text) ?? 0.0;
          final alc = double.tryParse(alcoholCtrl.text) ?? 0.0;
          final price = double.tryParse(priceCtrl.text) ?? 0.0;
          
          service.addPreset(CapacityPreset(
            name: nameCtrl.text,
            capacity: oil + alc,
            oilMl: oil,
            alcoholMl: alc,
            bottlePrice: 0.0,
            defaultSalePrice: price,
          ));
          Get.back();
        }
      }
    );
  }

  void _showEditPresetDialog(BuildContext context, PerfumeFormulaService service, int index, CapacityPreset preset) {
    final nameCtrl = TextEditingController(text: preset.name);
    final oilCtrl = TextEditingController(text: preset.oilMl.toString());
    final alcoholCtrl = TextEditingController(text: preset.alcoholMl.toString());
    final priceCtrl = TextEditingController(text: preset.defaultSalePrice.toStringAsFixed(0));

    Get.defaultDialog(
      title: 'تعديل السعة',
      backgroundColor: AppColors.black,
      titleStyle: const TextStyle(color: AppColors.gold),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'اسم السعة', labelStyle: TextStyle(color: AppColors.grey)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: oilCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'كمية الزيت العطري (مل)', labelStyle: TextStyle(color: AppColors.grey)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alcoholCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'كمية الكحول (مل)', labelStyle: TextStyle(color: AppColors.grey)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'سعر البيع النهائي للزبون (د.ع)', labelStyle: TextStyle(color: AppColors.grey)),
            ),
          ],
        ),
      ),
      textConfirm: 'حفظ التعديل',
      textCancel: 'إلغاء',
      buttonColor: AppColors.gold,
      confirmTextColor: AppColors.black,
      cancelTextColor: AppColors.grey,
      onConfirm: () {
        if (nameCtrl.text.isNotEmpty) {
          final oil = double.tryParse(oilCtrl.text) ?? 0.0;
          final alc = double.tryParse(alcoholCtrl.text) ?? 0.0;
          final price = double.tryParse(priceCtrl.text) ?? 0.0;
          
          service.updatePreset(index, CapacityPreset(
            name: nameCtrl.text,
            capacity: oil + alc,
            oilMl: oil,
            alcoholMl: alc,
            bottlePrice: preset.bottlePrice,
            defaultSalePrice: price,
          ));
          Get.back();
        }
      }
    );
  }

  Widget _buildBackupRestoreCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync, color: AppColors.gold, size: 28),
                const SizedBox(width: 12),
                Text(
                  'النسخ الاحتياطي واستيراد البيانات (Sync Data)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'يمكنك تصدير قاعدة بيانات العطور والأسعار بالكامل من جهاز الكمبيوتر واستيرادها مباشرة على الآيباد لتوفير الوقت وسرعة مزامنة بياناتك بضغطة زر واحدة.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: controller.exportDatabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.upload, size: 22),
                  label: const Text(
                    'تصدير نسخة احتياطية (Export)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: controller.importDatabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlack,
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download, size: 22),
                  label: const Text(
                    'استيراد نسخة احتياطية (Import)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
