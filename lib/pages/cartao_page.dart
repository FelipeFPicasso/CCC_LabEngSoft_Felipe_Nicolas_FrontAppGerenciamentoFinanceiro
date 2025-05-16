import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';

class CartaoPage extends StatefulWidget {
  @override
  _CartaoPageState createState() => _CartaoPageState();
}

class _CartaoPageState extends State<CartaoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController limiteController = TextEditingController();
  final TextEditingController vencFaturaController = TextEditingController();

  bool carregando = false;
  String? mensagemErro;
  String? mensagemSucesso;

  static const Color primaryColor = Color(0xFF1B263B);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color inputFillColor = Colors.white;

  InputDecoration estiloInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        fontSize: 16,
      ),
      filled: true,
      fillColor: inputFillColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
    );
  }

  ButtonStyle estiloBotao() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      padding: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }

  Future<void> criarCartao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      carregando = true;
      mensagemErro = null;
      mensagemSucesso = null;
    });

    final token = await AuthService.obterToken();
    if (token == null) {
      setState(() {
        mensagemErro = 'Token inválido. Faça login novamente.';
        carregando = false;
      });
      return;
    }

    try {
      final resposta = await ApiService.criarCartao(
        token,
        limiteController.text,
        vencFaturaController.text,
      );

      if (resposta['cartao'] != null) {
        setState(() {
          mensagemSucesso = 'Cartão criado com sucesso!';
          carregando = false;
        });
        limiteController.clear();
        vencFaturaController.clear();
      } else {
        setState(() {
          mensagemErro = resposta['erro'] ?? 'Erro desconhecido';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        mensagemErro = 'Erro ao criar cartão: $e';
        carregando = false;
      });
    }
  }

  @override
  void dispose() {
    limiteController.dispose();
    vencFaturaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Adicionar Cartão', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: primaryColor,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: limiteController,
                keyboardType: TextInputType.number,
                decoration: estiloInput('Limite'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o limite';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Informe um número válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: vencFaturaController,
                decoration: estiloInput('Vencimento da Fatura (YYYY-MM-DD)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a data de vencimento';
                  }
                  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!regex.hasMatch(value)) {
                    return 'Formato inválido (use YYYY-MM-DD)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              carregando
                  ? CircularProgressIndicator(color: primaryColor)
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: criarCartao,
                  style: estiloBotao(),
                  child: Text('Adicionar Cartão'),
                ),
              ),
              if (mensagemErro != null)
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    mensagemErro!,
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (mensagemSucesso != null)
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    mensagemSucesso!,
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
