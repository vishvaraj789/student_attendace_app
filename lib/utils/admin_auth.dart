import 'shared_preference.dart';

/// The single admin account for this device.
/// First run uses the default login below; the admin can change the
/// password from the Admin Panel.
class AdminAuth {
  static const defaultEmail = 'admin@school.com';
  static const defaultPassword = 'Admin@123';

  static String get email =>
      SharedPrefsUtil.getString('admin_email', defaultValue: defaultEmail);

  static String get _password =>
      SharedPrefsUtil.getString('admin_password', defaultValue: defaultPassword);

  static bool verify(String email, String password) =>
      email.trim().toLowerCase() == AdminAuth.email.toLowerCase() &&
          password == _password;

  static bool isCurrentPassword(String password) => password == _password;

  static Future<void> changePassword(String newPassword) async {
    await SharedPrefsUtil.setString('admin_password', newPassword);
  }
}