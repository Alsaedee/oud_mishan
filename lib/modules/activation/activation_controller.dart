import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/activation_service.dart';
import '../../routes/app_pages.dart';
import '../../core/theme/app_colors.dart';

class ActivationController extends GetxController {
  final codeCtrl = TextEditingController();
  final isSubmitting = false.obs;

  void submitCode() {
    final code = codeCtrl.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال كود التفعيل أولاً',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isSubmitting.value = true;
    
    // Simulate brief check for visual feedback
    Future.delayed(const Duration(milliseconds: 800), () {
      final activationService = Get.find<ActivationService>();
      final success = activationService.verifyAndActivate(code);
      isSubmitting.value = false;

      if (success) {
        Get.defaultDialog(
          title: 'تم التفعيل بنجاح! 🎉',
          backgroundColor: AppColors.black,
          titleStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
          middleText: 'تهانينا! تم تفعيل برنامج عود ميشان بنجاح. يمكنك الآن استخدام كافة مميزات النظام.',
          middleTextStyle: const TextStyle(color: AppColors.white),
          textConfirm: 'دخول للبرنامج',
          buttonColor: AppColors.gold,
          confirmTextColor: AppColors.black,
          onConfirm: () {
            Get.back();
            Get.offAllNamed(Routes.LOGIN);
          },
        );
      } else {
        Get.snackbar(
          'فشل التفعيل ❌',
          'كود التفعيل الذي أدخلته غير صحيح أو منتهي الصلاحية. يرجى التحقق والتجربة مرة أخرى.',
          backgroundColor: AppColors.error,
          colorText: AppColors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    });
  }

  @override
  void onClose() {
    codeCtrl.dispose();
    super.onClose();
  }
}
