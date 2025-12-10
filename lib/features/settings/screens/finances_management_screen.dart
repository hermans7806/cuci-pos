import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';

class FinancesManagementScreen extends StatelessWidget {
  const FinancesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();

    /// Protect page: Owners only
    if (profile.role.value != 'owner') {
      Future.microtask(() {
        Get.offAllNamed('/dashboard');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Finances Management")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuCard(
            icon: Icons.wallet_giftcard_outlined,
            title: "Atur Cashbox",
            onTap: () =>
                Navigator.pushNamed(context, '/settings/finances/cashbox'),
          ),
          _menuCard(
            icon: Icons.category,
            title: "Atur Kategori",
            onTap: () =>
                Navigator.pushNamed(context, '/settings/finances/fin-category'),
          ),
          _menuCard(
            icon: Icons.account_balance_wallet,
            title: "Tambah Pendapatan",
            onTap: () =>
                Navigator.pushNamed(context, '/settings/finances/income'),
          ),
          _menuCard(
            icon: Icons.payment,
            title: "Tambah Pengeluaran",
            onTap: () =>
                Navigator.pushNamed(context, '/settings/finances/expense'),
          ),
          _menuCard(
            icon: Icons.monetization_on,
            title: "Koreksi Keuangan",
            onTap: () => Navigator.pushNamed(
              context,
              '/settings/finances/fin-correction',
            ),
          ),
          _menuCard(
            icon: Icons.wallet_travel,
            title: "Koreksi Pembayaran",
            onTap: () => Navigator.pushNamed(
              context,
              '/settings/finances/payment-correction',
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
