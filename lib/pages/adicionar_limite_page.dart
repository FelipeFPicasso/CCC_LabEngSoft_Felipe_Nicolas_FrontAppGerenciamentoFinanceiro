import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/services/auth_services.dart';
import 'dart:convert';

class AdicionarLimitePage extends StatefulWidget {
  const AdicionarLimitePage({super.key});

  @override
  State<AdicionarLimitePage> createState() => _AdicionarLimitePageState();
}

class _AdicionarLimitePageState extends State<AdicionarLimitePage> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  List<dynamic> categorias = [];
  List<dynamic> recorrencias = [];

  int? categoriaSelecionada;
  int? recorrenciaSelecionada;

  String? token;

  @override
  void initState() {
    super.initState();
    carregarTokenEListas();
  }

  Future<void> carregarTokenEListas() async {
    final t = await AuthService.obterToken();
    if (t == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao obter token')),
      );
      return;
    }
    setState(() {
      token = t;
    });
    await Future.wait([fetchCategorias(), fetchRecorrencias()]);
  }

  Future<void> fetchCategorias() async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/categorias-transacao'),
      headers: {'Authorization': '$token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        categorias = json.decode(response.body);
      });
    }
  }

  Future<void> fetchRecorrencias() async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/recorrencias'),
      headers: {'Authorization': '$token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        recorrencias = json.decode(response.body);
      });
    }
  }

  Future<void> salvarLimite() async {
    final titulo = _tituloController.text;
    final valor = _valorController.text;

    if (titulo.isEmpty || valor.isEmpty || categoriaSelecionada == null || recorrenciaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:8000/limite'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token'
      },
      body: json.encode({
        'titulo': titulo,
        'valor': double.parse(valor),
        'fk_id_categoria_transacao': categoriaSelecionada,
        'fk_id_recorrencia': recorrenciaSelecionada,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite criado com sucesso!')),
      );
      Navigator.pop(context); // Volta para a tela de listagem
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar limite.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Limite'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: categoriaSelecionada,
              items: categorias
                  .map((cat) => DropdownMenuItem<int>(
                value: cat['id'],
                child: Text(cat['nome']),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  categoriaSelecionada = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: recorrenciaSelecionada,
              items: recorrencias
                  .map((rec) => DropdownMenuItem<int>(
                value: rec['id'],
                child: Text(rec['nome']),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  recorrenciaSelecionada = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Recorrência'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: salvarLimite,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
