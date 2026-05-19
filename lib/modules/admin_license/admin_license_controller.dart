import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../core/services/activation_service.dart';
import '../../core/theme/app_colors.dart';

class AdminLicenseController extends GetxController {
  final isLifetime = true.obs;
  final daysCtrl = TextEditingController(text: '30');
  final generatedCode = ''.obs;

  void toggleLifetime(bool val) {
    isLifetime.value = val;
  }

  void generateKey() {
    final service = Get.find<ActivationService>();
    if (isLifetime.value) {
      generatedCode.value = service.generateCode(true);
    } else {
      final days = int.tryParse(daysCtrl.text);
      if (days == null || days <= 0) {
        Get.snackbar(
          'خطأ',
          'يرجى إدخال عدد أيام تفعيل صحيح (مثال: 30)',
          backgroundColor: AppColors.error,
          colorText: AppColors.white,
        );
        return;
      }
      generatedCode.value = service.generateCode(false, days: days);
    }

    Get.snackbar(
      'نجاح ✨',
      'تم توليد كود تفعيل جديد بنجاح',
      backgroundColor: AppColors.success,
      colorText: AppColors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void copyKey() {
    if (generatedCode.value.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: generatedCode.value));
    
    Get.snackbar(
      'نسخ الكود 📋',
      'تم نسخ كود التفعيل إلى الحافظة بنجاح',
      backgroundColor: AppColors.success,
      colorText: AppColors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  void onClose() {
    daysCtrl.dispose();
    super.onClose();
  }
}
