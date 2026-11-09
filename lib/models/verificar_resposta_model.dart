class VerificarRespostaModel {
  const VerificarRespostaModel({
    required this.sucesso,
    required this.explicacao,
    required this.xpGanho,
    this.pegadinha,
  });

  final bool sucesso;
  final String explicacao;
  final int xpGanho;

  /// Nota sobre a armadilha da questão; só chega após responder. Nula se não houver.
  final String? pegadinha;

  factory VerificarRespostaModel.fromJson(Map<String, dynamic> json) {
    final sucesso = _asBool(
      json['sucesso'] ?? json['correto'] ?? json['acertou'],
    );

    final explicacao = _asString(
      json['explicacao'] ??
          json['explicacaoTecnica'] ??
          json['explicacao_tecnica'] ??
          json['mensagem'],
    );

    final xp = json['xpGanho'] ?? json['xp_ganho'] ?? json['xp'] ?? 0;

    final pegadinha = _asString(json['pegadinha']).trim();

    return VerificarRespostaModel(
      sucesso: sucesso,
      explicacao: explicacao,
      xpGanho: _asInt(xp),
      pegadinha: pegadinha.isEmpty ? null : pegadinha,
    );
  }

  /// Aceita boolean, 0/1 e strings típicas de APIs Java/JSON.
  static bool _asBool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
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
}
