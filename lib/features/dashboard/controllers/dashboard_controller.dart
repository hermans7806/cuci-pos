import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardController extends GetxController {
  final stats = <String, int>{}.obs;

  final isLoading = true.obs;

  late String branchId;

  @override
  void onInit() async {
    super.onInit();
    await _loadBranch();
    await loadStats();
    listenRealtime();
  }

  Future<void> _loadBranch() async {
    final prefs = await SharedPreferences.getInstance();
    branchId = prefs.getString("activeBranchId") ?? "";
  }

  // ----------------------------
  // LOAD FROM CACHE / FIRESTORE
  // ----------------------------
  Future<void> loadStats() async {
    isLoading.value = true;

    final doc = await FirebaseFirestore.instance
        .collection("dashboard_stats")
        .doc(branchId)
        .get();

    if (doc.exists) {
      final raw = doc.data()!;

      final safeMap = <String, int>{};

      raw.forEach((key, value) {
        if (value is int) {
          safeMap[key] = value;
        } else if (value is num) {
          safeMap[key] = value.toInt();
        } else {
          safeMap[key] = 0;
        }
      });

      stats.value = safeMap;
    }

    isLoading.value = false;
  }

  // ----------------------------
  // REALTIME LISTENER (LIGHT)
  // ----------------------------
  void listenRealtime() {
    FirebaseFirestore.instance
        .collection("orders")
        .where("branchId", isEqualTo: branchId)
        .snapshots()
        .listen((snapshot) {
          final map = <String, int>{};

          for (var d in snapshot.docs) {
            final status =
                (d.data() as Map<String, dynamic>)["dashboardStatus"] ??
                "pending";
            map[status] = (map[status] ?? 0) + 1;
          }

          stats.value = map;
        });
  }

  // ----------------------------
  // GETTERS (UI READY)
  // ----------------------------
  int get konfirmasi => stats["konfirmasi"] ?? 0;
  int get penjemputan => stats["penjemputan"] ?? 0;
  int get antrian => stats["antrian"] ?? 0;
  int get proses => stats["proses"] ?? 0;
  int get siapAmbil => stats["siap_ambil"] ?? 0;
  int get siapAntar => stats["pengantaran"] ?? 0;

  int get todayOrders => stats["todayOrders"] ?? 0;
  int get dueToday => stats["dueToday"] ?? 0;
  int get late => stats["late"] ?? 0;
}
