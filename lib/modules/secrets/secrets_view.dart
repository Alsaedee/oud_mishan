import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'secrets_controller.dart';

class SecretsView extends StatelessWidget {
  const SecretsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SecretsController());
    final pinCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 سجل الخلطات السرية والملاحظات'),
        actions: [
          Obx(() => controller.isAuthenticated.value
              ? IconButton(
                  icon: const Icon(Icons.vpn_key),
                  onPressed: () => _showChangePasscodeDialog(context, controller),
                  tooltip: 'تغيير رمز المرور',
                )
              : const SizedBox.shrink())
        ],
      ),
      body: Obx(() {
        if (!controller.isAuthenticated.value) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              child: Card(
                color: AppColors.black,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 64, color: AppColors.gold),
                      const SizedBox(height: 24),
                      const Text(
                        'الخزنة محمية برمز مرور',
                        style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'الرمز الافتراضي هو 1234',
                        style: TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: pinCtrl,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.white, fontSize: 24, letterSpacing: 8),
                        decoration: const InputDecoration(
                          hintText: '••••',
                          hintStyle: TextStyle(color: AppColors.grey),
                        ),
                        onSubmitted: (val) => controller.checkPasscode(val),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => controller.checkPasscode(pinCtrl.text),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                        child: const Text('دخول'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الخلطات والتركيبات الخاصة', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFormulaDialog(context, controller),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('إضافة تركيبة جديدة'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: controller.formulas.isEmpty
                    ? const Center(child: Text('لا توجد خلطات سرية مضافة بعد.', style: TextStyle(color: AppColors.grey)))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: controller.formulas.length,
                        itemBuilder: (context, index) {
                          final f = controller.formulas[index];
                          return Card(
                            color: AppColors.darkGrey,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(f['name'], style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                                        onPressed: () => controller.deleteFormula(f['id']),
                                      )
                                    ],
                                  ),
                                  const Divider(color: AppColors.grey),
                                  const SizedBox(height: 8),
                                  const Text('التركيبة والخلطة:', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(f['recipe'], style: const TextStyle(color: AppColors.lightGrey, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  const Text('الملاحظات والخطوات:', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(f['notes'] ?? '', style: const TextStyle(color: AppColors.lightGrey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        );
      }),
    );
  }

  void _showAddFormulaDialog(BuildContext context, SecretsController controller) {
    final nameCtrl = TextEditingController();
    final recipeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text('إضافة تركيبة سرية جديدة', style: TextStyle(color: AppColors.gold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(labelText: 'اسم التركيبة'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: recipeCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(labelText: 'النسب والمكونات (مثال: عود 50%، صندل 20%)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(labelText: 'طريقة التحضير والملاحظات'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء', style: TextStyle(color: AppColors.grey))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && recipeCtrl.text.isNotEmpty) {
                controller.addFormula(nameCtrl.text, recipeCtrl.text, notesCtrl.text);
                Get.back();
              }
            },
            child: const Text('حفظ في الخزنة'),
          ),
        ],
      ),
    );
  }

  void _showChangePasscodeDialog(BuildContext context, SecretsController controller) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text('تغيير رمز المرور', style: TextStyle(color: AppColors.gold)),
        content: TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(labelText: 'رمز المرور الجديد (4 أرقام)'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء', style: TextStyle(color: AppColors.grey))),
          ElevatedButton(
            onPressed: () {
              if (codeCtrl.text.isNotEmpty) {
                controller.changePasscode(codeCtrl.text);
                Get.back();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
