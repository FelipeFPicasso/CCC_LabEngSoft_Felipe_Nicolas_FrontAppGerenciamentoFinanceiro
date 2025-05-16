import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

/// Formatação da data no formato DD/MM/AAAA durante a digitação
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;

    if (newValue.selection.baseOffset == 0) return newValue;

    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;
    int usedSubstringIndex = 0;

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
  const CadastroPage({Key? key}) : super(key: key);

  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String nome = '';
  String email = '';
  String senha = '';
  String cpf = '';
  String dataNasc = '';

  final TextEditingController _dataController = TextEditingController();

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  // Exibe o seletor de data para o usuário
  Future<void> _selecionarData() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: initialDate,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
            onSurface: Colors.blue,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final formattedDate = '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        dataNasc = formattedDate;
        _dataController.text = formattedDate;
      });
    }
  }

  // Realiza a chamada para cadastro via API
  Future<void> _cadastrar() async {
    final bool sucesso = await ApiService.cadastrarUsuario(
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

  // Decora os campos do formulário de maneira padronizada
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.blue),
      floatingLabelStyle: const TextStyle(color: Colors.blue),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: _inputDecoration('Nome'),
                  onChanged: (value) => nome = value,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Nome é obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => email = value,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Email é obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('Senha'),
                  obscureText: true,
                  onChanged: (value) => senha = value,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Senha é obrigatória' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration('CPF'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => cpf = value,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'CPF é obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dataController,
                  decoration: _inputDecoration('Data Nasc. (DD/MM/AAAA)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [DateInputFormatter()],
                  onChanged: (value) => dataNasc = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Data é obrigatória';
                    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                    if (!regex.hasMatch(value)) return 'Formato deve ser DD/MM/AAAA';
                    return null;
                  },
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    await _selecionarData();
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _cadastrar();
                      }
                    },
                    child: const Text('Cadastrar', style: TextStyle(fontSize: 18)),
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
