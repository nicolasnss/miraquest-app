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
    required this.opcoes,
    this.banca,
  });

  final int id;
  final String materia;
  final String enunciado;
  final TipoQuestao tipo;

  /// Opções já embaralhadas pela API (não indicam qual é a correta).
  final List<String> opcoes;

  /// Banca organizadora (ex.: CESPE); nula quando a questão não informa.
  final String? banca;

  factory QuestaoModel.fromJson(Map<String, dynamic> json) {
    return QuestaoModel(
      id: _asInt(json['id']),
      materia: _asString(json['materia']),
      enunciado: _asString(json['enunciado']),
      tipo: _tipoFromJson(json['tipo'] ?? json['tipoQuestao']),
      opcoes: _opcoesFromJson(json['opcoes']),
      banca: _asOptionalString(json['banca']),
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

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static String _asString(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _asOptionalString(Object? value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static List<String> _opcoesFromJson(Object? value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}
