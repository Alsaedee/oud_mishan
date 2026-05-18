import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/currency_service.dart';
import 'financial_controller.dart';

class FinancialView extends StatelessWidget {
  const FinancialView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinancialController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخطة الاستثمارية والمصروفات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddExpenseDialog(context, controller),
            tooltip: 'إضافة مصروف جديد',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الملخص المالي', style: TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildBudgetCard('رأس المال الكلي', controller.totalBudget, AppColors.info)),
                const SizedBox(width: 16),
                Expanded(child: _buildBudgetCard('الميزانية المصروفة', controller.allocatedBudget, AppColors.warning)),
                const SizedBox(width: 16),
                Expanded(child: Obx(() => _buildStatCard('الميزانية المتبقية', controller.remainingBudget, AppColors.success))),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('سجل المصروفات', style: TextStyle(color: AppColors.lightGold, fontSize: 20)),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkGrey),
                        ),
                        child: Obx(() => ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.expenses.length,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.darkGrey, height: 1),
                          itemBuilder: (context, index) {
                            final expense = controller.expenses[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.deepBlack,
                                child: Icon(Icons.money_off, color: AppColors.error, size: 20),
                              ),
                              title: Text(expense['title'], style: const TextStyle(color: AppColors.white)),
                              subtitle: Text('${expense['category']} • ${expense['date']}', style: const TextStyle(color: AppColors.grey)),
                              trailing: Text('${expense['amount']} ${Get.find<CurrencyService>().symbol}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                            );
                          },
                        )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('توزيع المصروفات', style: TextStyle(color: AppColors.lightGold, fontSize: 20)),
                      const SizedBox(height: 16),
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkGrey),
                        ),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(color: AppColors.gold, value: 40, title: 'مواد خام', radius: 50, titleStyle: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
                              PieChartSectionData(color: AppColors.info, value: 30, title: 'تسويق', radius: 50, titleStyle: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
                              PieChartSectionData(color: AppColors.warning, value: 15, title: 'رواتب', radius: 50, titleStyle: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
                              PieChartSectionData(color: AppColors.error, value: 15, title: 'أخرى', radius: 50, titleStyle: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              color: AppColors.black,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('توقعات الأرباح والتدفق المالي للخطة الاستثمارية', style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('مقارنة بين رأس المال التراكمي (الذهبي) والأرباح المتوقعة (الأزرق) خلال 6 أشهر قادمة', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0: return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text('الشهر 1', style: TextStyle(color: AppColors.grey, fontSize: 10)));
                                    case 1: return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text('الشهر 2', style: TextStyle(color: AppColors.grey, fontSize: 10)));
                                    case 2: return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text('الشهر 3', style: TextStyle(color: AppColors.grey, fontSize: 10)));
                                    case 3: return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text('الشهر 4', style: TextStyle(color: AppColors.grey, fontSize: 10)));
                                    case 4: return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text('الشهر 5', style: TextStyle(color: AppColors.grey, fontSize: 10)));
                                    case 5: return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text('الشهر 6', style: TextStyle(color: AppColors.grey, fontSize: 10)));
                                  }
                                  return const Text('');
                                }
                              )
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 10000), FlSpot(1, 12000), FlSpot(2, 16000), FlSpot(3, 22000), FlSpot(4, 30000), FlSpot(5, 45000)
                              ],
                              isCurved: true,
                              color: AppColors.gold,
                              barWidth: 4,
                              belowBarData: BarAreaData(show: true, color: AppColors.gold.withValues(alpha: 0.15)),
                            ),
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 5000), FlSpot(1, 8000), FlSpot(2, 12000), FlSpot(3, 19000), FlSpot(4, 28000), FlSpot(5, 40000)
                              ],
                              isCurved: true,
                              color: AppColors.info,
                              barWidth: 3,
                              belowBarData: BarAreaData(show: true, color: AppColors.info.withValues(alpha: 0.1)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(String title, RxDouble amount, Color color) {
    return Obx(() => _buildStatCard(title, amount.value, color));
  }

  Widget _buildStatCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text('${amount.toStringAsFixed(2)} ${Get.find<CurrencyService>().symbol}', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, FinancialController controller) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCategory = 'مواد خام';
    final categories = ['مواد خام', 'تسويق', 'رواتب', 'إيجار', 'صيانة', 'أخرى'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text('تسجيل مصروف جديد', style: TextStyle(color: AppColors.gold)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(labelText: 'وصف المصروف', labelStyle: TextStyle(color: AppColors.grey)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(labelText: 'المبلغ (${Get.find<CurrencyService>().symbol})', labelStyle: const TextStyle(color: AppColors.grey)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  dropdownColor: AppColors.deepBlack,
                  style: const TextStyle(color: AppColors.white),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                  decoration: const InputDecoration(labelText: 'التصنيف', labelStyle: TextStyle(color: AppColors.grey)),
                ),
              ],
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء', style: TextStyle(color: AppColors.grey))),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (titleCtrl.text.isNotEmpty && amt > 0) {
                controller.addExpense(titleCtrl.text, amt, selectedCategory);
                Get.back();
              }
            },
            child: const Text('حفظ المصروف'),
          ),
        ],
      ),
    );
  }
}
