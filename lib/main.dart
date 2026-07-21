import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/captures_provider.dart';
import 'core/localization/l10n_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Desktop window setup (Windows/Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1100, 720),
      minimumSize: Size(480, 600),
      center: true,
      title: 'XCapture',
    );
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final auth = AuthProvider();
  await auth.loadFromStorage();
  final settings = SettingsProvider();
  await settings.load();
  final l10n = L10nProvider();
  await l10n.load(settings.languageCode);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: l10n),
        ChangeNotifierProvider(create: (_) => CapturesProvider()),
      ],
      child: const XCaptureApp(),
    ),
  );
}
