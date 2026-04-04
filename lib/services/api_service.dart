import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/questao_model.dart';
import '../models/usuario_model.dart';
import '../models/verificar_resposta_model.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'http://10.0.2.2:8080';

  final http.Client _client;

  Future<UsuarioModel> getUsuarioProgresso(int id) async {
    final uri = Uri.parse('$_baseUrl/api/usuario/$id');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar usuário: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UsuarioModel.fromJson(data);
  }

  Future<List<QuestaoModel>> getLicao(String materia) async {
    final uri = Uri.parse(
      '$_baseUrl/api/questoes/licao?materia=${Uri.encodeQueryComponent(materia)}',
    );
    final response = await _client.get(uri);

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
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

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
