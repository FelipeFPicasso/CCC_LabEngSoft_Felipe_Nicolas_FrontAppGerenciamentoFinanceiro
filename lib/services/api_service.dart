import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  // Login
  static Future<http.Response> login(String email, String senha) {
    return http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
  }

  // Cadastrar usuário
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
    return response.statusCode == 201;
  }

  // Listar usuários
  static Future<List<Map<String, dynamic>>> listarUsuarios({
    String? nome,
    String? email,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios').replace(queryParameters: {
      if (nome != null) 'nome': nome,
      if (email != null) 'email': email,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Falha ao carregar usuários');
    }
  }

  // Solicitar código de recuperação
  static Future<bool> solicitarCodigoRecuperacao(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/recuperar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  // Alterar senha
  static Future<bool> alterarSenha(String email, String codigo, String novaSenha) async {
    final response = await http.put(
      Uri.parse('$baseUrl/usuarios/senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'codigo_recuperacao': codigo,
        'nova_senha': novaSenha,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<double> obterSaldoAtual(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/saldo-atual'),
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['saldo_atual']?.toDouble() ?? 0.0;
    } else {
      throw Exception('Erro ao buscar saldo');
    }
  }
  static Future<Map<String, dynamic>> criarCartao(
      String token, String limite, String vencFatura) async {
    final url = Uri.parse('$baseUrl/cartao');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',  // <-- token enviado aqui
      },
      body: jsonEncode({
        'limite': limite,
        'venc_fatura': vencFatura,
      }),
    );

    if (response.statusCode == 401) {
      print('Token inválido ou expirado!');
      // Pode tratar logout, pedir novo login, etc.
    }

    return jsonDecode(response.body);
  }
  static Future<List<Map<String, dynamic>>> listarContasUsuario(String token, String userId) async {
    final url = Uri.parse('$baseUrl/conta/usuario/$userId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['contas']);
    } else {
      throw Exception('Erro ao carregar contas do usuário');
    }
  }
  static Future<double> obterSaldoAtualConta(String token, int fkIdConta) async {
    final response = await http.get(
      Uri.parse('$baseUrl/saldo_atual/$fkIdConta'),
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['saldo']?.toDouble() ?? 0.0;
    } else {
      throw Exception('Erro ao buscar saldo da conta');
    }
  }

  static Future<bool> criarConta(String token, Map<String, dynamic> conta) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conta'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(conta),
    );

    return response.statusCode == 201;
  }

}