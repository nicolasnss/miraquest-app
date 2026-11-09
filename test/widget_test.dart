// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can use the WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miraquest_app/models/materia_model.dart';
import 'package:miraquest_app/models/usuario_model.dart';
import 'package:miraquest_app/screens/home_screen.dart';
import 'package:miraquest_app/services/api_service.dart';
import 'package:miraquest_app/theme/mira_tema.dart';

class _FakeApiService extends ApiService {
  _FakeApiService({this.materias = const []});

  final List<MateriaModel> materias;

  @override
  Future<List<MateriaModel>> getMaterias() async => materias;

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
        theme: MiraTema.claro,
        home: HomeScreen(apiService: _FakeApiService()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ESCOLHA UMA MATÉRIA'), findsOneWidget);
    expect(find.text('Nenhuma matéria disponível ainda.'), findsOneWidget);
  });

  testWidgets('lista as matérias vindas da API', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          apiService: _FakeApiService(
            materias: const [
              MateriaModel(nome: 'Redes', totalQuestoes: 12),
              MateriaModel(nome: 'Banco de Dados', totalQuestoes: 1),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('REDES'), findsOneWidget);
    expect(find.text('12 questões'), findsOneWidget);
    expect(find.text('BANCO DE DADOS'), findsOneWidget);
    expect(find.text('1 questão'), findsOneWidget);
  });
}
