import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdicionarCartaoPage extends StatefulWidget {
  final String token;
  final int usuarioId;

  const AdicionarCartaoPage({
    super.key,
    required this.token,
    required this.usuarioId,
  });

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

  @override
  void initState() {
    super.initState();
    _buscarContas();
  }

  Future<void> _buscarContas() async {
    try {
      final contas = await ApiService.listarContasUsuario(widget.token, widget.usuarioId.toString());
      setState(() {
        _contas = contas;
        if (_contas.isNotEmpty) {
          _contaSelecionada = _contas[0]['id'];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar contas: $e')),
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

    // Validação simples para formato dd/mm/yyyy
    final regexData = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regexData.hasMatch(vencFatura)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data de vencimento deve estar no formato DD/MM/AAAA.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ApiService.adicionarCartao(
        token: widget.token,
        limite: limite,
        vencFatura: vencFatura,
        idConta: _contaSelecionada!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cartão adicionado com sucesso!')),
      );

      Navigator.of(context).pop(true);
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
      appBar: AppBar(
        title: const Text('Adicionar Cartão'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Conta'),
                items: _contas.map((conta) {
                  return DropdownMenuItem<int>(
                    value: conta['id'],
                    child: Text(conta['nome_conta'] ?? 'Conta sem nome'),
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
                decoration: const InputDecoration(labelText: 'Limite'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o limite';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Limite inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vencFaturaController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(labelText: 'Vencimento da Fatura (DD/MM/AAAA)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o vencimento';
                  }
                  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                    return 'Formato inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _adicionarCartao,
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
