import 'package:shared_preferences/shared_preferences.dart';

class SharedReference {
  static const String keyActiveBranchId = 'activeBranchId';
  static const String keyIsOwner = 'isOwner';

  static Future<String> getActiveBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyActiveBranchId) ?? '';
  }

  static Future<void> setActiveBranchId(String branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyActiveBranchId, branchId);
  }

  static Future<bool> getIsOwner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsOwner) ?? false;
  }

  static Future<void> setIsOwner(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsOwner, v);
  }
}
