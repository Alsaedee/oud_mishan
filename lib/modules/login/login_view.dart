import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_pages.dart';

class LoginController extends GetxController {
  final pinController = TextEditingController();

  void login() {
    // Implement actual authentication logic here
    Get.offAllNamed(Routes.DASHBOARD);
  }
}

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LoginController());
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_person_rounded, size: 80, color: AppColors.gold),
                    const SizedBox(height: 24),
                    Text(
                      'تسجيل الدخول',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: controller.pinController,
                      decoration: const InputDecoration(
                        labelText: 'رمز PIN',
                        prefixIcon: Icon(Icons.password, color: AppColors.gold),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.login,
                        child: const Text('دخول'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.fingerprint, color: AppColors.gold),
                      label: const Text('الدخول بالبصمة', style: TextStyle(color: AppColors.gold)),
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
