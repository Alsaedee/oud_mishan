import 'package:get/get.dart';
import '../../data/providers/local_database.dart';

class ReportsController extends GetxController {
  final isLoading = true.obs;
  
  final topSelling = <Map<String, dynamic>>[].obs;
  final unsold = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    isLoading.value = true;
    try {
      final db = await LocalDatabase.instance.database;

      // Get total ml_sold per product
      final salesData = await db.rawQuery('''
        SELECT product_id, product_name, SUM(ml_sold) as total_ml
        FROM sales
        GROUP BY product_id
        ORDER BY total_ml DESC
      ''');

      topSelling.assignAll(salesData);

      // Get unsold products (products that never appear in sales)
      final unsoldData = await db.rawQuery('''
        SELECT p.id, p.name, p.stock
        FROM products p
        LEFT JOIN sales s ON p.id = s.product_id
        WHERE s.id IS NULL
      ''');

      unsold.assignAll(unsoldData);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل التقارير');
    } finally {
      isLoading.value = false;
    }
  }
}
