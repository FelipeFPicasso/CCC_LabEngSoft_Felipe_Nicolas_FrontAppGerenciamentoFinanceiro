import 'package:flutter/material.dart';
import '../services/api_service.dart'; // sua API service

class RecuperarSenhaPage extends StatefulWidget {
  const RecuperarSenhaPage({super.key});

  @override
  _RecuperarSenhaPageState createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String codigo = '';
  String novaSenha = '';
  bool codigoEnviado = false;

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.blue),
      floatingLabelStyle: TextStyle(color: Colors.blue),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  void solicitarCodigo() async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Informe o e-mail'), backgroundColor: Colors.red));
      return;
    }

    final sucesso = await ApiService.solicitarCodigoRecuperacao(email);
    if (sucesso) {
      setState(() => codigoEnviado = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Código enviado ao seu e-mail'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar código'), backgroundColor: Colors.red));
    }
  }

  void alterarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    final sucesso = await ApiService.alterarSenha(email, codigo, novaSenha);
    final msg = sucesso ? 'Senha alterada com sucesso' : 'Falha ao alterar senha';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: sucesso ? Colors.green : Colors.red,
    ));

    if (sucesso) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Recuperar Senha'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: _inputDecoration('E-mail'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => email = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Informe o e-mail' : null,
                enabled: !codigoEnviado,
              ),
              SizedBox(height: 16),
              if (!codigoEnviado)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: solicitarCodigo,
                    child: Text('Enviar Código', style: TextStyle(fontSize: 18)),
                  ),
                ),
              if (codigoEnviado) ...[
                SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('Código de Recuperação'),
                  onChanged: (v) => codigo = v,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o código' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('Nova Senha'),
                  obscureText: true,
                  onChanged: (v) => novaSenha = v,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe a nova senha' : null,
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: alterarSenha,
                    child: Text('Alterar Senha', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}