import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/scanner_pro_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ScannerProApp());
}

class ScannerProApp extends StatelessWidget {
  const ScannerProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3D Scanner Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData(),
      home: const SafeArea(
        child: const LoginScreen(),
      ),
    );
  }
}
