import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/theme/app_theme.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_shell.dart';
import 'screens/login_page.dart';

class XCaptureApp extends StatelessWidget {
  const XCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light(settings.useDynamicColor ? lightDynamic : null),
          darkTheme: AppTheme.dark(settings.useDynamicColor ? darkDynamic : null),
          home: context.watch<AuthProvider>().isLoggedIn ? const HomeShell() : const LoginPage(),
        );
      },
    );
  }
}
