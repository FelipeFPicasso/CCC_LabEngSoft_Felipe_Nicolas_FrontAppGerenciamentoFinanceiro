import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  // Salvar o token
  static Future<void> salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Buscar o token
  static Future<String?> obterToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Remover o token (logout)
  static Future<void> removerToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Obter o ID do usuário diretamente a partir do token
  static Future<int?> obterUsuarioId() async {
    final token = await obterToken();
    if (token == null || JwtDecoder.isExpired(token)) return null;

    final decodedToken = JwtDecoder.decode(token);
    return decodedToken['usuario_id'];
  }
}