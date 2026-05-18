import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

import '../../data/providers/local_database.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/exchange_rate_service.dart';
import '../../core/services/perfume_formula_service.dart';
import '../../core/services/fragrance_search_service.dart';

class POSController extends GetxController {
  final cart = <Map<String, dynamic>>[].obs;
  final subtotal = 0.0.obs;
  final discount = 0.0.obs;
  
  final products = <Map<String, dynamic>>[].obs;
  final searchController = TextEditingController();

  double get total => subtotal.value - discount.value;

  @override
  void onInit() {
    super.onInit();
    HardwareKeyboard.instance.addHandler(_handleKey);
    loadProducts();
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.onClose();
  }

  Future<void> loadProducts() async {
    try {
      final db = await LocalDatabase.instance.database;
      final result = await db.query('products');
      products.assignAll(result);
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر تحميل المنتجات');
    }
  }

  Future<void> searchProduct(String query) async {
    if (query.isEmpty) {
      loadProducts();
      return;
    }

    final db = await LocalDatabase.instance.database;
    final result = await db.query('products');
    
    final matched = result.where((p) {
      final name = p['name'].toString().toLowerCase();
      final barcode = p['barcode'].toString().toLowerCase();
      final q = query.toLowerCase();
      return name.contains(q) || barcode.contains(q);
    }).toList();
    
    products.assignAll(matched);
  }

  Future<void> onSearchSubmitted(String query) async {
    if (query.isEmpty) return;

    final db = await LocalDatabase.instance.database;
    final result = await db.query('products', where: 'barcode = ?', whereArgs: [query]);

    if (result.isNotEmpty) {
      addToCart(result.first);
      searchController.clear();
      loadProducts();
    } else {
      _showProductNotFoundDialog(query);
    }
  }

  void _showProductNotFoundDialog(String barcode) {
    Get.defaultDialog(
      title: 'المنتج غير موجود',
      middleText: 'الباركود ($barcode) غير مسجل في قاعدة البيانات. هل تود إضافته الآن؟',
      backgroundColor: AppColors.black,
      titleStyle: const TextStyle(color: AppColors.warning),
      middleTextStyle: const TextStyle(color: AppColors.white),
      textConfirm: 'إضافة منتج فوراً',
      textCancel: 'إلغاء',
      confirmTextColor: AppColors.black,
      buttonColor: AppColors.gold,
      cancelTextColor: AppColors.grey,
      onConfirm: () {
        Get.back(); // close confirm dialog
        _showDirectAddProductDialog(barcode);
      }
    );
  }

  void _showDirectAddProductDialog(String barcode) {
    final nameCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController(text: barcode);
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'عطور');

    final exchangeService = Get.find<ExchangeRateService>();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          final costUsd = double.tryParse(costCtrl.text) ?? 0.0;
          final totalMl = double.tryParse(stockCtrl.text) ?? 0.0;

          final costIqd = costUsd * exchangeService.usdToIqd.value;
          final costPerMl = totalMl > 0 ? costIqd / totalMl : 0.0;

