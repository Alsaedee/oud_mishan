// ignore_for_file: constant_identifier_names
import 'package:get/get.dart';
import '../modules/splash/splash_view.dart';
import '../modules/login/login_view.dart';
import '../modules/dashboard/dashboard_view.dart';
import '../modules/pos/pos_view.dart';
import '../modules/ai_formula/ai_formula_view.dart';
import '../modules/personality_analysis/personality_analysis_view.dart';

import '../modules/settings/settings_view.dart';
import '../modules/products/products_view.dart';
import '../modules/customers/customers_view.dart';
import '../modules/reports/reports_view.dart';
import '../modules/financial/financial_view.dart';
import '../modules/secrets/secrets_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
    ),
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardView(),
    ),
    GetPage(
      name: Routes.POS,
      page: () => const POSView(),
    ),
    GetPage(
      name: Routes.AI_FORMULA,
      page: () => const AIFormulaView(),
    ),
    GetPage(
      name: Routes.PERSONALITY_ANALYSIS,
      page: () => const PersonalityAnalysisView(),
    ),
    GetPage(
      name: Routes.PRODUCTS,
      page: () => const ProductsView(),
    ),
    GetPage(
      name: Routes.CUSTOMERS,
      page: () => const CustomersView(),
    ),
    GetPage(
      name: Routes.REPORTS,
      page: () => const ReportsView(),
    ),
    GetPage(
      name: Routes.FINANCIAL,
      page: () => const FinancialView(),
    ),
    GetPage(
      name: Routes.SECRETS,
      page: () => const SecretsView(),
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => const SettingsView(),
    ),
  ];
}
