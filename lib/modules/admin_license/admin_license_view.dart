import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'admin_license_controller.dart';

class AdminLicenseView extends GetView<AdminLicenseController> {
  const AdminLicenseView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AdminLicenseController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 توليد كود تفعيل النظام (المدير)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'لوحة تحكم التراخيص - License Generator',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 24,
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'من هنا يمكنك بصفتك المطور والمدير توليد أكواد تفعيل وتراخيص للبرنامج صالحة للعمل مدى الحياة أو لفترة محددة.',
                  style: TextStyle(color: AppColors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Generator Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. اختر نوع فترة الاشتراك',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() => Row(
                              children: [
                                Expanded(
                                  child: _buildChoiceCard(
                                    title: 'اشتراك مدى الحياة (Lifetime)',
                                    subtitle: 'تفعيل دائم للبرنامج دون انتهاء صلاحية',
                                    icon: Icons.all_inclusive,
                                    isSelected: controller.isLifetime.value,
                                    onTap: () => controller.toggleLifetime(true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildChoiceCard(
                                    title: 'اشتراك لفترة محددة',
                                    subtitle: 'ينتهي بعد عدد معين من الأيام',
                                    icon: Icons.date_range,
                                    isSelected: !controller.isLifetime.value,
                                    onTap: () => controller.toggleLifetime(false),
                                  ),
                                ),
                              ],
                            )),
                        const SizedBox(height: 32),

                        // Custom Period Duration Input
                        Obx(() {
                          if (controller.isLifetime.value) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '2. حدد مدة الاشتراك بالأيام',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: TextField(
                                      controller: controller.daysCtrl,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: AppColors.white, fontSize: 18),
                                      decoration: const InputDecoration(
                                        labelText: 'عدد الأيام',
                                        suffixText: 'يوم',
                                        prefixIcon: Icon(Icons.timer, color: AppColors.gold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Presets
                                  _presetButton('شهر (30 يوم)', '30'),
                                  const SizedBox(width: 8),
                                  _presetButton('3 أشهر (90 يوم)', '90'),
                                  const SizedBox(width: 8),
                                  _presetButton('سنة (365 يوم)', '365'),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          );
                        }),

                        // Action Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: controller.generateKey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.bolt, size: 22),
                            label: const Text(
                              'توليد كود التفعيل الآن',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Generated Key Display Card
                Obx(() {
                  if (controller.generatedCode.value.isEmpty) return const SizedBox.shrink();
                  return Card(
                    color: AppColors.deepBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.success, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'تم توليد كود التفعيل بنجاح!',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'قم بنسخ هذا الكود وإعطائه للعميل لتفعيل نسخته على جهاز الكمبيوتر أو جهاز الآيباد الخاص به.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          
                          // Display Code Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.darkGrey),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: controller.copyKey,
                                  icon: const Icon(Icons.copy, color: AppColors.gold, size: 24),
                                  tooltip: 'نسخ الكود',
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SelectableText(
                                    controller.generatedCode.value,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 20,
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.08) : AppColors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.darkGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.gold : AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.lightGrey,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetButton(String label, String value) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.black,
      labelStyle: const TextStyle(color: AppColors.gold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.gold, width: 0.8),
      ),
      onPressed: () {
        controller.daysCtrl.text = value;
      },
    );
  }
}
