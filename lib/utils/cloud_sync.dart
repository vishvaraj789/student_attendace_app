import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'admin_auth.dart';
import 'faculty_repository.dart';
import 'shared_preference.dart';
import 'sheets_config.dart';

/// Keeps the app's data in a Google Sheet (through a small Apps Script web app).
///
/// The app still reads from the device (SharedPreferences) so screens stay
/// fast and work offline. Every save is also sent to the Sheet, and
/// [pullAll] refreshes the device copy from the Sheet (app start + login).
///
/// Sheet tabs: students, classes, faculty, attendance, settings
class CloudSync {
  static bool _ready = false;
  static bool get isReady => _ready;

  /// Short human-readable sync state (shown on the login page).
  static String status = 'Sheets: not started';

  static const _writeTimeout = Duration(seconds: 15);

  /// Turns Google Sheets sync on. Safe to call when it isn't configured yet:
  /// the app simply stays in offline (device-only) mode.
  static Future<void> init() async {
    if (SheetsConfig.webAppUrl.startsWith('YOUR_') ||
        SheetsConfig.token.startsWith('YOUR_')) {
      debugPrint('Google Sheets not configured: see google_sheets/SETUP.md');
      status = 'Sheets: NOT configured (fill sheets_config.dart)';
      _ready = false;
      return;
    }
    _ready = true;
    status = 'Sheets: configured, not synced yet';
  }

  // ---------------------------------------------------------------- writes

  static Future<bool> _post(Map<String, dynamic> body) async {
    try {
      var res = await http
          .post(
        Uri.parse(SheetsConfig.webAppUrl),
        // text/plain keeps this a "simple" request (no CORS preflight).
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({...body, 'token': SheetsConfig.token}),
      )
          .timeout(_writeTimeout);
      // Apps Script runs the request, then answers with a redirect that
      // holds the result. Follow it so errors are not silently ignored.
      if ({301, 302, 303, 307, 308}.contains(res.statusCode)) {
        final loc = res.headers['location'];
        if (loc != null) {
          res = await http.get(Uri.parse(loc)).timeout(_writeTimeout);
        }
      }
      if (res.statusCode != 200) {
        debugPrint('Sheets write failed: HTTP ${res.statusCode}');
        status = 'Sheets: write failed (HTTP ${res.statusCode})';
        return false;
      }
      try {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        if (j['ok'] != true) {
          debugPrint('Sheets rejected the write: ${j['error']}');
          status = 'Sheets: rejected (${j['error']})';
          return false;
        }
      } catch (_) {
        debugPrint('Sheets did not return JSON. Is the web app deployed with '
            '"Who has access: Anyone"?');
        status = 'Sheets: bad reply (set access to Anyone)';
        return false;
      }
      status = 'Sheets: connected, last save OK';
      return true;
    } catch (e) {
      debugPrint('Sheets request failed: $e');
      status = 'Sheets: request failed ($e)';
      return false;
    }
  }

  /// Makes sheet tab [name] match [items] (each needs an 'id').
  static Future<void> syncCollection(
      String name,
      List<Map<String, dynamic>> items,
      ) async {
    if (!_ready) return;
    await _post({'action': 'syncCollection', 'name': name, 'items': items});
  }

  static Future<void> saveAttendance(
      String classId,
      String dateKey,
      Map<String, bool> status,
      ) async {
    if (!_ready) return;
    await _post({
      'action': 'saveAttendance',
      'classId': classId,
      'date': dateKey,
      'status': status,
    });
  }

  static Future<void> deleteAttendanceForClass(String classId) async {
    if (!_ready) return;
    await _post({'action': 'deleteAttendanceForClass', 'classId': classId});
  }

  static Future<void> saveAdmin(String email, String password) async {
    if (!_ready) return;
    await _post({'action': 'saveAdmin', 'email': email, 'password': password});
  }

  // ----------------------------------------------------------------- reads

