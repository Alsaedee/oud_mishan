import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(seconds: 3), () {
      Get.offNamed(Routes.LOGIN);
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
            Icon(Icons.spa_rounded, size: 100, color: AppColors.gold),
            const SizedBox(height: 24),
            Text(
              'LUXURY PERFUME',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 8,
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'POS & AI STUDIO',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 4,
                    color: AppColors.lightGold,
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
