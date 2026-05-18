import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'personality_analysis_controller.dart';

class PersonalityAnalysisView extends StatelessWidget {
  const PersonalityAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PersonalityAnalysisController());

    return Scaffold(
      appBar: AppBar(title: const Text('تحليل شخصية العميل')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Notes Selection
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. اختر النوتات المفضلة للعميل', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.availableNotes.map((note) {
                            return Obx(() {
                              final isSelected = controller.selectedNotes.contains(note);
                              return ChoiceChip(
                                label: Text(note),
                                selected: isSelected,
                                onSelected: (_) => controller.toggleNote(note),
                                selectedColor: AppColors.gold,
                                labelStyle: TextStyle(color: isSelected ? AppColors.black : AppColors.white),
                                backgroundColor: AppColors.darkGrey,
                              );
                            });
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.analyzePersonality,
                        icon: const Icon(Icons.psychology),
                        label: const Text('تحليل الشخصية واستخراج العطر'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Right Side: Analysis Results
            Expanded(
              flex: 1,
              child: Obx(() {
                if (controller.isAnalyzing.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.gold),
                        SizedBox(height: 16),
                        Text('يتم الآن تحليل الشخصية بناءً على النوتات...', style: TextStyle(color: AppColors.gold)),
                      ],
                    ),
                  );
                }

                if (controller.recommendedProducts.isEmpty && controller.selectedNotes.isEmpty) {
                  return const Center(child: Text('النتائج ستظهر هنا بعد التحليل', style: TextStyle(color: AppColors.grey, fontSize: 18)));
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نتيجة التحليل', style: TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text(controller.getPersonalityDescription(), style: const TextStyle(color: AppColors.white, fontSize: 18, height: 1.5)),
                      const SizedBox(height: 32),
                      const Text('العطور المقترحة من المخزون:', style: TextStyle(color: AppColors.lightGold, fontSize: 20)),
                      const SizedBox(height: 16),
                      if (controller.recommendedProducts.isEmpty)
                        const Text('لا توجد عطور مطابقة لهذه النوتات في المخزون الحالي.', style: TextStyle(color: AppColors.grey)),
                      if (controller.recommendedProducts.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: controller.recommendedProducts.length,
                            itemBuilder: (context, index) {
                              final product = controller.recommendedProducts[index];
                              return Card(
                                color: AppColors.black,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const Icon(Icons.water_drop, color: AppColors.gold),
                                  title: Text(product['name'], style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text('النوتات المتوفرة: ${product['notes'] ?? 'غير محدد'}', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                                  trailing: Text('${product['price']} ر.س', style: const TextStyle(color: AppColors.success)),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
