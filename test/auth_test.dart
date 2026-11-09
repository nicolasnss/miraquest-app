import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:miraquest_app/main.dart';
import 'package:miraquest_app/models/materia_model.dart';
import 'package:miraquest_app/models/usuario_model.dart';
import 'package:miraquest_app/screens/login_screen.dart';
import 'package:miraquest_app/services/api_service.dart';
import 'package:miraquest_app/services/session_store.dart';

class _MemoryStore implements SessionStore {
  _MemoryStore([this.sessao]);
  Sessao? sessao;

  @override
  Future<Sessao?> ler() async => sessao;
  @override
  Future<void> salvar(Sessao s) async => sessao = s;
  @override
  Future<void> limpar() async => sessao = null;
}

class _FakeApi extends ApiService {
  @override
  Future<List<MateriaModel>> getMaterias() async => const [
    MateriaModel(nome: 'Redes', totalQuestoes: 3),
  ];

  @override
  Future<Sessao> login(String email, String senha) async {
    if (senha != 'senha-forte-1') {
      throw Exception('E-mail ou senha inválidos.');
    }
    return Sessao(token: 'tok', usuarioId: 7, email: email);
  }

  @override
  Future<UsuarioModel> getUsuarioProgresso(int id) async => UsuarioModel(
    id: id,
    emailUsuario: 'a@x.com',
    vidas: 5,
    xpTotal: 10,
    streakDias: 1,
  );
}

Widget _app(SessionStore store, ApiService api) => MaterialApp(
  home: AuthGate(store: store, api: api),
);

void main() {
  group('AuthGate', () {
    testWidgets('sem sessão mostra o login', (tester) async {
      await tester.pumpWidget(_app(_MemoryStore(), _FakeApi()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('com sessão salva vai direto para a home', (tester) async {
      final store = _MemoryStore(
        const Sessao(token: 'tok', usuarioId: 7, email: 'a@x.com'),
      );
      await tester.pumpWidget(_app(store, _FakeApi()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('ESCOLHA UMA MATÉRIA'), findsOneWidget);
    });

    testWidgets('login válido guarda a sessão e abre a home; sair limpa', (
      tester,
    ) async {
      final store = _MemoryStore();
      await tester.pumpWidget(_app(store, _FakeApi()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'a@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'senha-forte-1');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(store.sessao?.token, 'tok');
      expect(find.text('ESCOLHA UMA MATÉRIA'), findsOneWidget);

      await tester.tap(find.byTooltip('Sair'));
      await tester.pumpAndSettle();

      expect(store.sessao, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('credenciais inválidas mostram erro e ficam no login', (
      tester,
    ) async {
      final store = _MemoryStore();
      await tester.pumpWidget(_app(store, _FakeApi()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'a@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'errada');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
      expect(store.sessao, isNull);
    });

    testWidgets('criar conta exige senha de 8+ caracteres', (tester) async {
      await tester.pumpWidget(_app(_MemoryStore(), _FakeApi()));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('criar agora'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'a@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'curta');
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(
        find.text('A senha deve ter de 8 a 72 caracteres'),
        findsOneWidget,
      );
    });
  });

  group('ApiService', () {
    test('getMaterias lê a lista e envia o token', () async {
      String? auth;
      final api = ApiService(
        client: MockClient((req) async {
          auth = req.headers['Authorization'];
          return http.Response(
            jsonEncode([
              {'nome': 'Informática Básica', 'totalQuestoes': 4},
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      )..token = 'abc';

      final materias = await api.getMaterias();

      expect(auth, 'Bearer abc');
      expect(materias.single.nome, 'Informática Básica');
      expect(materias.single.totalQuestoes, 4);
    });

    test('envia Authorization: Bearer quando há token', () async {
      String? auth;
      final api = ApiService(
        client: MockClient((req) async {
          auth = req.headers['Authorization'];
          return http.Response(
            jsonEncode({
              'id': 7,
              'emailUsuario': 'a@x.com',
              'vidas': 5,
              'xpTotal': 0,
              'streakDias': 0,
            }),
            200,
          );
        }),
      )..token = 'abc';

      await api.getUsuarioProgresso(7);

      expect(auth, 'Bearer abc');
    });

    test('401 vira NaoAutorizadoException', () async {
      final api = ApiService(
        client: MockClient((_) async => http.Response('', 401)),
      );

      expect(api.getLicao('REDES'), throwsA(isA<NaoAutorizadoException>()));
    });

    test('login traduz 401 em mensagem amigável e 201 em sessão', () async {
      var status = 401;
      final api = ApiService(
        client: MockClient(
          (_) async => http.Response(
            status == 201
                ? jsonEncode({'token': 't', 'usuarioId': 3, 'email': 'a@x.com'})
                : '',
            status,
          ),
        ),
      );

      await expectLater(
        api.login('a@x.com', 'x'),
        throwsA(predicate((e) => '$e'.contains('E-mail ou senha inválidos'))),
      );

      status = 201;
      final sessao = await api.registrar('a@x.com', 'senha-forte-1');
      expect(sessao.usuarioId, 3);
      expect(sessao.token, 't');
    });
  });
}
