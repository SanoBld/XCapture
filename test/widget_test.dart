import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xcapture/app.dart';
import 'package:xcapture/providers/auth_provider.dart';
import 'package:xcapture/providers/settings_provider.dart';
import 'package:xcapture/providers/captures_provider.dart';

void main() {
  testWidgets('App shows login page when logged out', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => CapturesProvider()),
        ],
        child: const XCaptureApp(),
      ),
    );
    expect(find.text('XCapture'), findsOneWidget);
  });
}
