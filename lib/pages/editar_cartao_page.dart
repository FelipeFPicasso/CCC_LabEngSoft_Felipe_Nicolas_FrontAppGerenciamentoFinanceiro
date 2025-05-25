import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditarCartaoPage extends StatefulWidget {
  final String token;
  final int cartaoId;

  const EditarCartaoPage({
    Key? key,
    required this.token,
    required this.cartaoId,
  }) : super(key: key);

  @override
  State<EditarCartaoPage> createState() => _EditarCartaoPageState();
}

class _EditarCartaoPageState extends State<EditarCartaoPage> {
  final _formKey = GlobalKey<FormState>();
  final _limiteController = TextEditingController();
  final _vencFaturaController = TextEditingController();

  List<Map<String, dynamic>> _contas = [];
  int? _contaSelecionada;
  bool _isLoading = false;
  bool _isLoadingCartao = true;

  static const String baseUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _buscarContas();
    _carregarDadosCartao();
  }

  Future<void> _buscarContas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contas/usuario'),
        headers: {
          'Authorization': widget.token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> dados = jsonDecode(response.body);
        final List<dynamic> listaContas = dados['contas'];

        setState(() {
          _contas = listaContas.map((c) => Map<String, dynamic>.from(c)).toList();
          if (_contas.isNotEmpty && _contaSelecionada == null) {
            _contaSelecionada = _contas[0]['id'];
          }
        });
      } else {
        throw Exception('Erro ao carregar contas: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar contas: $e')),
      );
    }
  }

  Future<void> _carregarDadosCartao() async {
    setState(() => _isLoadingCartao = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cartoes/${widget.cartaoId}'),
        headers: {
          'Authorization': widget.token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> cartao = jsonDecode(response.body);

        setState(() {
          _limiteController.text = cartao['limite'].toString();
          _vencFaturaController.text = cartao['venc_fatura'] ?? '';
          _contaSelecionada = cartao['fk_id_conta'];
        });
      } else {
        throw Exception('Erro ao carregar dados do cartão: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do cartão: $e')),
      );
    } finally {
      setState(() => _isLoadingCartao = false);
    }
  }

  Future<void> _editarCartao() async {
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
      final response = await http.put(
        Uri.parse('$baseUrl/cartoes'),
        headers: {
          'Authorization': widget.token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': widget.cartaoId,
          'limite': limite,
          'venc_fatura': vencFatura,
          'fk_id_conta': _contaSelecionada,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cartão atualizado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Erro do servidor: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar cartão: $e')),
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
        title: const Text('Editar Cartão', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingCartao
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Conta'),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                items: _contas.map((conta) {
                  return DropdownMenuItem<int>(
                    value: conta['id'],
                    child: Text(conta['nome_banco'] ?? 'Conta sem nome',
                        style: const TextStyle(color: Colors.white)),
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
                decoration: const InputDecoration(
                    labelText: 'Limite',
                    labelStyle: TextStyle(color: Colors.white)),
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
                decoration: const InputDecoration(
                    labelText: 'Vencimento da Fatura (DD/MM/AAAA)',
                    labelStyle: TextStyle(color: Colors.white)),
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
                  onPressed: _editarCartao,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Salvar Alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}