import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/services/auth_services.dart';
import 'dart:convert';

class AdicionarTransacaoPage extends StatefulWidget {
  const AdicionarTransacaoPage({super.key});

  @override
  _AdicionarTransacaoPageState createState() => _AdicionarTransacaoPageState();
}

class _AdicionarTransacaoPageState extends State<AdicionarTransacaoPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  String? _selectedBanco;
  int? _selectedCategoriaId;
  int? _selectedTipoId;

  List<String> bancos = [];
  List<Map<String, dynamic>> categorias = [];
  List<Map<String, dynamic>> tipos = [];

  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('dd/mm/yyyy').format(DateTime.now());
    _fetchBancos();
    _fetchCategorias();
    _fetchTipos();
  }

  Future<void> _fetchBancos() async {
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
          bancos = lista.map((e) => e['nome_banco'] as String).toList();
          if (bancos.isNotEmpty) _selectedBanco = bancos[0];
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
              .map((e) => {'id': e['id'] as int, 'nome': e['nome'] as String})
              .toList();

          if (categorias.isNotEmpty) _selectedCategoriaId = categorias[0]['id'];
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
              .map((e) => {'id': e['id'] as int, 'nome': e['nome'] as String})
              .toList();

          if (tipos.isNotEmpty) _selectedTipoId = tipos[0]['id'];
        });
      } else {
        print('Erro ao buscar tipos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar tipos: $e');
    }
  }

  Future<bool> _submit() async {
    if (!_formKey.currentState!.validate()) return false;

    try {
      final token = await AuthService.obterToken();

      final data = {
        'descricao': _descricaoController.text.trim(),
        'valor': double.tryParse(_valorController.text.trim()),
        'data': _dataController.text.trim(),
        'nome_banco': _selectedBanco,
        'nome_categoria':
        categorias.firstWhere((c) => c['id'] == _selectedCategoriaId)['nome'],
        'nome_tipo': tipos.firstWhere((t) => t['id'] == _selectedTipoId)['nome'],
      };

      final response = await http.post(
        Uri.parse('http://localhost:8000/transacao'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transação criada com sucesso!')),
        );
        Navigator.pop(context, true);  // Retorna true indicando sucesso
        return true;
      } else {
        final body = jsonDecode(response.body);
        final errorMsg = body['erro'] ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $errorMsg')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de rede ou servidor: $e')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[900],
      labelStyle: TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
          borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(8)),
      errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
          borderRadius: BorderRadius.circular(8)),
      focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
          borderRadius: BorderRadius.circular(8)),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Adicionar Transação',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descricaoController,
                decoration: inputDecoration.copyWith(labelText: 'Descrição'),
                style: TextStyle(color: Colors.white),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Informe a descrição'
                    : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _valorController,
                keyboardType:
                TextInputType.numberWithOptions(decimal: true),
                decoration: inputDecoration.copyWith(labelText: 'Valor'),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o valor';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _dataController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Data (DD/MM/AAAA)',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.white70),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate:
                        DateTime.tryParse(_dataController.text) ?? DateTime.now(),
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
                              ), dialogTheme: DialogThemeData(backgroundColor: Colors.grey[850]),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        _dataController.text =
                            DateFormat('dd/mm/yyyy').format(picked);
                      }
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) =>
                value == null || value.isEmpty ? 'Informe a data' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBanco,
                decoration: inputDecoration.copyWith(labelText: 'Conta (Banco)'),
                dropdownColor: Colors.grey[900],
                style: TextStyle(color: Colors.white),
                items: bancos
                    .map((banco) => DropdownMenuItem(
                  value: banco,
                  child: Text(banco),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBanco = val),
                validator: (value) =>
                value == null ? 'Selecione uma conta' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedCategoriaId,
                decoration: inputDecoration.copyWith(labelText: 'Categoria'),
                dropdownColor: Colors.grey[900],
                style: TextStyle(color: Colors.white),
                items: categorias
                    .map((cat) => DropdownMenuItem(
                  value: cat['id'] as int,
                  child: Text(cat['nome'] as String),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoriaId = val),
                validator: (value) =>
                value == null ? 'Selecione uma categoria' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedTipoId,
                decoration: inputDecoration.copyWith(labelText: 'Tipo'),
                dropdownColor: Colors.grey[900],
                style: TextStyle(color: Colors.white),
                items: tipos
                    .map((tipo) => DropdownMenuItem(
                  value: tipo['id'] as int,
                  child: Text(tipo['nome'] as String),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTipoId = val),
                validator: (value) =>
                value == null ? 'Selecione um tipo' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white, // texto branco
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
