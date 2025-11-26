import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

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
      appBar: AppBar(title: const Text("Product & Service Management")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuCard(
            icon: Icons.local_offer,
            title: "Layanan Paket",
            onTap: () =>
                Navigator.pushNamed(context, '/settings/product/paket'),
          ),
          _menuCard(
            icon: Icons.cleaning_services,
            title: "Layanan Reguler",
            onTap: () =>
                Navigator.pushNamed(context, '/settings/product/service'),
          ),
          _menuCard(
            icon: Icons.discount,
            title: "Setup Promo",
            onTap: () =>
                Navigator.pushNamed(context, '/settings/product/promo'),
          ),
          _menuCard(
            icon: Icons.spa,
            title: "Setup Parfum",
            onTap: () =>
                Navigator.pushNamed(context, '/settings/product/parfum'),
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
