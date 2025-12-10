// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/orders/screens/create_order_screen.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/add_service_category_screen.dart';
import '../../features/settings/screens/branch_screen.dart';
import '../../features/settings/screens/cashbox_list_screen.dart';
import '../../features/settings/screens/fin_category_list_screen.dart';
import '../../features/settings/screens/finances_management_screen.dart';
import '../../features/settings/screens/income_add_screen.dart';
import '../../features/settings/screens/income_list_screen.dart';
import '../../features/settings/screens/my_customers_screen.dart';
import '../../features/settings/screens/package_screen.dart';
import '../../features/settings/screens/product_management_screen.dart';
import '../../features/settings/screens/promo_screen.dart';
import '../../features/settings/screens/role_screen.dart';
import '../../features/settings/screens/service_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/staff_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _page(const LoginScreen());

      case '/profile':
        return _page(ProfileScreen());

      case '/register':
        return _page(const RegisterScreen());

      case '/forgot-password':
        return _page(const ForgotPasswordScreen());

      case '/dashboard':
        return _page(DashboardScreen());

      // OWNER PROTECTED ROUTES
      case '/settings':
        return _protectedOwner(() => const SettingsScreen());

      case '/settings/role':
        return _protectedOwner(() => RoleScreen());

      case '/settings/branch':
        return _protectedOwner(() => BranchScreen());

      case '/settings/staff':
        return _protectedOwner(() => StaffScreen());

      case '/settings/product':
        return _protectedOwner(() => const ProductManagementScreen());

      case '/settings/product/paket':
        return _protectedOwner(() => PackageScreen());

      case '/settings/product/service':
        return _protectedOwner(() => ServiceScreen());

      case '/settings/product/service/add-service':
        return _protectedOwner(() => AddServiceCategoryScreen());

      case '/settings/product/promos':
        return _protectedOwner(() => PromoScreen());

      case '/settings/customers':
        return _protectedOwner(() => MyCustomersScreen());

      case '/settings/finances':
        return _protectedOwner(() => FinancesManagementScreen());

      case '/settings/finances/cashbox':
        return _protectedOwner(() => CashboxListScreen());

      case '/settings/finances/fin-category':
        return _protectedOwner(() => FinCategoryListScreen());

      case '/settings/finances/income':
        return _protectedOwner(() => IncomeListScreen());

      case '/settings/finances/income/add':
        return _protectedOwner(() => IncomeAddScreen());

      case '/create-order':
        return _protectedOwner(() => CreateOrderScreen());

      default:
        return _page(
          const Scaffold(body: Center(child: Text("Page not found"))),
        );
    }
  }

  static MaterialPageRoute _page(Widget page) =>
      MaterialPageRoute(builder: (_) => page);

  static MaterialPageRoute _protectedOwner(Widget Function() screenBuilder) {
    return MaterialPageRoute(
      builder: (_) {
        final profile = Get.find<ProfileController>();

        return Obx(() {
          final role = profile.role.value;

          if (role == "") {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (role != "owner") {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Get.currentRoute != '/dashboard') {
                Get.offAllNamed('/dashboard');
              }
            });
            return const Scaffold();
          }

          return screenBuilder();
        });
      },
    );
  }
}
