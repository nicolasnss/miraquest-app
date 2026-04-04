class UsuarioModel {
  const UsuarioModel({
    required this.id,
    required this.emailUsuario,
    required this.vidas,
    required this.xpTotal,
    required this.streakDias,
  });

  final int id;
  final String emailUsuario;
  final int vidas;
  final int xpTotal;
  final int streakDias;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: _asInt(json['id']),
      emailUsuario: _asString(json['emailUsuario'] ?? json['email_usuario']),
      vidas: _asInt(json['vidas']),
      xpTotal: _asInt(json['xpTotal'] ?? json['xp_total']),
      streakDias: _asInt(json['streakDias'] ?? json['streak_dias']),
    );
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
