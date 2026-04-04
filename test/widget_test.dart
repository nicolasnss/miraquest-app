// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can use the WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miraquest_app/models/usuario_model.dart';
import 'package:miraquest_app/screens/home_screen.dart';
import 'package:miraquest_app/services/api_service.dart';

class _FakeApiService extends ApiService {
  @override
  Future<UsuarioModel> getUsuarioProgresso(int id) async {
    return const UsuarioModel(
      id: 1,
      emailUsuario: 'teste@miraquest.app',
      vidas: 5,
      xpTotal: 750,
      streakDias: 12,
    );
  }
}

void main() {
  testWidgets('MIRAQuest carrega a home', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF1A237E),
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF1A237E),
            secondary: const Color(0xFF00E676),
            surface: Colors.white,
          ),
        ),
        home: HomeScreen(apiService: _FakeApiService()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('MISSÃO DO DIA'), findsOneWidget);
  });
}
