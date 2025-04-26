import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CadastroPage extends StatefulWidget {
  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  String nome = '', email = '', senha = '', cpf = '', dataNasc = '';

  void cadastrar() async {
    final sucesso = await ApiService.cadastrarUsuario(
      nome: nome,
      email: email,
      senha: senha,
      cpf: cpf,
      dataNasc: dataNasc,
    );

    final snackBar = SnackBar(
      content: Text(sucesso ? 'Cadastro OK' : 'Erro no cadastro'),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nome'),
                onChanged: (v) => nome = v,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onChanged: (v) => email = v,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email é obrigatório';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                onChanged: (v) => senha = v,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Senha é obrigatória';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'CPF'),
                onChanged: (v) => cpf = v,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'CPF é obrigatório';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Data Nasc. (yyyy-mm-dd)'),
                onChanged: (v) => dataNasc = v,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Data de nascimento é obrigatória';
                  }
                  // Validar o formato da data
                  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!dateRegex.hasMatch(value)) {
                    return 'Formato inválido. Use YYYY-MM-DD';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    cadastrar();
                  }
                },
                child: Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
