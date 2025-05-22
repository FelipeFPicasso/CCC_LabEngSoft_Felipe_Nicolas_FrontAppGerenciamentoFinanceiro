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
      builder: (context, child) =>
          Theme(
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
      content: Text(sucesso
          ? 'Cadastro realizado com sucesso'
          : 'Erro ao cadastrar usuário'),
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
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Cadastro', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Nome', onChanged: (v) => nome = v),
                const SizedBox(height: 12),
                _buildTextField('Email', onChanged: (v) => email = v,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildTextField(
                    'Senha', obscure: true, onChanged: (v) => senha = v),
                const SizedBox(height: 12),
                _buildTextField('CPF', onChanged: (v) => cpf = v,
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dataController,
                  style: const TextStyle(color: Colors.white70),
                  decoration: _darkInputDecoration(
                      'Data Nasc. (DD/MM/AAAA)', icon: Icons.calendar_today),
                  keyboardType: TextInputType.number,
                  inputFormatters: [DateInputFormatter()],
                  readOnly: true,
                  onTap: _selecionarData,
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Data de nascimento é obrigatória'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _cadastrar();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 18),
                      elevation: 2,
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                            (states) {
                          if (states.contains(MaterialState.pressed)) {
                            return Colors.blue[800];
                          } else if (states.contains(MaterialState.hovered)) {
                            return Colors.blue[700];
                          }
                          return null;
                        },
                      ),
                    ),
                    child: const Text("Cadastrar"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white70),
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: _darkInputDecoration(label),
      onChanged: onChanged,
      validator: (value) =>
      (value == null || value.isEmpty)
          ? '$label é obrigatório'
          : null,
    );
  }

  InputDecoration _darkInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white70),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}