import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';  // API rodando na porta 8000

  // Função para cadastrar o usuário
  static Future<bool> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String cpf,
    required String dataNasc,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'cpf': cpf,
        'data_nasc': dataNasc,
      }),
    );

    // Verificar se a resposta foi bem-sucedida (status 201)
    return response.statusCode == 201;
  }

  // Função para listar os usuários
  static Future<List<Map<String, dynamic>>> listarUsuarios({
    String? nome,
    String? email,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios')
        .replace(queryParameters: {
      'nome': nome,
      'email': email,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Falha ao carregar usuários');
    }
  }
}
