import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/providers/local_database.dart';
import '../../core/theme/app_colors.dart';

class SecretsController extends GetxController {
  final isAuthenticated = false.obs;
  final formulas = <Map<String, dynamic>>[].obs;
  final passcode = "".obs;

  @override
  void onInit() {
    super.onInit();
    _loadPasscode();
  }

  Future<void> _loadPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    passcode.value = prefs.getString('secrets_passcode') ?? '1234'; // Default passcode is 1234
  }

  Future<void> changePasscode(String newCode) async {
    if (newCode.length < 4) {
      Get.snackbar('خطأ', 'رمز المرور يجب أن يكون 4 أرقام على الأقل');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secrets_passcode', newCode);
    passcode.value = newCode;
    Get.snackbar('نجاح', 'تم تغيير رمز المرور بنجاح');
  }

  void checkPasscode(String code) {
    if (code == passcode.value) {
      isAuthenticated.value = true;
      loadFormulas();
    } else {
      Get.snackbar('خطأ', 'رمز المرور غير صحيح!', backgroundColor: AppColors.error);
    }
  }

  Future<void> loadFormulas() async {
    if (!isAuthenticated.value) return;
    try {
      final db = await LocalDatabase.instance.database;
      final result = await db.query('formulas');
      formulas.assignAll(result);
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر تحميل الخلطات');
    }
  }

  Future<void> addFormula(String name, String recipe, String notes) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.insert('formulas', {
        'name': name,
        'recipe': recipe,
        'notes': notes,
      });
      loadFormulas();
      Get.snackbar('نجاح', 'تم حفظ الخلطة السرية بنجاح', backgroundColor: AppColors.success);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حفظ الخلطة');
    }
  }

  Future<void> deleteFormula(int id) async {
    try {
      final db = await LocalDatabase.instance.database;
      await db.delete('formulas', where: 'id = ?', whereArgs: [id]);
      loadFormulas();
      Get.snackbar('تم الحذف', 'تم حذف الخلطة بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حذف الخلطة');
    }
  }
}
