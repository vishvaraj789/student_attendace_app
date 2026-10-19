import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'app_config.dart';

/// Builds and shares a "here is your login" message.
class LoginShare {
  static String message({
    required String name,
    required String role,
    required String email,
    required String password,
  }) {
    final b = StringBuffer()
      ..writeln('Hello $name,')
      ..writeln()
      ..writeln('Your $role login for ${AppConfig.appName}:')
      ..writeln()
      ..writeln('Email: $email')
      ..writeln(
          'Password: ${password.isEmpty ? '(ask your administrator)' : password}');
    b
      ..writeln()
      ..write('Sign in with this email and password. Please keep them private.');
    return b.toString();
  }

  /// Message telling a faculty member which class was assigned to them.
  static String classAssignmentMessage({
    required String facultyName,
    required String subject,
    required String className,
    required String division,
    required String schedule,
  }) {
    return 'Hello $facultyName,\n\n'
        'A class has been assigned to you in ${AppConfig.appName}:\n\n'
        'Subject: $subject\n'
        'Class: $className\n'
        'Division: $division\n'
        'Schedule: $schedule\n\n'
        'To take attendance: sign in, then tap "Take attendance" on this '
        'class under "My classes" on your home screen.';
  }

  static Future<void> shareText(BuildContext context, String text,
      {String? subject}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Share.share(text, subject: subject ?? AppConfig.appName);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(const SnackBar(
        content: Text('Sharing is not available here. Message copied.'),
      ));
    }
  }

  /// Opens the phone's share sheet. If sharing isn't available the message
  /// is copied instead so it can be pasted into any chat or email.
  static Future<void> share(
      BuildContext context, {
        required String name,
        required String role,
        required String email,
        required String password,
      }) async {
    final text = message(
        name: name, role: role, email: email, password: password);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Share.share(text, subject: '${AppConfig.appName} login');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(const SnackBar(
        content: Text('Sharing is not available here. Message copied.'),
      ));
    }
  }
}