import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:miraquest_app/models/questao_model.dart';
import 'package:miraquest_app/models/materia_model.dart';
import 'package:miraquest_app/models/usuario_model.dart';
import 'package:miraquest_app/models/verificar_resposta_model.dart';
import 'package:miraquest_app/screens/home_screen.dart';
import 'package:miraquest_app/screens/licao_screen.dart';
import 'package:miraquest_app/services/api_service.dart';
import 'package:miraquest_app/theme/mira_tema.dart';

class _FakeApi extends ApiService {
  _FakeApi({required this.certa});

  /// Resposta que a API considera correta.
  final String certa;
  final List<String> enviadas = [];
  final List<int> usuariosEnviados = [];

  @override
  Future<List<MateriaModel>> getMaterias() async => const [
    MateriaModel(nome: 'Redes', totalQuestoes: 1),
  ];

  /// Como a API real: o corpo do progresso NÃO traz o id (id vem como 0).
  @override
  Future<UsuarioModel> getUsuarioProgresso(int id) async => const UsuarioModel(
    id: 0,
    emailUsuario: '',
    vidas: 5,
    xpTotal: 0,
    streakDias: 0,
  );

  @override
  Future<List<QuestaoModel>> getLicao(String materia) async => const [
    QuestaoModel(
      id: 1,
      materia: 'Redes',
      enunciado: 'O protocolo ___ opera na camada de transporte.',
      tipo: TipoQuestao.cloze,
      opcoes: ['TCP', 'IP', 'ICMP', 'ARP'],
      banca: 'CESPE',
    ),
  ];

  @override
  Future<VerificarRespostaModel> verificarResposta({
    required int usuarioId,
    required int questaoId,
    required String resposta,
    String? materia,
  }) async {
    enviadas.add(resposta);
    usuariosEnviados.add(usuarioId);
    final ok = resposta == certa;
    return VerificarRespostaModel(
      sucesso: ok,
      explicacao: 'O TCP garante entrega ordenada.',
      xpGanho: ok ? 10 : 0,
      pegadinha: 'UDP também é de transporte.',
    );
  }
}

Future<void> _abrir(WidgetTester tester, _FakeApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MiraTema.claro,
      home: LicaoScreen(materia: 'Redes', apiService: api),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra matéria, banca, lacuna e opções em grade', (
    tester,
  ) async {
    await _abrir(tester, _FakeApi(certa: 'TCP'));

    expect(find.text('REDES'), findsOneWidget);
    expect(find.text('Banca CESPE'), findsOneWidget);
    expect(find.textContaining('[...]'), findsOneWidget);
    for (final o in ['TCP', 'IP', 'ICMP', 'ARP']) {
      expect(find.text(o), findsOneWidget);
    }
    expect(find.text('EXPLICAÇÃO TÉCNICA'), findsNothing);
  });

  testWidgets('acertar revela a resposta, a explicação e a pegadinha', (
    tester,
  ) async {
    final api = _FakeApi(certa: 'TCP');
    await _abrir(tester, api);

    await tester.tap(find.text('TCP'));
    await tester.pumpAndSettle();

    expect(api.enviadas, ['TCP']);
    expect(find.text('Excelente!'), findsOneWidget);
    expect(find.text('EXPLICAÇÃO TÉCNICA'), findsOneWidget);
    expect(find.text('O TCP garante entrega ordenada.'), findsOneWidget);
    expect(find.text('PEGADINHA'), findsOneWidget);
    expect(find.textContaining('[...]'), findsNothing);
    expect(find.text('CONTINUAR'), findsOneWidget);
  });

  testWidgets(
    'errar mostra o feedback, a explicação e bloqueia nova tentativa',
    (tester) async {
      final api = _FakeApi(certa: 'TCP');
      await _abrir(tester, api);

      await tester.tap(find.text('IP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ICMP'));
      await tester.pumpAndSettle();

      expect(api.enviadas, ['IP']);
      expect(find.text('Humm, não foi dessa vez...'), findsOneWidget);
      expect(find.text('EXPLICAÇÃO TÉCNICA'), findsOneWidget);
    },
  );

  testWidgets('continuar na última questão leva à missão cumprida', (
    tester,
  ) async {
    await _abrir(tester, _FakeApi(certa: 'TCP'));

    await tester.tap(find.text('TCP'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    expect(find.text('Missão cumprida!'), findsOneWidget);
    expect(find.text('+10 XP'), findsOneWidget);
  });

  testWidgets(
    'da home à resposta: envia o id do usuário logado (não o do corpo)',
    (tester) async {
      final api = _FakeApi(certa: 'TCP');
      await tester.pumpWidget(
        MaterialApp(
          theme: MiraTema.claro,
          home: HomeScreen(apiService: api, usuarioId: 7),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('REDES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TCP'));
      await tester.pumpAndSettle();

      expect(api.usuariosEnviados, [7]);
      expect(find.text('Excelente!'), findsOneWidget);
    },
  );
}
