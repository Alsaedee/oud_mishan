import 'package:get/get.dart';
import '../../data/providers/local_database.dart';
import '../../core/services/fragrance_search_service.dart';

class PersonalityAnalysisController extends GetxController {
  final selectedNotes = <String>[].obs;
  final recommendedProducts = <Map<String, dynamic>>[].obs;
  final isAnalyzing = false.obs;
  final onlineAnalysisResult = "".obs;

  final availableNotes = [
    'برغموت', 'فلفل', 'لافندر', 'فيتيفير', 'باتشولي', 'امبروكسان',
    'أناناس', 'تفاح', 'ياسمين', 'مسك', 'فانيلا', 'عود', 'ورد',
    'زعفران', 'عنبر', 'صندل', 'جريب فروت', 'نعناع', 'ليمون',
    'برتقال', 'أرز', 'قرفة', 'جلود', 'هيل', 'تونكا', 'تبغ', 'زنجبيل'
  ];

  void toggleNote(String note) {
    if (selectedNotes.contains(note)) {
      selectedNotes.remove(note);
    } else {
      selectedNotes.add(note);
    }
  }

  Future<void> analyzePersonality() async {
    if (selectedNotes.isEmpty) {
      Get.snackbar('تنبيه', 'الرجاء اختيار بعض النوتات أولاً');
      return;
    }

    isAnalyzing.value = true;
    recommendedProducts.clear();
    onlineAnalysisResult.value = "";

    try {
      // 1. Fetch real psychological notes analysis from the internet
      final searchService = Get.find<FragranceSearchService>();
      final analysis = await searchService.fetchOnlinePersonalityAnalysis(selectedNotes);
      onlineAnalysisResult.value = analysis;

      // 2. Fetch matched products from local DB
      final db = await LocalDatabase.instance.database;
      final allProducts = await db.query('products');

      List<Map<String, dynamic>> matched = [];
      for (var product in allProducts) {
        String notes = product['notes']?.toString() ?? '';
        bool hasMatch = false;
        for (var selectedNote in selectedNotes) {
          if (notes.toLowerCase().contains(selectedNote.toLowerCase())) {
            hasMatch = true;
            break;
          }
        }
        if (hasMatch) {
          matched.add(product);
        }
      }

      recommendedProducts.assignAll(matched);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء استخراج العطور: $e');
    } finally {
      isAnalyzing.value = false;
    }
  }

  String getPersonalityDescription() {
    if (selectedNotes.isEmpty) return 'لم يتم تحديد الشخصية بعد.';
    
    // If online analysis fetched successfully, show it!
    if (onlineAnalysisResult.value.isNotEmpty) {
      return onlineAnalysisResult.value;
    }

    // Offline pleasant fallback
    int woodyCount = selectedNotes.where((n) => ['فيتيفير', 'باتشولي', 'عود', 'صندل', 'أرز'].contains(n)).length;
    int freshCount = selectedNotes.where((n) => ['برغموت', 'أناناس', 'تفاح', 'جريب فروت', 'نعناع', 'ليمون', 'برتقال'].contains(n)).length;
    int floralCount = selectedNotes.where((n) => ['لافندر', 'ياسمين', 'ورد'].contains(n)).length;
    int orientalCount = selectedNotes.where((n) => ['فلفل', 'امبروكسان', 'مسك', 'فانيلا', 'زعفران', 'عنبر', 'قرفة', 'جلود', 'هيل', 'تونكا', 'تبغ', 'زنجبيل'].contains(n)).length;

    int maxCount = [woodyCount, freshCount, floralCount, orientalCount].reduce((a, b) => a > b ? a : b);

    if (maxCount == 0) return 'شخصية متوازنة تحب التنوع والانفراد بمزيج عطري فريد.';
    if (maxCount == woodyCount) return 'شخصية قوية، قيادية، تعشق الفخامة والعمق وتحب فرض حضورها المهيب.';
    if (maxCount == freshCount) return 'شخصية نشيطة، متفائلة ومحبة للحياة، تمنح طاقة إيجابية فورية لمن حولها.';
    if (maxCount == floralCount) return 'شخصية رومانسية، رقيقة وشفافة، تميل للهدوء والمشاعر الجياشة المتزنة.';
    if (maxCount == orientalCount) return 'شخصية غامضة، جذابة ولها طابع ملكي ساحر يثير الفضول والاهتمام.';
    
    return 'شخصية فريدة ومميزة.';
  }
}
