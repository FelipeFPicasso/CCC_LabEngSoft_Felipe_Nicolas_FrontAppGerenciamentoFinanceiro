import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart'; // Import necessário para salvar o token

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;
  String? _erro;

  Future<void> _fazerLogin() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    final response = await ApiService.login(
      _emailController.text,
      _senhaController.text,
    );

    setState(() {
      _loading = false;
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final token = json['token'];

      if (token != null) {
        await AuthService.salvarToken(token);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _erro = 'Token não encontrado na resposta.';
        });
      }
    } else {
      setState(() {
        _erro = 'Login falhou: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Bem-vindo de volta!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[600])),
                SizedBox(height: 24),
                TextField(
                  style: TextStyle(color: Colors.white70),
                  cursorWidth: 1,
                  cursorHeight: 17,
                  cursorColor: Colors.white,
                  controller: _emailController,
                  decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.email, color: Colors.white70),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                          borderRadius: BorderRadius.circular(8)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                        color: Colors.white, // cor da borda ao focar
                  ),
                ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  style: TextStyle(color: Colors.white70),
                  cursorWidth: 1,
                  cursorHeight: 17,
                  cursorColor: Colors.white,
                  controller: _senhaController,
                  decoration: InputDecoration(
                      labelText: 'Senha',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.lock, color: Colors.white70),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                          borderRadius: BorderRadius.circular(8)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white, // cor da borda ao focar
                        ),
                      ),
                  ),
                  obscureText: true,
                ),
                if (_erro != null) ...[
                  SizedBox(height: 16),
                  Text(
                    _erro!,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _fazerLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shadowColor: Colors.black,
                      textStyle: const TextStyle(fontSize: 18),
                      elevation: 2,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.blue[800]; // cor ao pressionar
                          } else if (states.contains(WidgetState.hovered)) {
                            return Colors.blue[700];
                          }
                          return null;
                        },
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                      "Entrar",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[500],
                        overlayColor: Colors.black,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/cadastro'),
                      child: Text("Criar conta", style: TextStyle(color: Colors.blue[500]),),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[500],
                        overlayColor: Colors.black,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/recuperar-senha'),
                      child: Text("Recuperar senha", style: TextStyle(color: Colors.blue[500]),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}