          return AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text('إضافة عطر جديد سريع', style: TextStyle(color: AppColors.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAddDialogField(nameCtrl, 'اسم العطر'),
                  _buildAddDialogField(barcodeCtrl, 'الباركود'),
                  _buildAddDialogField(priceCtrl, 'سعر البيع المقترح لـ 1 مل', isNumber: true),
                  
                  _buildAddDialogField(
                    costCtrl, 
                    'سعر التكلفة بالدولار (\$)', 
                    isNumber: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  
                  _buildAddDialogField(
                    stockCtrl, 
                    'الحجم الإجمالي بالمليلتر (مل)', 
                    isNumber: true,
                    onChanged: (_) => setState(() {}),
                  ),

                  // Dynamic Calculations Display
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.deepBlack,
                      border: Border.all(color: AppColors.darkGrey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('التكلفة بالدينار العراقي:', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                            Text('${costIqd.toStringAsFixed(0)} د.ع', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('تكلفة المليلتر الواحد (1 مل):', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                            Text('${costPerMl.toStringAsFixed(1)} د.ع / مل', style: const TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildAddDialogField(categoryCtrl, 'التصنيف'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('إلغاء', style: TextStyle(color: AppColors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;
                  final cost = double.tryParse(costCtrl.text) ?? 0.0;
                  final stock = int.tryParse(stockCtrl.text) ?? 0;
                  
                  if (nameCtrl.text.isNotEmpty) {
                    Get.back(); // Close add dialog
                    
                    try {
                      final db = await LocalDatabase.instance.database;
                      final searchService = Get.find<FragranceSearchService>();
                      final extractedNotes = await searchService.fetchRealPerfumeNotes(nameCtrl.text);

                      await db.insert('products', {
                        'name': nameCtrl.text,
                        'barcode': barcodeCtrl.text,
                        'price': price,
                        'cost': cost,
                        'stock': stock,
                        'category': categoryCtrl.text,
                        'notes': extractedNotes,
                      });
                      
                      await loadProducts();
                      
                      // Auto add to cart!
                      final newProduct = products.firstWhereOrNull((p) => p['barcode'] == barcodeCtrl.text);
                      if (newProduct != null) {
                        addToCart(newProduct);
                      }
                      
                      Get.snackbar('نجاح', 'تم إضافة المنتج وإدراجه للبيع بنجاح', backgroundColor: AppColors.success);
                    } catch (e) {
                      Get.snackbar('خطأ', 'فشل إضافة المنتج');
                    }
                  }
                },
                child: const Text('حفظ وإدراج في السلة'),
              ),
            ],
          );
        }
      )
    );
  }

  Widget _buildAddDialogField(TextEditingController controller, String label, {bool isNumber = false, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppColors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grey),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.darkGrey)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
        ),
      ),
    );
  }

  String _scannerBuffer = "";
  DateTime? _lastKeyEventTime;

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final primaryFocus = FocusManager.instance.primaryFocus;
      final now = DateTime.now();
      final keyLabel = event.logicalKey.keyLabel;
      
      // Wedge scanner pattern: fast sequence of characters
      if (keyLabel.length == 1 && RegExp(r'[0-9a-zA-Z]').hasMatch(keyLabel)) {
        if (_lastKeyEventTime == null || now.difference(_lastKeyEventTime!) < const Duration(milliseconds: 85)) {
          _scannerBuffer += keyLabel;
        } else {
          _scannerBuffer = keyLabel;
        }
        _lastKeyEventTime = now;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_scannerBuffer.isNotEmpty && _scannerBuffer.length >= 4) {
          final barcode = _scannerBuffer;
          _scannerBuffer = "";
          onSearchSubmitted(barcode);
          return true;
        }
        _scannerBuffer = "";

        if (primaryFocus == null || primaryFocus.context?.widget is! EditableText) {
          checkout('نقدي', printReceipt: true);
          return true; 
        }
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        if (primaryFocus == null || primaryFocus.context?.widget is! EditableText) {
          checkout('نقدي', printReceipt: false);
          return true; 
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        cancelSale();
        return true; 
      }
    }
    return false;
  }

  void addToCart(Map<String, dynamic> product) {
    final formulaService = Get.find<PerfumeFormulaService>();

    Get.defaultDialog(
      title: 'خيارات التعبئة والكمية - ${product['name']}',
      backgroundColor: AppColors.black,
      titleStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
      content: SizedBox(
        width: 450,
        child: Column(
          children: [
            const Text(
              'اختر السعة (سيتم احتساب السعر وخصم الزيت العطري تلقائياً):',
              style: TextStyle(color: AppColors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: formulaService.presets.map((preset) {
                final calculatedPrice = preset.defaultSalePrice;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGrey,
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold, width: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    final item = Map<String, dynamic>.from(product);
                    item['perfume_ml'] = preset.oilMl;
                    item['alcohol_ml'] = preset.alcoholMl;
                    item['capacity_name'] = preset.name;
                    item['price'] = calculatedPrice;
                    cart.add(item);
                    _calculateTotals();
                    Get.back();
                    Get.snackbar(
                      'تمت الإضافة', 
                      'تم إضافة ${product['name']} سعة ${preset.name} بسعر ${calculatedPrice.toStringAsFixed(0)}',
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 1),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${calculatedPrice.toStringAsFixed(0)} د.ع', style: const TextStyle(color: AppColors.white, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 16),
            const Divider(color: AppColors.darkGrey),
            const SizedBox(height: 8),
            // Custom ML input fallback
            ElevatedButton.icon(
              icon: const Icon(Icons.tune),
              label: const Text('تعبئة مخصصة (يدوي)'),
              onPressed: () {
                Get.back();
                _showCustomBlendingDialog(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomBlendingDialog(Map<String, dynamic> product) {
    final perfumeCtrl = TextEditingController(text: '30');
    final alcoholCtrl = TextEditingController(text: '20');
    final priceCtrl = TextEditingController(text: product['price'].toString());

    Get.defaultDialog(
      title: 'تعبئة مخصصة - ${product['name']}',
      backgroundColor: AppColors.black,
      titleStyle: const TextStyle(color: AppColors.gold),
      content: Column(
        children: [
          TextField(
            controller: perfumeCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(labelText: 'كمية الزيت العطري (مل)', labelStyle: TextStyle(color: AppColors.grey)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: alcoholCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(labelText: 'كمية الكحول (مل)', labelStyle: TextStyle(color: AppColors.grey)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(labelText: 'السعر الكلي للخلطة', labelStyle: TextStyle(color: AppColors.grey)),
          ),
        ],
      ),
      textConfirm: 'إضافة للسلة',
      textCancel: 'إلغاء',
      buttonColor: AppColors.gold,
      confirmTextColor: AppColors.black,
      cancelTextColor: AppColors.grey,
      onConfirm: () {
        final double pMl = double.tryParse(perfumeCtrl.text) ?? 30.0;
        final double aMl = double.tryParse(alcoholCtrl.text) ?? 20.0;
        final double price = double.tryParse(priceCtrl.text) ?? (product['price'] as num).toDouble();
        
        final item = Map<String, dynamic>.from(product);
        item['perfume_ml'] = pMl;
        item['alcohol_ml'] = aMl;
        item['capacity_name'] = 'مخصص';
        item['price'] = price;
        cart.add(item);
        _calculateTotals();
        Get.back();
      }
    );
  }

  void _calculateTotals() {
    subtotal.value = cart.fold(0, (sum, item) => sum + (item['price'] as double));
  }

  void applyDiscount(String value) {
    discount.value = double.tryParse(value) ?? 0.0;
  }

  void cancelSale() {
    if (cart.isEmpty) return;
    cart.clear();
    discount.value = 0.0;
    _calculateTotals();
    Get.snackbar(
      'إلغاء البيع',
      'تم إلغاء عملية البيع وتفريغ السلة',
      backgroundColor: AppColors.warning,
      colorText: AppColors.black,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> checkout(String paymentMethod, {bool printReceipt = false}) async {
    if (cart.isEmpty) {
      Get.snackbar('تنبيه', 'سلة المبيعات فارغة', backgroundColor: AppColors.warning);
      return;
    }
    
    final db = await LocalDatabase.instance.database;

    // Deduct stock
    for (var item in cart) {
      final double usedMl = item['perfume_ml'] ?? 0.0;
      final int id = item['id'];
      
      // Get current stock
      final res = await db.query('products', where: 'id = ?', whereArgs: [id]);
      if (res.isNotEmpty) {
        double currentStock = (res.first['stock'] as num).toDouble();
        double newStock = currentStock - usedMl;
        if (newStock < 0) newStock = 0;
        
        await db.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [id]);

        if (newStock < 50) { // Alert if stock is less than 50 ml
          Get.snackbar('تنبيه مخزون', 'الزيت العطري ${item['name']} قارب على النفاذ ($newStock مل فقط)', backgroundColor: AppColors.warning, colorText: AppColors.black, duration: const Duration(seconds: 4));
        }
      }

      // Track Sale (we will create a sales table)
      try {
        await db.insert('sales', {
          'product_id': id,
          'product_name': item['name'],
          'ml_sold': usedMl,
          'price': item['price'],
          'date': DateTime.now().toIso8601String()
        });
      } catch (e) {
        // Sales table might not exist yet
      }
    }

    String message = 'تمت عملية البيع بنجاح عبر: $paymentMethod\nالإجمالي: $total';
    if (printReceipt) {
      message += '\nجاري طباعة الفاتورة...';
    }

    Get.snackbar(
      'اكتملت العملية',
      message,
      backgroundColor: AppColors.success,
      colorText: AppColors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
    
    cart.clear();
    discount.value = 0.0;
    _calculateTotals();
    loadProducts(); // reload to reflect new stock
  }

  Future<void> generateBarcode() async {
    final rnd = Random();
    String newBarcode = '';
    for (var i = 0; i < 12; i++) {
      newBarcode += rnd.nextInt(10).toString();
    }

    Get.defaultDialog(
      title: 'إنشاء وطباعة باركود',
      backgroundColor: AppColors.black,
      titleStyle: const TextStyle(color: AppColors.gold),
      content: Column(
        children: [
          const Icon(Icons.qr_code_2, size: 100, color: AppColors.white),
          const SizedBox(height: 16),
          Text(newBarcode, style: const TextStyle(color: AppColors.gold, fontSize: 24, letterSpacing: 4)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              await _printBarcode(newBarcode);
            },
            icon: const Icon(Icons.print),
            label: const Text('طباعة الباركود'),
          )
        ],
      ),
    );
  }

  Future<void> _printBarcode(String barcodeData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Settings
    final double bWidth = prefs.getDouble('barcodeWidth') ?? 50.0;
    final double bHeight = prefs.getDouble('barcodeHeight') ?? 30.0;
    final double fSize = prefs.getDouble('barcodeFontSize') ?? 10.0;
    final String align = prefs.getString('barcodeAlignment') ?? 'Center';
    final String shopName = prefs.getString('shopName') ?? 'Luxury Perfume POS';

    // Convert mm to points (1 mm = 2.83465 points)
    final double widthPt = bWidth * 2.83465;
    final double heightPt = bHeight * 2.83465;

    final pdf = pw.Document();

    pw.MainAxisAlignment alignment;
    if (align == 'Left') {
      alignment = pw.MainAxisAlignment.start;
    } else if (align == 'Right') {
      alignment = pw.MainAxisAlignment.end;
    } else {
      alignment = pw.MainAxisAlignment.center;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(widthPt, heightPt, marginAll: 2 * 2.83465), // 2mm margin
        build: (pw.Context context) {
          return pw.Container(
            width: widthPt,
            height: heightPt,
            child: pw.Column(
              mainAxisAlignment: alignment,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.BarcodeWidget(
                    data: barcodeData,
                    barcode: pw.Barcode.code128(),
                    drawText: true,
                    textStyle: pw.TextStyle(fontSize: fSize),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(shopName, style: pw.TextStyle(fontSize: fSize * 0.8), maxLines: 1),
              ],
            ),
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Barcode_$barcodeData',
      );
      Get.snackbar('نجاح', 'تم إرسال أمر الطباعة', backgroundColor: AppColors.success);
    } catch (e) {
      Get.snackbar('خطأ', 'فشلت عملية الطباعة: $e', backgroundColor: AppColors.error);
    }
  }
}

class POSView extends GetView<POSController> {
  const POSView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(POSController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الكاشير - POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: controller.generateBarcode,
            tooltip: 'إنشاء وطباعة باركود',
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: () {
              Get.defaultDialog(
                title: 'اختصارات لوحة المفاتيح',
                backgroundColor: AppColors.black,
                titleStyle: const TextStyle(color: AppColors.gold),
                content: const Column(
                  children: [
                    ListTile(title: Text('إتمام البيع + طباعة', style: TextStyle(color: AppColors.white)), trailing: Text('Enter', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
                    ListTile(title: Text('إتمام البيع فقط', style: TextStyle(color: AppColors.white)), trailing: Text('Space', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
                    ListTile(title: Text('إلغاء البيع', style: TextStyle(color: AppColors.white)), trailing: Text('Esc', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            },
            tooltip: 'اختصارات الكيبورد',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner), 
            onPressed: () {
              Get.snackbar('مسح الباركود', 'يرجى توجيه قارئ الباركود (السكانر) الآن', backgroundColor: AppColors.info);
            },
            tooltip: 'مسح باركود',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side: Products Grid
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: controller.searchController,
                    onChanged: controller.searchProduct,
                    onSubmitted: controller.onSearchSubmitted,
                    decoration: const InputDecoration(
                      hintText: 'البحث عن عطر أو مسح الباركود...',
                      prefixIcon: Icon(Icons.search, color: AppColors.gold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() {
                      if (controller.products.isEmpty) {
                        return const Center(child: Text('لا توجد منتجات مطابقة', style: TextStyle(color: AppColors.grey)));
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: controller.products.length,
                        itemBuilder: (context, index) {
                          final p = controller.products[index];
                          return _productCard(context, p);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          // Right side: Cart & Checkout Panel
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.deepBlack,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.black,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سلة المبيعات', style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.delete, color: AppColors.error), onPressed: controller.cancelSale),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() => ListView.builder(
                          itemCount: controller.cart.length,
                          itemBuilder: (context, index) {
                            final item = controller.cart[index];
                            return ListTile(
                              title: Text('${item['name']} (${item['capacity_name'] ?? ''})', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('زيت: ${item['perfume_ml']}مل | كحول: ${item['alcohol_ml']}مل', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      final priceCtrl = TextEditingController(text: (item['price'] as num).toStringAsFixed(0));
                                      Get.defaultDialog(
                                        title: 'تعديل السعر النهائي للزبون',
                                        backgroundColor: AppColors.black,
                                        titleStyle: const TextStyle(color: AppColors.gold),
                                        content: TextField(
                                          controller: priceCtrl,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(color: AppColors.white),
                                          decoration: const InputDecoration(
                                            labelText: 'السعر النهائي',
                                            labelStyle: TextStyle(color: AppColors.grey),
                                          ),
                                        ),
                                        textConfirm: 'حفظ وتحديث',
                                        textCancel: 'إلغاء',
                                        buttonColor: AppColors.gold,
                                        confirmTextColor: AppColors.black,
                                        cancelTextColor: AppColors.grey,
                                        onConfirm: () {
                                          final newPrice = double.tryParse(priceCtrl.text) ?? (item['price'] as num).toDouble();
                                          controller.cart[index]['price'] = newPrice;
                                          controller.cart.refresh();
                                          controller._calculateTotals();
                                          Get.back();
                                        }
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.gold, width: 0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${(item['price'] as num).toStringAsFixed(0)} ${Get.find<CurrencyService>().symbol}',
                                        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                                    onPressed: () {
                                      controller.cart.removeAt(index);
                                      controller._calculateTotals();
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                        )),
                  ),
                  _buildCheckoutPanel(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, Map<String, dynamic> product) {
    return InkWell(
      onTap: () => controller.addToCart(product),
      child: Card(
        color: AppColors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Icon(Icons.water_drop, size: 64, color: AppColors.gold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(product['name'], style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${product['price']}', style: const TextStyle(color: AppColors.gold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(top: BorderSide(color: AppColors.gold, width: 2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 1, child: Text('الخصم:', style: TextStyle(color: AppColors.white))),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: '0.0',
                    ),
                    onChanged: controller.applyDiscount,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي المطلوب:', style: TextStyle(color: AppColors.white, fontSize: 18)),
              Obx(() => Text('${controller.total}', style: const TextStyle(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('طريقة الدفع (إتمام البيع)', style: TextStyle(color: AppColors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _paymentButton('نقدي', Icons.money, AppColors.success, () => controller.checkout('نقدي', printReceipt: true)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _paymentButton('بطاقة', Icons.credit_card, AppColors.info, () => controller.checkout('بطاقة', printReceipt: true)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _paymentButton('آجل', Icons.handshake, AppColors.warning, () => controller.checkout('آجل', printReceipt: true)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppColors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
