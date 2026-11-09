import 'package:flutter/foundation.dart';

/// Configuração em tempo de build.
///
/// A URL da API vem de `--dart-define=API_BASE_URL=https://api.exemplo.com`
/// (ou `--dart-define-from-file=config/dev.json`). Sem ela, usa-se um padrão
/// de desenvolvimento conforme a plataforma.
class AppConfig {
  const AppConfig._();

  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// URL base efetiva da API (sem barra final).
  static String get apiBaseUrl => resolverApiBaseUrl(
    configurada: _apiBaseUrlDefine,
    plataforma: defaultTargetPlatform,
    web: kIsWeb,
  );

  /// Separada do getter para ser testável.
  @visibleForTesting
  static String resolverApiBaseUrl({
    required String? configurada,
    required TargetPlatform plataforma,
    required bool web,
  }) {
    final url = configurada?.trim() ?? '';
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !(uri.scheme == 'http' || uri.scheme == 'https') ||
          uri.host.isEmpty) {
        throw FormatException(
          'API_BASE_URL inválida: "$url" (use http(s)://host[:porta])',
        );
      }
      return url.replaceFirst(RegExp(r'/+$'), '');
    }
    // Emulador Android enxerga a máquina host em 10.0.2.2.
    if (!web && plataforma == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
