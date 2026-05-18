import 'package:get/get.dart';
import '../../data/providers/local_database.dart';

import '../../core/services/fragrance_search_service.dart';

class ProductsController extends GetxController {
  final products = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      final db = await LocalDatabase.instance.database;
      final result = await db.query('products');
      products.assignAll(result);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل المنتجات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(String name, String barcode, double price, double cost, int stock, String category) async {
    final db = await LocalDatabase.instance.database;
    
    // Call FragranceSearchService to fetch real fragrance notes from the internet
    final searchService = Get.find<FragranceSearchService>();
    final extractedNotes = await searchService.fetchRealPerfumeNotes(name);

    await db.insert('products', {
      'name': name,
      'barcode': barcode,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category': category,
      'notes': extractedNotes,
    });
    
    await loadProducts();
  }

  Future<void> updateProduct(int id, String name, String barcode, double price, double cost, double stock, String category, String notes) async {
    final db = await LocalDatabase.instance.database;
    await db.update('products', {
      'name': name,
      'barcode': barcode,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category': category,
      'notes': notes,
    }, where: 'id = ?', whereArgs: [id]);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    final db = await LocalDatabase.instance.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await loadProducts();
  }
}
