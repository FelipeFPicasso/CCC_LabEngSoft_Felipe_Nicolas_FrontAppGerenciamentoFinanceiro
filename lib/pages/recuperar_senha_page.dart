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
      labelStyle: TextStyle(color: Colors.white),
      floatingLabelStyle: TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void solicitarCodigo() async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informe o e-mail'), backgroundColor: Colors.red),
      );
      return;
    }

    final sucesso = await ApiService.solicitarCodigoRecuperacao(email);
    if (sucesso) {
      setState(() => codigoEnviado = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Código enviado ao seu e-mail'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao enviar código'), backgroundColor: Colors.red),
      );
    }
  }

  void alterarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    final sucesso = await ApiService.alterarSenha(email, codigo, novaSenha);
    final msg = sucesso ? 'Senha alterada com sucesso' : 'Falha ao alterar senha';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: sucesso ? Colors.green : Colors.red),
    );

    if (sucesso) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Recuperar Senha'),
        backgroundColor: Colors.white12,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: _inputDecoration('E-mail'),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.white),
                onChanged: (v) => email = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Informe o e-mail' : null,
                enabled: !codigoEnviado,
              ),
              SizedBox(height: 20),
              if (!codigoEnviado)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: solicitarCodigo,
                    child: Text('Enviar Código', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              if (codigoEnviado) ...[
                SizedBox(height: 16),
                TextFormField(
                  decoration: _inputDecoration('Código de Recuperação'),
                  style: TextStyle(color: Colors.white),
                  onChanged: (v) => codigo = v,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o código' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: _inputDecoration('Nova Senha'),
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                  onChanged: (v) => novaSenha = v,
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe a nova senha' : null,
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: alterarSenha,
                    child: Text('Alterar Senha', style: TextStyle(fontSize: 18, color: Colors.white)),
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
