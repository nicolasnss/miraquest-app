import 'package:flutter_test/flutter_test.dart';
import 'package:miraquest_app/models/questao_model.dart';
import 'package:miraquest_app/models/verificar_resposta_model.dart';

void main() {
  test('QuestaoModel lê banca e trata ausente/vazia como nula', () {
    final com = QuestaoModel.fromJson({
      'id': 1,
      'materia': 'Redes',
      'enunciado': 'x',
      'tipo': 'CLOZE',
      'opcoes': ['a', 'b'],
      'banca': ' CESPE ',
    });
    final sem = QuestaoModel.fromJson({'id': 2, 'tipo': 'CLOZE', 'banca': ''});
    final ausente = QuestaoModel.fromJson({'id': 3, 'tipo': 'CLOZE'});

    expect(com.banca, 'CESPE');
    expect(sem.banca, isNull);
    expect(ausente.banca, isNull);
  });

  test('VerificarRespostaModel lê pegadinha e trata nula/vazia', () {
    final com = VerificarRespostaModel.fromJson({
      'sucesso': false,
      'explicacao': 'e',
      'xpGanho': 0,
      'pegadinha': 'Cuidado com o termo absoluto',
    });
    final nula = VerificarRespostaModel.fromJson({
      'sucesso': true,
      'explicacao': '',
      'xpGanho': 10,
      'pegadinha': null,
    });

    expect(com.pegadinha, 'Cuidado com o termo absoluto');
    expect(nula.pegadinha, isNull);
  });
}
