import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sessão autenticada (token JWT + dados básicos do usuário).
class Sessao {
  const Sessao({
    required this.token,
    required this.usuarioId,
    required this.email,
  });

  final String token;
  final int usuarioId;
  final String email;

  factory Sessao.fromJson(Map<String, dynamic> json) {
    final id = json['usuarioId'];
    return Sessao(
      token: json['token'].toString(),
      usuarioId: id is num ? id.toInt() : int.parse('$id'),
      email: (json['email'] ?? '').toString(),
    );
  }
}

/// Persistência da sessão. Abstração para permitir fakes nos testes.
abstract class SessionStore {
  Future<Sessao?> ler();
  Future<void> salvar(Sessao sessao);
  Future<void> limpar();
}

/// Guarda a sessão no armazenamento seguro do sistema (Keychain / Keystore).
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _kToken = 'auth_token';
  static const _kUsuarioId = 'auth_usuario_id';
  static const _kEmail = 'auth_email';

  final FlutterSecureStorage _storage;

  @override
  Future<Sessao?> ler() async {
    try {
      final token = await _storage.read(key: _kToken);
      final id = int.tryParse(await _storage.read(key: _kUsuarioId) ?? '');
      if (token == null || token.isEmpty || id == null) return null;
      return Sessao(
        token: token,
        usuarioId: id,
        email: await _storage.read(key: _kEmail) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> salvar(Sessao sessao) async {
    await _storage.write(key: _kToken, value: sessao.token);
    await _storage.write(key: _kUsuarioId, value: '${sessao.usuarioId}');
    await _storage.write(key: _kEmail, value: sessao.email);
  }

  @override
  Future<void> limpar() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUsuarioId);
    await _storage.delete(key: _kEmail);
  }
}
