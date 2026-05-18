import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';

class AIFormulaController extends GetxController {
  final searchController = TextEditingController();
  final isGenerating = false.obs;
  final formulaResult = {}.obs;

  void generateFormula() {
    if (searchController.text.isEmpty) return;
    isGenerating.value = true;
    formulaResult.clear();

    // Simulate AI generation delay
    Future.delayed(const Duration(seconds: 3), () {
      isGenerating.value = false;
      formulaResult.value = {
        'name': searchController.text,
        'top_notes': 'Bergamot, Pepper',
        'middle_notes': 'Lavender, Pink Pepper, Vetiver, Patchouli',
        'base_notes': 'Ambroxan, Cedar, Labdanum',
        'recipe': [
          {'ingredient': 'Fragrance Oil (Sauvage Type)', 'percentage': '20%'},
          {'ingredient': 'Perfumer\'s Alcohol', 'percentage': '75%'},
          {'ingredient': 'Fixative (Glucam P-20)', 'percentage': '3%'},
          {'ingredient': 'Distilled Water', 'percentage': '2%'},
        ],
        'instructions': '1. Mix fragrance oil with alcohol.\n2. Add fixative and stir gently.\n3. Add distilled water.\n4. Macerate in a cool dark place for 3 weeks.',
        'cost_estimate': '45 ر.س لـ 100ml',
      };
    });
  }
}

class AIFormulaView extends GetView<AIFormulaController> {
  const AIFormulaView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AIFormulaController());
    return Scaffold(
      appBar: AppBar(title: const Text('مصمم العطور AI')),
      body: Row(
        children: [
          // Left side: Input & Generation
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              color: AppColors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('أدخل اسم عطر مشهور', style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.searchController,
                    decoration: const InputDecoration(
                      hintText: 'مثال: Dior Sauvage...',
                      prefixIcon: Icon(Icons.science, color: AppColors.gold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.generateFormula,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('توليد التركيبة (Formula)'),
                    ),
                  ),
                  const Spacer(),
                  Image.asset('assets/images/ai_lab.png', errorBuilder: (c, e, s) => const Icon(Icons.biotech, size: 100, color: AppColors.darkGrey)),
                ],
              ),
            ),
          ),
          // Right side: Results
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: Obx(() {
                if (controller.isGenerating.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.gold),
                        SizedBox(height: 16),
                        Text('يتم الآن تحليل النوتات العطرية...', style: TextStyle(color: AppColors.gold)),
                      ],
                    ),
                  );
                }

                if (controller.formulaResult.isEmpty) {
                  return const Center(
                    child: Text('اكتب اسم العطر لبدء التحليل بالذكاء الاصطناعي', style: TextStyle(color: AppColors.grey, fontSize: 18)),
                  );
                }

                final res = controller.formulaResult;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تركيبة: ${res['name']}', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28, color: AppColors.gold)),
                      const Divider(color: AppColors.gold, thickness: 2),
                      const SizedBox(height: 16),
                      
                      _sectionTitle('النوتات العطرية (Notes)'),
                      _infoRow('الافتتاحية (Top):', res['top_notes']),
                      _infoRow('القلب (Middle):', res['middle_notes']),
                      _infoRow('القاعدة (Base):', res['base_notes']),
                      
                      const SizedBox(height: 24),
                      _sectionTitle('النسب المئوية (Formula)'),
                      ...List.generate(
                        res['recipe'].length,
                        (index) => _infoRow(res['recipe'][index]['ingredient'], res['recipe'][index]['percentage']),
                      ),

                      const SizedBox(height: 24),
                      _sectionTitle('التكلفة التقريبية'),
                      Text(res['cost_estimate'], style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 24),
                      _sectionTitle('خطوات التحضير والتعتيق'),
                      Text(res['instructions'], style: const TextStyle(color: AppColors.white, fontSize: 16, height: 1.5)),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.save), label: const Text('حفظ التركيبة')),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: (){},
                            icon: const Icon(Icons.print),
                            label: const Text('طباعة الباركود والوصفة'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGrey, foregroundColor: AppColors.white),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(color: AppColors.lightGold, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: const TextStyle(color: AppColors.grey, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.white))),
        ],
      ),
    );
  }
}
