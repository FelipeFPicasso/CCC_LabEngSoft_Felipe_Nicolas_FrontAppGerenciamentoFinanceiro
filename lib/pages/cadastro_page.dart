import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

// Utilitário para máscara DD/MM/AAAA enquanto digita
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;
    int usedSubstringIndex = 0;

    // Remove caracteres não numéricos
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
        if (i <= selectionIndex) selectionIndex++;
      }
      buffer.write(text[i]);
      usedSubstringIndex++;
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class CadastroPage extends StatefulWidget {
  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  String nome = '', email = '', senha = '', cpf = '', dataNasc = '';
  final _dataController = TextEditingController();

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: initialDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // header background
              onPrimary: Colors.white, // header text
              onSurface: Colors.blue, // body text
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        dataNasc = formattedDate;
        _dataController.text = formattedDate;
      });
    }
  }

  void cadastrar() async {
    final sucesso = await ApiService.cadastrarUsuario(
      nome: nome,
      email: email,
      senha: senha,
      cpf: cpf,
      dataNasc: dataNasc,
    );

    final snackBar = SnackBar(
      content: Text(sucesso ? 'Cadastro realizado com sucesso' : 'Erro ao cadastrar usuário'),
      backgroundColor: sucesso ? Colors.green : Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    if (sucesso) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Cadastro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: _inputDecoration('Nome'),
                  onChanged: (v) => nome = v,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Nome é obrigatório' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => email = v,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Email é obrigatório' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('Senha'),
                  obscureText: true,
                  onChanged: (v) => senha = v,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Senha é obrigatória' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('CPF'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => cpf = v,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'CPF é obrigatório' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _dataController,
                  decoration: _inputDecoration('Data Nasc. (DD/MM/AAAA)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [DateInputFormatter()],
                  onChanged: (v) => dataNasc = v,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Data é obrigatória';
                    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                    if (!regex.hasMatch(value)) return 'Formato deve ser DD/MM/AAAA';
                    return null;
                  },
                  onTap: () async {
                    // Evitar abrir o teclado
                    FocusScope.of(context).requestFocus(FocusNode());
                    await _selectDate();
                  },
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
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        cadastrar();
                      }
                    },
                    child: Text('Cadastrar', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}