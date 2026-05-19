import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'activation_controller.dart';

class ActivationView extends GetView<ActivationController> {
  const ActivationView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ActivationController());
    
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              color: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.gold, width: 1.5),
              ),
              elevation: 12,
              shadowColor: AppColors.gold.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(70),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.spa_rounded,
                            size: 70,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // App title
                    const Text(
                      'نظام عود ميشان للمبيعات والعطور',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Text(
                      'Oud Mishan POS & AI Studio',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Activation Info Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlack,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkGrey),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.lock_outline, color: AppColors.gold, size: 36),
                          SizedBox(height: 12),
                          Text(
                            'نسخة غير مفعلة - Activation Required',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'يرجى إدخال كود التفعيل المعتمد لتتمكن من استخدام التطبيق ومزامنة بياناتك مع الآيباد.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Activation Form
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'كود التفعيل (Activation Code)',
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.codeCtrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'OM-XXXX-XXXX-XXXX',
                        hintStyle: const TextStyle(color: AppColors.darkGrey, letterSpacing: 0),
                        prefixIcon: const Icon(Icons.vpn_key, color: AppColors.gold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.darkGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Activate Button
                    Obx(() => ElevatedButton(
                      onPressed: controller.isSubmitting.value ? null : controller.submitCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: controller.isSubmitting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                            )
                          : const Text(
                              'تفعيل البرنامج الآن',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    )),
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.darkGrey),
                    const SizedBox(height: 24),
                    
                    // Developer Card
                    const Text(
                      'لطلب تفعيل البرنامج والدعم الفني:',
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlack.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkGrey.withValues(alpha: 0.5)),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, color: AppColors.gold, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'المهندس محمد مهدي الساعدي',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, color: AppColors.success, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '07803240403',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, color: AppColors.error, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'العراق - العمارة',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
