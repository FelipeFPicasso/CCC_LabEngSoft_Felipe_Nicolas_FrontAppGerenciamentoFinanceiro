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
        'Authorization': token,
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

  static Future<List<Map<String, dynamic>>> listarContasUsuario(String token, String userId) async {
    final url = Uri.parse('$baseUrl/contas/usuario');

    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
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
        'Authorization': token,
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
        'Authorization': token,
      },
      body: jsonEncode(conta),
    );

    return response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> getCartoesPorUsuario(String token, int usuarioId) async {
    final url = Uri.parse('$baseUrl/cartoes/usuario/$usuarioId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erro ao buscar cartões: ${response.statusCode} ${response.body}');
    }
  }

  static Future<http.Response> postJson({
    required Uri url,
    required String token,
    required Map<String, dynamic> body,
  }) {
    return http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode(body),
    );
  }

  // Aqui o método para adicionar cartão (usado na tela AdicionarCartaoPage)
  static Future<void> adicionarCartao({
    required String token,
    required double limite,
    required String vencFatura,
    required int idConta,
  }) async {
    final url = Uri.parse('$baseUrl/cartoes');
    final body = {
      'limite': limite,
      'vencimento_fatura': vencFatura,
      'fk_id_conta': idConta,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao adicionar cartão: ${response.statusCode} ${response.body}');
    }
  }
}
