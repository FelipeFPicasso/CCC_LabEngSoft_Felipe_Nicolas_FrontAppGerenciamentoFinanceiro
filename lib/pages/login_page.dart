import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart'; // Import necessário para salvar o token

class LoginPage extends StatefulWidget {
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

      final token = json['token']; // extrai o token do JSON
      if (token != null) {
        await AuthService.salvarToken(token); // salva o token
        Navigator.pushReplacementNamed(context, '/home'); // vai para a tela de menu
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
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Bem-vindo de volta!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shadowColor: Colors.black12,
                      textStyle: TextStyle(fontSize: 18),
                      elevation: 2,
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                            (states) => states.contains(MaterialState.hovered) ? Colors.grey[300] : null,
                      ),
                    ),
                    child: _loading
                        ? CircularProgressIndicator(color: Colors.black)
                        : Text("Entrar"),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/cadastro'),
                      child: Text("Criar conta"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/recuperar-senha'),
                      child: Text("Recuperar senha"),
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