enum TipoQuestao {
  certoErrado,
  cloze,
  multiplaEscolha,
  verdadeiroFalso,
  associacao,
  lacuna,
  desconhecido,
}

class QuestaoModel {
  const QuestaoModel({
    required this.id,
    required this.materia,
    required this.enunciado,
    required this.tipo,
    required this.opcoesDistracao,
    this.respostaCorreta,
  });

  final int id;
  final String materia;
  final String enunciado;
  final TipoQuestao tipo;
  final List<String> opcoesDistracao;
  final String? respostaCorreta;

  factory QuestaoModel.fromJson(Map<String, dynamic> json) {
    return QuestaoModel(
      id: _asInt(json['id']),
      materia: _asString(json['materia']),
      enunciado: _asString(json['enunciado']),
      tipo: _tipoFromJson(json['tipo'] ?? json['tipoQuestao']),
      opcoesDistracao: _opcoesDistracaoFromJson(
        json['opcoesDistracao'] ??
            json['opcoes_distracao'] ??
            json['opcoes'] ??
            json['distracoes'],
      ),
      respostaCorreta: _optionalString(
        json['respostaCorreta'] ?? json['resposta_correta'],
      ),
    );
  }

  static TipoQuestao _tipoFromJson(Object? value) {
    if (value == null) return TipoQuestao.desconhecido;

    // Jackson / Java: enum serializado como objeto { "name": "CLOZE" }.
    if (value is Map) {
      final m = Map<String, dynamic>.from(value);
      final nested = m['name'] ?? m['value'] ?? m['tipo'] ?? m['type'];
      if (nested != null) {
        return _tipoFromJson(nested);
      }
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return TipoQuestao.desconhecido;

    // Backend Java: strings em UPPERCASE (ex.: CERTO_ERRADO, CLOZE).
    final upper = raw.toUpperCase().replaceAll(RegExp(r'[\s\-]+'), '_');
    switch (upper) {
      case 'CERTO_ERRADO':
      case 'CERTOERRADO':
        return TipoQuestao.certoErrado;
      case 'CLOZE':
        return TipoQuestao.cloze;
    }

    final normalized = raw
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '_');

    const aliases = <String, TipoQuestao>{
      'certo_errado': TipoQuestao.certoErrado,
      'certoerrado': TipoQuestao.certoErrado,
      'verdadeirofalso': TipoQuestao.certoErrado,
      'vf': TipoQuestao.certoErrado,
      'cloze': TipoQuestao.cloze,
      'lacuna': TipoQuestao.cloze,
    };
    final direct = aliases[normalized];
    if (direct != null) return direct;

    final noUnderscore = normalized.replaceAll('_', '');
    for (final e in TipoQuestao.values) {
      if (e == TipoQuestao.desconhecido) continue;
      final nameNorm = e.name.toLowerCase().replaceAll('_', '');
      if (nameNorm == noUnderscore) return e;
    }
    return TipoQuestao.desconhecido;
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static String _asString(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Lista JSON ou String única com pipe: `'A|B|C'`.
  static List<String> _opcoesDistracaoFromJson(Object? value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}
