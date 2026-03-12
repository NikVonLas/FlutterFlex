import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutterflex/providers/app_settings_provider.dart';
import 'package:flutterflex/providers/auth_provider.dart';
import 'package:flutterflex/screens/auth/login_screen.dart';
import 'package:flutterflex/services/api_service.dart';
import 'package:flutterflex/services/auth_service.dart';

void main() {
  testWidgets('Login screen shows core controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appSettings = AppSettingsProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(AuthService(ApiService()), appSettings),
          ),
        ],
        child: MaterialApp(
          theme: appSettings.currentThemeData,
          home: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('FlutterFlex'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'E-Mail'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Passwort'), findsOneWidget);
  });
}
