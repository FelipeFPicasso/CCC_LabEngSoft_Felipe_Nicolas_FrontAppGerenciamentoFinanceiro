// lib/pages/cadastro_page.dart

import 'package:flutter/material.dart';

class CadastroPage extends StatelessWidget {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController dataNascController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cadastro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            TextField(
              controller: cpfController,
              decoration: InputDecoration(labelText: 'CPF'),
            ),
            TextField(
              controller: dataNascController,
              decoration: InputDecoration(labelText: 'Data de Nascimento (YYYY-MM-DD)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aqui você pode chamar sua API para cadastrar o usuário
                print('Nome: ${nomeController.text}');
                print('Email: ${emailController.text}');
                print('Senha: ${passwordController.text}');
                print('CPF: ${cpfController.text}');
                print('Data de Nascimento: ${dataNascController.text}');
              },
              child: Text("Cadastrar"),
            ),
          ],
        ),
      ),
    );
  }
}
