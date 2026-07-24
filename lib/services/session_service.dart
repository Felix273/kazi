import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class SessionService {
  const SessionService._();

  static Future<void> save(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(AppConstants.prefIsLoggedIn, true),
      prefs.setString(AppConstants.prefUserRole, role),
    ]);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(AppConstants.prefIsLoggedIn, false),
      prefs.remove(AppConstants.prefUserRole),
    ]);
  }

  static Future<String?> get role async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefUserRole);
  }

  static String homeForRole(String role) {
    return role == AppConstants.roleEmployer
        ? '/employer/home'
        : '/jobseeker/home';
  }
}
