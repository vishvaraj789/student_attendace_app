import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'utils/cloud_sync.dart';
import 'utils/shared_preference.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsUtil.init();
  // Google Sheets: if not configured yet, the app keeps working on the device only.
  await CloudSync.init();
  await CloudSync.pullAll();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}