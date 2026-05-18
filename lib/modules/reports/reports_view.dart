import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'reports_controller.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية والمبيعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadReports,
            tooltip: 'تحديث البيانات',
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Selling Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔥 العطور الأكثر طلباً ومبيعاً', style: TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: controller.topSelling.isEmpty
                          ? const Center(child: Text('لا توجد مبيعات حتى الآن', style: TextStyle(color: AppColors.grey)))
                          : ListView.builder(
                              itemCount: controller.topSelling.length,
                              itemBuilder: (context, index) {
                                final item = controller.topSelling[index];
                                return Card(
                                  color: AppColors.black,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.deepBlack,
                                      child: Text('#${index + 1}', style: const TextStyle(color: AppColors.gold)),
                                    ),
                                    title: Text(item['product_name'].toString(), style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                                    trailing: Text('${item['total_ml']} مل', style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Unsold Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('❄️ العطور الراكدة (لم تُباع بعد)', style: TextStyle(color: AppColors.info, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: controller.unsold.isEmpty
                          ? const Center(child: Text('جميع المنتجات تم بيعها على الأقل مرة واحدة!', style: TextStyle(color: AppColors.success)))
                          : ListView.builder(
                              itemCount: controller.unsold.length,
                              itemBuilder: (context, index) {
                                final item = controller.unsold[index];
                                return Card(
                                  color: AppColors.black,
                                  child: ListTile(
                                    leading: const Icon(Icons.inventory_2, color: AppColors.grey),
                                    title: Text(item['name'].toString(), style: const TextStyle(color: AppColors.white)),
                                    trailing: Text('المتوفر: ${item['stock']} مل', style: const TextStyle(color: AppColors.grey)),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
