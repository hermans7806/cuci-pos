import 'package:shared_preferences/shared_preferences.dart';

class SharedReference {
  static const String keyActiveBranchId = 'activeBranchId';

  static Future<String> getActiveBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyActiveBranchId) ?? '';
  }

  static Future<void> setActiveBranchId(String branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyActiveBranchId, branchId);
  }
}
