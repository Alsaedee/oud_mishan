import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'core/services/currency_service.dart';
import 'core/services/exchange_rate_service.dart';
import 'core/services/perfume_formula_service.dart';
import 'core/services/fragrance_search_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Get.putAsync(() => CurrencyService().init());
  await Get.putAsync(() => ExchangeRateService().init());
  await Get.putAsync(() => PerfumeFormulaService().init());
  Get.put(FragranceSearchService());

  // Initialize ScreenUtil for responsive UI
  runApp(const LuxuryPerfumeApp());
}

class LuxuryPerfumeApp extends StatelessWidget {
  const LuxuryPerfumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1024, 768), // POS Tablet baseline
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Luxury Perfume POS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Default to luxurious dark mode
          initialRoute: Routes.SPLASH,
          getPages: AppPages.routes,
          locale: const Locale('ar', 'SA'), // Default to Arabic RTL
          fallbackLocale: const Locale('en', 'US'),
        );
      },
    );
  }
}
