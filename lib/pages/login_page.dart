import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  void _fazerLogin() {
    print("Login: ${_emailController.text} / ${_senhaController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
          TextField(controller: _senhaController, decoration: InputDecoration(labelText: 'Senha'), obscureText: true),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _fazerLogin, child: Text("Entrar")),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/cadastro'), child: Text("Ir para cadastro")),
        ]),
      ),
    );
  }
}
