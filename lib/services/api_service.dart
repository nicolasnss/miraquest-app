import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/materia_model.dart';
import '../models/questao_model.dart';
import '../models/usuario_model.dart';
import '../models/verificar_resposta_model.dart';
import 'session_store.dart';

/// Token ausente, inválido ou expirado (HTTP 401).
class NaoAutorizadoException implements Exception {
  const NaoAutorizadoException();
  @override
  String toString() => 'Sessão expirada. Entre novamente.';
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final String _baseUrl;
  final http.Client _client;

  /// JWT enviado em todas as chamadas autenticadas.
  String? token;

  Map<String, String> get _headers => {
    if (token != null) 'Authorization': 'Bearer $token',
  };

  void _checarAutorizacao(http.Response response) {
    if (response.statusCode == 401) throw const NaoAutorizadoException();
  }

  Future<Sessao> login(String email, String senha) =>
      _autenticar('login', email, senha);

  Future<Sessao> registrar(String email, String senha) =>
      _autenticar('registrar', email, senha);

  Future<Sessao> _autenticar(String acao, String email, String senha) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/auth/$acao'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Sessao.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception(switch (response.statusCode) {
      401 => 'E-mail ou senha inválidos.',
      409 => 'Este e-mail já está cadastrado.',
      400 => 'Informe um e-mail válido e uma senha com 8 a 72 caracteres.',
      _ => 'Falha na autenticação (${response.statusCode}).',
    });
  }

  Future<UsuarioModel> getUsuarioProgresso(int id) async {
    final uri = Uri.parse('$_baseUrl/api/usuario/$id');
    final response = await _client.get(uri, headers: _headers);

    _checarAutorizacao(response);
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar usuário: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UsuarioModel.fromJson(data);
  }

  /// Matérias disponíveis (derivadas das questões cadastradas).
  Future<List<MateriaModel>> getMaterias() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/materias'),
      headers: _headers,
    );
    _checarAutorizacao(response);
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar matérias: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return [];
    return decoded
        .map((e) => MateriaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<QuestaoModel>> getLicao(String materia) async {
    final uri = Uri.parse(
      '$_baseUrl/api/questoes/licao?materia=${Uri.encodeQueryComponent(materia)}',
    );
    final response = await _client.get(uri, headers: _headers);

    _checarAutorizacao(response);
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar lição: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map((e) => QuestaoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final list = decoded['questoes'] ?? decoded['data'];
      if (list is List) {
        return list
            .map((e) => QuestaoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// Valida a resposta do usuário para uma questão.
  Future<VerificarRespostaModel> verificarResposta({
    required int usuarioId,
    required int questaoId,
    required String resposta,
    String? materia,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/questoes/verificar');
    final body = <String, dynamic>{
      'usuarioId': usuarioId,
      'questaoId': questaoId,
      'resposta': resposta,
      if (materia != null && materia.isNotEmpty) 'materia': materia,
    };

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8', ..._headers},
      body: jsonEncode(body),
    );

    _checarAutorizacao(response);
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao verificar resposta: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do servidor');
    }
    return VerificarRespostaModel.fromJson(data);
  }
}
