import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;

    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
        if (i <= selectionIndex) selectionIndex++;
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
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

  Future<void> _selecionarData() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(now.year - 18);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: initialDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(), // Fundo escuro no calendário
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        dataNasc = formatted;
        _dataController.text = formatted;
      });
    }
  }

  Future<void> _cadastrar() async {
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

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white12,
        elevation: 0,
        centerTitle: true,
        title: const Text('Cadastro', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Volta para a tela anterior (login)
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Nome'),
                onChanged: (value) => nome = value,
                validator: (value) => value!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => email = value,
                validator: (value) => value!.isEmpty ? 'Informe o email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Senha'),
                obscureText: true,
                onChanged: (value) => senha = value,
                validator: (value) => value!.isEmpty ? 'Informe a senha' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('CPF'),
                keyboardType: TextInputType.number,
                onChanged: (value) => cpf = value,
                validator: (value) => value!.isEmpty ? 'Informe o CPF' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dataController,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Data de Nascimento'),
                keyboardType: TextInputType.number,
                inputFormatters: [DateInputFormatter()],
                onChanged: (value) => dataNasc = value,
                validator: (value) {
                  if (value!.isEmpty) return 'Informe a data';
                  final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                  if (!regex.hasMatch(value)) return 'Formato inválido (DD/MM/AAAA)';
                  return null;
                },
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  await _selecionarData();
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _cadastrar();
                    }
                  },
                  child: const Text(
                    'Cadastrar',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