  /// Refreshes the device copy from the Sheet. The very first time on a
  /// device, anything already saved locally is uploaded instead, so
  /// existing data isn't lost.
  static Future<void> pullAll({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_ready) return;
    try {
      await _pull().timeout(timeout);
    } catch (e) {
      debugPrint('Sheets pull failed (using device copy): $e');
      status = 'Sheets: pull failed ($e)';
    }
  }

  static Future<Map<String, dynamic>?> _fetch() async {
    final uri = Uri.parse(SheetsConfig.webAppUrl).replace(
      queryParameters: {'action': 'pull', 'token': SheetsConfig.token},
    );
    final res = await http.get(uri); // follows Apps Script's redirect
    if (res.statusCode != 200) {
      status = 'Sheets: pull failed (HTTP ${res.statusCode})';
      return null;
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['ok'] != true) {
      debugPrint('Sheets error: ${body['error']}');
      status = 'Sheets: rejected (${body['error']}) - check token';
      return null;
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  static Future<void> _pull() async {
    final data = await _fetch();
    if (data == null) return; // keep the device copy
    final seeded = SharedPrefsUtil.getBool('sheets_seeded');
    FacultyRepository.getAll(); // runs the old-account migration first

    await _pullList(data['students'], 'students', 'students', seeded);
    await _pullList(data['classes'], 'classes', 'classes', seeded);
    await _pullList(data['faculty'], 'faculty', 'faculty_accounts', seeded);
    await _pullAttendance(data['attendance'], seeded);
    await _pullAdmin(data['admin'], seeded);

    await SharedPrefsUtil.setBool('sheets_seeded', true);
    if (!status.contains('failed') && !status.contains('rejected')) {
      status = 'Sheets: connected';
    }
  }

  static Future<void> _pullList(
      dynamic cloud,
      String collection,
      String prefsKey,
      bool seeded,
      ) async {
    final rows = (cloud as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (rows.isEmpty) {
      if (!seeded) {
        final raw = SharedPrefsUtil.getString(prefsKey);
        if (raw.isNotEmpty) {
          final list = (jsonDecode(raw) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          await syncCollection(collection, list);
        }
      } else {
        await SharedPrefsUtil.setString(prefsKey, '[]');
      }
      return;
    }
    await SharedPrefsUtil.setString(prefsKey, jsonEncode(rows));
  }

  static Future<void> _pullAttendance(dynamic cloud, bool seeded) async {
    final rows = (cloud as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (rows.isEmpty) {
      if (!seeded) {
        final raw = SharedPrefsUtil.getString('attendance');
        if (raw.isNotEmpty) {
          final all = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          for (final c in all.entries) {
            final days = Map<String, dynamic>.from(c.value as Map);
            for (final d in days.entries) {
              await saveAttendance(
                c.key,
                d.key,
                Map<String, bool>.from(d.value as Map),
              );
            }
          }
        }
      } else {
        await SharedPrefsUtil.setString('attendance', '{}');
      }
      return;
    }
    final all = <String, Map<String, dynamic>>{};
    for (final r in rows) {
      final classId = r['classId'] as String;
      all.putIfAbsent(classId, () => {});
      all[classId]![r['date'] as String] =
      Map<String, dynamic>.from(r['status'] as Map);
    }
    await SharedPrefsUtil.setString('attendance', jsonEncode(all));
  }

  static Future<void> _pullAdmin(dynamic cloud, bool seeded) async {
    if (cloud is Map) {
      // The admin email is fixed in code (AdminAuth.allowedEmail); only the
      // password is synced from the Sheet.
      final cloudPassword = cloud['password'] as String? ?? '';
      if (cloudPassword.isNotEmpty) {
        await SharedPrefsUtil.setString('admin_password', cloudPassword);
      }
    } else if (!seeded) {
      final password = SharedPrefsUtil.getString('admin_password');
      if (password.isNotEmpty) {
        await saveAdmin(AdminAuth.allowedEmail, password);
      }
    }
  }
}