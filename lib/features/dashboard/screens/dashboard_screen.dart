import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final ProfileController profileCtrl = Get.find<ProfileController>();
  int _currentIndex = 0;
  String selectedTab = 'Transaksi'; // or 'Keuangan'

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58), // smaller height
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Image.asset('lib/assets/fast_clean4-02.png', height: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() {
                        return Text(
                          'Hai, ${profileCtrl.nickname.value}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }),

                      const Text(
                        'Selamat datang kembali di Fastclean Medit',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  if (profileCtrl.role.value == 'owner') {
                    return IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        ),
      ),

      // MAIN BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Blue box with tabs
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton('Keuangan'),
                      const SizedBox(width: 16),
                      _buildTabButton('Transaksi'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Animated tab content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: selectedTab == 'Keuangan'
                        ? _buildKeuanganTab()
                        : _buildTransaksiTab(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Transaction status icons (2 rows × 3 columns)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuIcon(Icons.check_circle, 'Konfirmasi', '0'),
                _buildMenuIcon(Icons.location_pin, 'Penjemputan', '0'),
                _buildMenuIcon(Icons.list_alt, 'Antrian', '21'),
                _buildMenuIcon(Icons.local_laundry_service, 'Proses', '22'),
                _buildMenuIcon(Icons.shopping_basket, 'Siap Ambil', '95'),
                _buildMenuIcon(Icons.local_shipping, 'Siap Antar', '0'),
              ],
            ),

            const SizedBox(height: 32),

            // 🔹 Shortcuts
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pintasan',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildShortcutTile(
              'Top Pelanggan',
              'Pelanggan dengan transaksi terbanyak',
            ),
            _buildShortcutTile('Top Layanan', 'Layanan paling sering dipesan'),
          ],
        ),
      ),

      // Floating button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        onPressed: () {
          Navigator.pushNamed(context, '/create-order');
        },
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);

          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/dashboard'); // Beranda
              break;

            case 2:
              Navigator.pushNamed(context, '/create-order');
              break;

            case 4:
              Navigator.pushNamed(context, '/profile'); // 🧩 Settings page
              break;
          }
        },
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Pesanan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────
  // 🔹 Subcomponents
  // ───────────────────────────────

  Widget _buildTabButton(String title) {
    final isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade700 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildKeuanganTab() {
    return Row(
      key: const ValueKey('Keuangan'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(Icons.attach_money, 'Pendapatan', 'Rp 2.350.000'),
        _buildStatItem(Icons.pie_chart, 'Omset', 'Rp 4.120.000'),
      ],
    );
  }

  Widget _buildTransaksiTab() {
    return Row(
      key: const ValueKey('Transaksi'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(Icons.download, 'Masuk', '0'),
        _buildStatItem(Icons.push_pin, 'Harus Selesai', '17'),
        _buildStatItem(Icons.access_time, 'Terlambat', '3'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, String count) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade50,
              child: Icon(icon, color: Colors.blue.shade600, size: 28),
            ),
            if (count != '0')
              Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.orange,
                  child: Text(
                    count,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildShortcutTile(String title, String subtitle) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: () {},
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
