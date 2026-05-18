import 'package:get/get.dart';

class FinancialController extends GetxController {
  // Investment Plan Data
  final totalBudget = 50000.0.obs;
  final allocatedBudget = 35000.0.obs;
  
  // Expenses tracking
  final expenses = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Load some dummy expenses
    expenses.assignAll([
      {'title': 'شراء زجاجات عطر فارغة', 'amount': 1500.0, 'category': 'مواد خام', 'date': '2026-05-15'},
      {'title': 'حملة إعلانية على انستغرام', 'amount': 800.0, 'category': 'تسويق', 'date': '2026-05-16'},
      {'title': 'صيانة جهاز التعبئة', 'amount': 300.0, 'category': 'صيانة', 'date': '2026-05-17'},
    ]);
  }

  double get remainingBudget => totalBudget.value - allocatedBudget.value;
  double get totalExpenses => expenses.fold(0, (sum, item) => sum + (item['amount'] as double));

  void addExpense(String title, double amount, String category) {
    expenses.insert(0, {
      'title': title,
      'amount': amount,
      'category': category,
      'date': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD
    });
    allocatedBudget.value += amount;
    Get.snackbar('نجاح', 'تم تسجيل المصروف بنجاح', snackPosition: SnackPosition.BOTTOM);
  }

  void updateBudget(double newBudget) {
    totalBudget.value = newBudget;
  }
}
