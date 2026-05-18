import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/exchange_rate_service.dart';
import 'products_controller.dart';
import 'dart:math';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductsController());
    
    return Scaffold(
      appBar: AppBar(title: const Text('العطور والمخزون')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('قائمة المنتجات', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(context, controller),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة عطر جديد'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                }
                if (controller.products.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات. أضف عطراً جديداً.', style: TextStyle(color: AppColors.grey, fontSize: 18)));
                }
                return ListView.builder(
                  itemCount: controller.products.length,
                  itemBuilder: (context, index) {
                    final product = controller.products[index];
                    return Card(
                      color: AppColors.darkGrey,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(product['name'], style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التصنيف: ${product['category']} | السعر: ${product['price']} ${Get.find<CurrencyService>().symbol} | المتوفر: ${product['stock']} مل', style: const TextStyle(color: AppColors.white)),
                            if (product['notes'] != null && product['notes'].toString().isNotEmpty)
                              Text('النوتات العطرية (AI): ${product['notes']}', style: const TextStyle(color: AppColors.lightGold, fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print, color: AppColors.success),
                              tooltip: 'طباعة الباركود',
                              onPressed: () => _printBarcode(product['name'], product['barcode']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.info),
                              tooltip: 'تعديل المنتج',
                              onPressed: () => _showEditProductDialog(context, controller, product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'حذف المنتج',
                              onPressed: () {
                                Get.defaultDialog(
                                  title: 'حذف المنتج',
                                  middleText: 'هل أنت متأكد من حذف عطر ${product['name']}؟',
                                  backgroundColor: AppColors.black,
                                  titleStyle: const TextStyle(color: AppColors.error),
                                  middleTextStyle: const TextStyle(color: AppColors.white),
                                  textConfirm: 'حذف',
                                  textCancel: 'إلغاء',
                                  confirmTextColor: AppColors.black,
                                  buttonColor: AppColors.error,
                                  cancelTextColor: AppColors.grey,
                                  onConfirm: () {
                                    controller.deleteProduct(product['id']);
                                    Get.back();
                                  }
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printBarcode(String name, String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    final double width = prefs.getDouble('barcodeWidth') ?? 50.0;
    final double height = prefs.getDouble('barcodeHeight') ?? 30.0;
    final double fontSize = prefs.getDouble('barcodeFontSize') ?? 10.0;
    final String alignment = prefs.getString('barcodeAlignment') ?? 'Center';

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width * PdfPageFormat.mm, height * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm),
        build: (pw.Context context) {
          final align = alignment == 'Center' 
              ? pw.Alignment.center 
              : alignment == 'Left' 
                  ? pw.Alignment.centerLeft 
                  : pw.Alignment.centerRight;
          return pw.Container(
            alignment: align,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: barcode,
                  width: width * PdfPageFormat.mm * 0.8,
                  height: height * PdfPageFormat.mm * 0.4,
                  drawText: true,
                  textStyle: pw.TextStyle(fontSize: fontSize * 0.8),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  void _showAddProductDialog(BuildContext context, ProductsController controller) {
    final nameCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'عطور');

    final exchangeService = Get.find<ExchangeRateService>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final costUsd = double.tryParse(costCtrl.text) ?? 0.0;
          final totalMl = double.tryParse(stockCtrl.text) ?? 0.0;

          final costIqd = costUsd * exchangeService.usdToIqd.value;
          final costPerMl = totalMl > 0 ? costIqd / totalMl : 0.0;

          return AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text('إضافة عطر جديد', style: TextStyle(color: AppColors.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameCtrl, 'اسم العطر'),
                  
                  // Barcode with Gen & Print buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(barcodeCtrl, 'الباركود'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.autorenew, color: AppColors.gold),
                        tooltip: 'توليد باركود تلقائي',
                        onPressed: () {
                          final random = Random();
                          final newBarcode = List.generate(12, (_) => random.nextInt(10)).join();
                          barcodeCtrl.text = newBarcode;
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.print, color: AppColors.success),
                        tooltip: 'طباعة الباركود',
                        onPressed: () {
                          if (barcodeCtrl.text.isNotEmpty) {
                            _printBarcode(nameCtrl.text.isEmpty ? 'عطر جديد' : nameCtrl.text, barcodeCtrl.text);
                          } else {
                            Get.snackbar('خطأ', 'يرجى إدخال أو توليد باركود أولاً');
                          }
                        },
                      ),
                    ],
                  ),
                  
                  _buildTextField(
                    costCtrl, 
                    'سعر التكلفة بالدولار (\$)', 
                    isNumber: true,
                    onChanged: (_) {
                      final usd = double.tryParse(costCtrl.text) ?? 0.0;
                      final ml = double.tryParse(stockCtrl.text) ?? 0.0;
                      if (ml > 0) {
                        final iqd = usd * exchangeService.usdToIqd.value;
                        final perMl = iqd / ml;
                        final rounded = (perMl * 2.0 / 50.0).roundToDouble() * 50.0;
                        priceCtrl.text = rounded.toStringAsFixed(0);
                      }
                      setState(() {});
                    },
                  ),
                  
                  _buildTextField(
                    stockCtrl, 
                    'الحجم الإجمالي بالمليلتر (مل)', 
                    isNumber: true,
                    onChanged: (_) {
                      final usd = double.tryParse(costCtrl.text) ?? 0.0;
                      final ml = double.tryParse(stockCtrl.text) ?? 0.0;
                      if (ml > 0) {
                        final iqd = usd * exchangeService.usdToIqd.value;
                        final perMl = iqd / ml;
                        final rounded = (perMl * 2.0 / 50.0).roundToDouble() * 50.0;
                        priceCtrl.text = rounded.toStringAsFixed(0);
                      }
                      setState(() {});
                    },
                  ),

                  _buildTextField(priceCtrl, 'سعر البيع المقترح لـ 1 مل', isNumber: true),

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

                  _buildTextField(categoryCtrl, 'التصنيف'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('إلغاء', style: TextStyle(color: AppColors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;
                  final cost = double.tryParse(costCtrl.text) ?? 0.0;
                  final stock = int.tryParse(stockCtrl.text) ?? 0;
                  
                  if (nameCtrl.text.isNotEmpty) {
                    // Show extracting dialog
                    Get.back();
                    Get.dialog(
                      const AlertDialog(
                        backgroundColor: AppColors.black,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.gold),
                            SizedBox(height: 16),
                            Text('يتم الآن استخراج النوتات العطرية بالذكاء الاصطناعي...', style: TextStyle(color: AppColors.gold)),
                          ],
                        ),
                      ),
                      barrierDismissible: false,
                    );
                    
                    Future.delayed(const Duration(seconds: 2), () {
                      controller.addProduct(nameCtrl.text, barcodeCtrl.text, price, cost, stock, categoryCtrl.text);
                      Get.back(); // close extracting dialog
                      Get.snackbar('نجاح', 'تم إضافة العطر واستخراج النوتات بنجاح', backgroundColor: AppColors.success, colorText: AppColors.black);
                    });
                  }
                },
                child: const Text('حفظ واستخراج النوتات'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, ProductsController controller, Map<String, dynamic> product) {
    final nameCtrl = TextEditingController(text: product['name']);
    final barcodeCtrl = TextEditingController(text: product['barcode']);
    final costCtrl = TextEditingController(text: (product['cost'] as num).toString());
    final stockCtrl = TextEditingController(text: (product['stock'] as num).toString());
    final priceCtrl = TextEditingController(text: (product['price'] as num).toStringAsFixed(0));
    final categoryCtrl = TextEditingController(text: product['category']);
    final notesCtrl = TextEditingController(text: product['notes'] ?? '');

    final exchangeService = Get.find<ExchangeRateService>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final costUsd = double.tryParse(costCtrl.text) ?? 0.0;
          final totalMl = double.tryParse(stockCtrl.text) ?? 0.0;

          final costIqd = costUsd * exchangeService.usdToIqd.value;
          final costPerMl = totalMl > 0 ? costIqd / totalMl : 0.0;

          return AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text('تعديل بيانات العطر', style: TextStyle(color: AppColors.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameCtrl, 'اسم العطر'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(barcodeCtrl, 'الباركود'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.autorenew, color: AppColors.gold),
                        tooltip: 'توليد باركود تلقائي',
                        onPressed: () {
                          final random = Random();
                          final newBarcode = List.generate(12, (_) => random.nextInt(10)).join();
                          barcodeCtrl.text = newBarcode;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  _buildTextField(
                    costCtrl, 
                    'سعر التكلفة بالدولار (\$)', 
                    isNumber: true,
                    onChanged: (_) {
                      final usd = double.tryParse(costCtrl.text) ?? 0.0;
                      final ml = double.tryParse(stockCtrl.text) ?? 0.0;
                      if (ml > 0) {
                        final iqd = usd * exchangeService.usdToIqd.value;
                        final perMl = iqd / ml;
                        final rounded = (perMl * 2.0 / 50.0).roundToDouble() * 50.0;
                        priceCtrl.text = rounded.toStringAsFixed(0);
                      }
                      setState(() {});
                    },
                  ),
                  _buildTextField(
                    stockCtrl, 
                    'الحجم الإجمالي بالمليلتر (مل)', 
                    isNumber: true,
                    onChanged: (_) {
                      final usd = double.tryParse(costCtrl.text) ?? 0.0;
                      final ml = double.tryParse(stockCtrl.text) ?? 0.0;
                      if (ml > 0) {
                        final iqd = usd * exchangeService.usdToIqd.value;
                        final perMl = iqd / ml;
                        final rounded = (perMl * 2.0 / 50.0).roundToDouble() * 50.0;
                        priceCtrl.text = rounded.toStringAsFixed(0);
                      }
                      setState(() {});
                    },
                  ),
                  _buildTextField(priceCtrl, 'سعر البيع المقترح لـ 1 مل', isNumber: true),
                  
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
                  _buildTextField(categoryCtrl, 'التصنيف'),
                  _buildTextField(notesCtrl, 'النوتات العطرية (AI)'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('إلغاء', style: TextStyle(color: AppColors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;
                  final cost = double.tryParse(costCtrl.text) ?? 0.0;
                  final stock = double.tryParse(stockCtrl.text) ?? 0.0;
                  
                  if (nameCtrl.text.isNotEmpty) {
                    controller.updateProduct(
                      product['id'], 
                      nameCtrl.text, 
                      barcodeCtrl.text, 
                      price, 
                      cost, 
                      stock, 
                      categoryCtrl.text, 
                      notesCtrl.text
                    );
                    Get.back();
                    Get.snackbar('نجاح', 'تم تحديث بيانات العطر بنجاح', backgroundColor: AppColors.success, colorText: AppColors.black);
                  }
                },
                child: const Text('حفظ التعديلات'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
}
