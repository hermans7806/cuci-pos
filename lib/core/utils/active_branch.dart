import 'package:shared_preferences/shared_preferences.dart';

class BranchUtils {
  static Future<String?> getActiveBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeBranchId');
  }

  static Future<String?> getActiveBranchName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeBranchName');
  }
}
