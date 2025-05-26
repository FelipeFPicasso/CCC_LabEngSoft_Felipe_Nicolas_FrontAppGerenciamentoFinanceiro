import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditarUsuarioPopup extends StatefulWidget {
  final String nomeAtual;
  final String emailAtual;
  final String dataNascAtual; // no formato dd/mm/aaaa

  const EditarUsuarioPopup({
    super.key,
    required this.nomeAtual,
    required this.emailAtual,
    required this.dataNascAtual,
  });

  @override
  State<EditarUsuarioPopup> createState() => _EditarUsuarioPopupState();
}

class _EditarUsuarioPopupState extends State<EditarUsuarioPopup> {
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _dataNascController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeAtual);
    _emailController = TextEditingController(text: widget.emailAtual);

    // Converte data ISO para formato dd/MM/yyyy
    String dataFormatada = widget.dataNascAtual;
    try {
      final dataOriginal = DateTime.parse(widget.dataNascAtual); // espera yyyy-MM-dd ou ISO
      final formatter = DateFormat('dd/MM/yyyy');
      dataFormatada = formatter.format(dataOriginal);
    } catch (e) {
      // Se falhar na conversão, mantém o texto original
    }
    _dataNascController = TextEditingController(text: dataFormatada);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _dataNascController.dispose();
    super.dispose();
  }

  Future<void> _salvarUsuario() async {
    final token = await AuthService.obterToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final Map<String, String> dadosParaAtualizar = {};

    if (_nomeController.text.trim().isNotEmpty) {
      dadosParaAtualizar['nome'] = _nomeController.text.trim();
    }
    if (_emailController.text.trim().isNotEmpty) {
      dadosParaAtualizar['email'] = _emailController.text.trim();
    }
    if (_dataNascController.text.trim().isNotEmpty) {
      dadosParaAtualizar['data_nasc'] = _dataNascController.text.trim();
    }

    if (dadosParaAtualizar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha pelo menos um campo para atualizar')),
      );
      return;
    }

    final response = await http.put(
      Uri.parse('http://localhost:8000/usuarios'),
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(dadosParaAtualizar),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário atualizado com sucesso')),
      );
      Navigator.of(context).pop(); // fecha popup
    } else {
      String mensagemErro = 'Erro ao atualizar usuário';
      try {
        final data = jsonDecode(response.body);
        if (data['erro'] != null) mensagemErro = data['erro'];
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro)),
      );
    }
  }

  Future<void> _excluirUsuario() async {
    final token = await AuthService.obterToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('http://localhost:8000/usuarios'),
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      await AuthService.removerToken();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir usuário')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AlertDialog(
        backgroundColor: Colors.black87,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Editar Usuário', style: TextStyle(color: Colors.white)),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dataNascController,
                keyboardType: TextInputType.datetime,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Data de Nascimento (dd/mm/aaaa)',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarUsuario,
                child: const Text('Salvar'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _excluirUsuario,
                child: const Text('Excluir Usuário'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
