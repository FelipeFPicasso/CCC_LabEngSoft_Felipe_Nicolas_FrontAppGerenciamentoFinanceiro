import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_services.dart';

class EditarLimitePopup extends StatefulWidget {
  final Map<String, dynamic> limite;

  const EditarLimitePopup({Key? key, required this.limite}) : super(key: key);

  @override
  State<EditarLimitePopup> createState() => _EditarLimitePopupState();
}

class _EditarLimitePopupState extends State<EditarLimitePopup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _valorController;

  // Dropdown selections
  String? _recorrenciaSelecionada;
  String? _categoriaSelecionada;

  // Listas que virão da API
  List<Map<String, dynamic>> _recorrencias = [];
  List<Map<String, dynamic>> _categorias = [];

  bool _carregandoDadosFixos = true;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.limite['titulo']);
    _valorController = TextEditingController(text: widget.limite['valor'].toString());

    _recorrenciaSelecionada = widget.limite['fk_id_recorrencia']?.toString();
    _categoriaSelecionada = widget.limite['fk_id_categoria_transacao']?.toString();

    _carregarDadosFixos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosFixos() async {
    final token = await AuthService.obterToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      setState(() => _carregandoDadosFixos = false);
      return;
    }

    try {
      final urlRecorrencias = Uri.parse('http://localhost:8000/recorrencias');
      final urlCategorias = Uri.parse('http://localhost:8000/categorias-transacao');

      final responses = await Future.wait([
        http.get(urlRecorrencias, headers: {'Authorization': '$token'}),
        http.get(urlCategorias, headers: {'Authorization': '$token'}),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final recorrenciasJson = json.decode(responses[0].body) as List<dynamic>;
        final categoriasJson = json.decode(responses[1].body) as List<dynamic>;

        setState(() {
          _recorrencias = recorrenciasJson
              .map((e) => {'id': e['id'].toString(), 'nome': e['nome'] as String})
              .toList();
          _categorias = categoriasJson
              .map((e) => {'id': e['id'].toString(), 'nome': e['nome'] as String})
              .toList();
          _carregandoDadosFixos = false;
        });
      } else {
        throw Exception('Erro ao carregar dados fixos');
      }
    } catch (e) {
      setState(() => _carregandoDadosFixos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<void> _editarLimite() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await AuthService.obterToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final url = Uri.parse('http://localhost:8000/limite/${widget.limite['id']}');

    final response = await http.put(
      url,
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'titulo': _tituloController.text,
        'valor': double.tryParse(_valorController.text) ?? 0,
        'fk_id_recorrencia': int.tryParse(_recorrenciaSelecionada ?? '') ?? null,
        'fk_id_categoria_transacao': int.tryParse(_categoriaSelecionada ?? '') ?? null,
        'fk_id_usuario': widget.limite['fk_id_usuario'],
      }),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop(true); // Indica que atualizou para recarregar lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite atualizado com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar limite')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Para permitir blur
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(15),
          ),
          child: _carregandoDadosFixos
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Editar Limite',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  TextFormField(
                    controller: _tituloController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54)),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o título' : null,
                  ),
                  const SizedBox(height: 15),

                  // Valor
                  TextFormField(
                    controller: _valorController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe o valor';
                      if (double.tryParse(value) == null) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Dropdown Recorrência
                  DropdownButtonFormField<String>(
                    value: _recorrenciaSelecionada,
                    dropdownColor: Colors.grey[850],
                    decoration: const InputDecoration(
                      labelText: 'Recorrência',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54)),
                    ),
                    items: _recorrencias
                        .map((rec) => DropdownMenuItem<String>(
                      value: rec['id'],
                      child: Text(rec['nome'], style: const TextStyle(color: Colors.white)),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _recorrenciaSelecionada = val;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Selecione a recorrência' : null,
                  ),
                  const SizedBox(height: 15),

                  // Dropdown Categoria
                  DropdownButtonFormField<String>(
                    value: _categoriaSelecionada,
                    dropdownColor: Colors.grey[850],
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54)),
                    ),
                    items: _categorias
                        .map((cat) => DropdownMenuItem<String>(
                      value: cat['id'],
                      child: Text(cat['nome'], style: const TextStyle(color: Colors.white)),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _categoriaSelecionada = val;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Selecione a categoria' : null,
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: _editarLimite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                    child: const Text('Salvar Alterações'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
