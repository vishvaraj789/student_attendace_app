import 'cloud_sync.dart';
import 'shared_preference.dart';

/// The ONE and only account allowed into the Admin Panel.
///
/// The admin email is fixed in code: it cannot be changed from the app,
/// from device storage, or from the Google Sheet. Only the password can be changed
/// (from the Admin Panel). Change [allowedEmail] below to your own email.
class AdminAuth {
  static const allowedEmail = 'admin@ljku.com';
  static const defaultPassword = 'ljku@123';

  // Earlier versions of the app used this default. If it is still saved on
  // the device or in the Sheet, treat it as "never changed" so the current
  // default password works.
  static const _legacyDefaults = {'Admin@123'};

  /// Always the single allowed admin email (never read from storage).
  static String get email => allowedEmail;

  static bool isAdminEmail(String value) =>
      value.trim().toLowerCase() == allowedEmail.toLowerCase();

  static String get _password {
    final saved = SharedPrefsUtil.getString('admin_password').trim();
    if (saved.isEmpty || _legacyDefaults.contains(saved)) {
      return defaultPassword;
    }
    return saved;
  }

  static bool verify(String email, String password) =>
      isAdminEmail(email) && password.trim() == _password;

  static bool isCurrentPassword(String password) =>
      password.trim() == _password;

  static Future<void> changePassword(String newPassword) async {
    await SharedPrefsUtil.setString('admin_password', newPassword);
    await CloudSync.saveAdmin(email, newPassword);
  }
}