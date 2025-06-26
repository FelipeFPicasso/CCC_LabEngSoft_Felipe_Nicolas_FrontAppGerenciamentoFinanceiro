import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdicionarCartaoPage extends StatefulWidget {
  final String token;
  final int usuarioId;

  const AdicionarCartaoPage({
    Key? key,
    required this.token,
    required this.usuarioId,
  }) : super(key: key);

  @override
  State<AdicionarCartaoPage> createState() => _AdicionarCartaoPageState();
}

class _AdicionarCartaoPageState extends State<AdicionarCartaoPage> {
  final _formKey = GlobalKey<FormState>();
  final _limiteController = TextEditingController();
  final _vencFaturaController = TextEditingController();

  List<Map<String, dynamic>> _contas = [];
  int? _contaSelecionada;
  bool _isLoading = false;

  late String token;
  late int usuarioId;

  static const String baseUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    token = widget.token;
    usuarioId = widget.usuarioId;
    _buscarContas();
  }

  Future<void> _buscarContas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contas/usuario'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );

      print('Resposta da API contas: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> dados = jsonDecode(response.body);

        if (!dados.containsKey('contas') || dados['contas'] == null) {
          throw Exception('Resposta inválida: chave "contas" ausente.');
        }

        final List<dynamic> listaContas = dados['contas'];

        setState(() {
          _contas = listaContas.map((c) => Map<String, dynamic>.from(c)).toList();
          if (_contas.isNotEmpty) {
            _contaSelecionada = _contas[0]['id'];
          }
        });
      } else {
        throw Exception('Erro ao carregar contas: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar contas: $e')),
      );
    }
  }

  Future<void> _adicionarCartao() async {
    if (!_formKey.currentState!.validate() || _contaSelecionada == null) return;

    setState(() => _isLoading = true);

    final limite = double.tryParse(_limiteController.text.replaceAll(',', '.'));
    final vencFatura = _vencFaturaController.text.trim();

    if (limite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite inválido.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final regexData = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regexData.hasMatch(vencFatura)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data deve estar no formato DD/MM/AAAA.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cartoes'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'limite': limite,
          'venc_fatura': vencFatura,
          'fk_id_conta': _contaSelecionada,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cartão adicionado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Erro do servidor: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar cartão: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Adicionar Cartão', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Conta',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[900],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                items: _contas.map((conta) {
                  return DropdownMenuItem<int>(
                    value: conta['id'],
                    child: Text(
                      conta['nome_banco'] ?? 'Conta sem nome',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                value: _contaSelecionada,
                onChanged: (int? novoValor) {
                  setState(() {
                    _contaSelecionada = novoValor;
                  });
                },
                validator: (value) => value == null ? 'Selecione uma conta' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limiteController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Limite',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[900],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe o limite';
                  if (double.tryParse(value.replaceAll(',', '.')) == null)
                    return 'Limite inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vencFaturaController,
                keyboardType: TextInputType.datetime,
                style: const TextStyle(color: Colors.white),
                readOnly: true,
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.blueAccent,
                            onPrimary: Colors.grey,
                            surface: Colors.black,
                            onSurface: Colors.grey,
                          ),
                          dialogBackgroundColor: Colors.grey[900], // <- aqui é o fundo da caixa de diálogo
                          scaffoldBackgroundColor: Colors.grey[900], // <- e aqui é o fundo geral do calendário
                          textTheme: const TextTheme(
                            bodyMedium: TextStyle(color: Colors.white),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    final String formatted = '${pickedDate.day.toString().padLeft(2, '0')}/'
                        '${pickedDate.month.toString().padLeft(2, '0')}/'
                        '${pickedDate.year}';
                    setState(() {
                      _vencFaturaController.text = formatted;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Vencimento da Fatura (DD/MM/AAAA)',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[900],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Informe o vencimento';
                  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value))
                    return 'Formato inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _adicionarCartao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
