import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/services/auth_services.dart';

class EditarTransacaoPage extends StatefulWidget {
  final Map<String, dynamic> transacao;

  const EditarTransacaoPage({Key? key, required this.transacao}) : super(key: key);

  @override
  _EditarTransacaoPageState createState() => _EditarTransacaoPageState();
}

class _EditarTransacaoPageState extends State<EditarTransacaoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descricaoController;
  late TextEditingController _valorController;
  late TextEditingController _dataController;

  int? _selectedContaId;
  int? _selectedCategoriaId;
  int? _selectedTipoId;

  List<Map<String, dynamic>> contas = [];
  List<Map<String, dynamic>> categorias = [];
  List<Map<String, dynamic>> tipos = [];

  final InputDecoration inputDecoration = InputDecoration(
    border: OutlineInputBorder(),
    labelStyle: TextStyle(color: Colors.white70),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white38),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blueAccent),
    ),
  );

  @override
  void initState() {
    super.initState();

    _descricaoController = TextEditingController(text: widget.transacao['descricao']);
    _valorController = TextEditingController(text: widget.transacao['valor'].toString());
    _dataController = TextEditingController(text: widget.transacao['data']);


    _selectedContaId = widget.transacao['fk_id_conta'];
    _selectedCategoriaId = widget.transacao['fk_id_categoria_transacao'];
    _selectedTipoId = widget.transacao['fk_id_tipo_transacao'];

    _fetchContas();
    _fetchCategorias();
    _fetchTipos();
  }

  Future<void> _fetchContas() async {
    try {
      final token = await AuthService.obterToken();
      final response = await http.get(
        Uri.parse('http://localhost:8000/contas/usuario'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> lista = jsonDecode(response.body)['contas'];
        setState(() {
          contas = lista
              .map((e) => {
            'id': e['id'] as int,
            'nome_banco': e['nome_banco'] as String,
          })
              .toList();

          if (_selectedContaId == null ||
              !contas.any((c) => c['id'] == _selectedContaId)) {
            _selectedContaId = contas.isNotEmpty ? contas[0]['id'] : null;
          }
        });
      } else {
        print('Erro ao buscar contas: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar contas: $e');
    }
  }

  Future<void> _fetchCategorias() async {
    try {
      final token = await AuthService.obterToken();
      final response = await http.get(
        Uri.parse('http://localhost:8000/categorias-transacao'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> lista = jsonDecode(response.body);
        setState(() {
          categorias = lista
              .map((e) => {
            'id': e['id'] as int,
            'nome': e['nome'] as String,
          })
              .toList();

          if (_selectedCategoriaId == null ||
              !categorias.any((c) => c['id'] == _selectedCategoriaId)) {
            _selectedCategoriaId = categorias.isNotEmpty ? categorias[0]['id'] : null;
          }
        });
      } else {
        print('Erro ao buscar categorias: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar categorias: $e');
    }
  }

  Future<void> _fetchTipos() async {
    try {
      final token = await AuthService.obterToken();
      final response = await http.get(
        Uri.parse('http://localhost:8000/tipos-transacao'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> lista = jsonDecode(response.body);
        setState(() {
          tipos = lista
              .map((e) => {
            'id': e['id'] as int,
            'nome': e['nome'] as String,
          })
              .toList();

          if (_selectedTipoId == null ||
              !tipos.any((t) => t['id'] == _selectedTipoId)) {
            _selectedTipoId = tipos.isNotEmpty ? tipos[0]['id'] : null;
          }
        });
      } else {
        print('Erro ao buscar tipos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar tipos: $e');
    }
  }

  Future<void> _excluirTransacao(int idTransacao) async {
    try {
      final token = await AuthService.obterToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário não autenticado')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('http://localhost:8000/transacao/$idTransacao'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transação excluída com sucesso!')),
        );
        Navigator.pop(context, true);
      } else {
        final erro = jsonDecode(response.body)['erro'] ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $erro')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  Future<void> _salvarTransacao() async {
    if (!_formKey.currentState!.validate()) return;

    final idTransacao = widget.transacao['id'];
    if (idTransacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: id da transação inválido.')),
      );
      return;
    }

    final token = await AuthService.obterToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final dados = {
      "descricao": _descricaoController.text.trim(),
      "valor": double.parse(_valorController.text.trim()),
      "data": _dataController.text.trim(),
      "fk_id_conta": _selectedContaId,
      "fk_id_categoria_transacao": _selectedCategoriaId,
      "fk_id_tipo_transacao": _selectedTipoId,
    };

    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/transacao/$idTransacao'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dados),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dados atualizados com sucesso!')),
        );
        Navigator.pop(context, true);
      } else {
        final erro = jsonDecode(response.body)['erro'] ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $erro')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Editar Transação'),
        backgroundColor: Colors.grey[850],
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Confirmar'),
                  content: Text('Deseja realmente excluir esta transação?'),
                  actions: [
                    TextButton(
                      child: Text('Cancelar'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text('Deletar'),
                      onPressed: () {
                        Navigator.pop(context);
                        final idTransacao = widget.transacao['id'];
                        if (idTransacao == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro: id da transação inválido.')));
                          return;
                        }
                        _excluirTransacao(idTransacao);
                      },
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: contas.isEmpty ||
            categorias.isEmpty ||
            tipos.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descricaoController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Descrição',
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Informe a descrição';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Valor',
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Informe o valor';
                  }
                  final v = double.tryParse(value.trim());
                  if (v == null) {
                    return 'Valor inválido';
                  }
                  if (v <= 0) {
                    return 'Valor deve ser maior que zero';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _dataController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Data (AAAA-MM-DD)',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today,
                        color: Colors.white70),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(
                            _dataController.text) ??
                            DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Colors.blueAccent,
                                onPrimary: Colors.white,
                                surface: Colors.grey[900]!,
                                onSurface: Colors.white70,
                              ),
                              dialogTheme: DialogThemeData(
                                backgroundColor: Colors.grey[850],
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        _dataController.text = DateFormat('yyyy-MM-dd').format(picked);
                      }
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Informe a data';
                  }
                  try {
                    DateTime.parse(value.trim());
                  } catch (_) {
                    return 'Data inválida';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedContaId,
                decoration: inputDecoration.copyWith(
                  labelText: 'Conta (Banco)',
                ),
                style: TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[900],
                items: contas
                    .map((conta) =>
                    DropdownMenuItem<int>(
                      value: conta['id'] as int,
                      child: Text(conta['nome_banco'] as String),
                    ),
                )
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedContaId = val),
                validator: (value) {
                  if (value == null) {
                    return 'Selecione uma conta';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoriaId,
                decoration: inputDecoration.copyWith(
                  labelText: 'Categoria',
                ),
                style: TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[900],
                items: categorias
                    .map((cat) =>
                    DropdownMenuItem<int>(
                      value: cat['id'] as int,
                      child: Text(cat['nome'] as String),
                    ),
                )
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategoriaId = val),
                validator: (value) {
                  if (value == null) {
                    return 'Selecione uma categoria';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedTipoId,
                decoration: inputDecoration.copyWith(
                  labelText: 'Tipo',
                ),
                style: TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[900],
                items: tipos
                    .map((tipo) =>
                    DropdownMenuItem<int>(
                      value: tipo['id'] as int,
                      child: Text(tipo['nome'] as String),
                    ),
                )
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedTipoId = val),
                validator: (value) {
                  if (value == null) {
                    return 'Selecione um tipo';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarTransacao,
                child: Text('Salvar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

