import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_pages.dart';
import '../../core/services/activation_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(seconds: 3), () {
      final activationService = Get.find<ActivationService>();
      if (activationService.isActivated) {
        Get.offNamed(Routes.LOGIN);
      } else {
        Get.offNamed(Routes.ACTIVATION);
      }
    });
  }
}

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 20,
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
                    size: 80,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'عود ميشان',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.gold,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Oud Mishan POS & AI Studio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 2,
                    color: AppColors.lightGold,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}
