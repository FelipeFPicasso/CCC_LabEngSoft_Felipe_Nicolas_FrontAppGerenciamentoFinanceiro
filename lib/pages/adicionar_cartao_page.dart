import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdicionarCartaoDialog extends StatefulWidget {
  final String token;
  final int usuarioId;

  const AdicionarCartaoDialog({
    Key? key,
    required this.token,
    required this.usuarioId,
  }) : super(key: key);

  @override
  State<AdicionarCartaoDialog> createState() => _AdicionarCartaoDialogState();
}

class _AdicionarCartaoDialogState extends State<AdicionarCartaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _limiteController = TextEditingController();
  final _vencFaturaController = TextEditingController();

  List<Map<String, dynamic>> _contas = [];
  int? _contaSelecionada;

  bool _isLoading = false;

  final Color _backgroundColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _textColor = Colors.white70;
  final Color _labelColor = Colors.white60;
  final Color _buttonColor = Colors.deepPurpleAccent;

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

  String _converterDataParaBackend(String dataBr) {
    final partes = dataBr.split('/');
    if (partes.length != 3) return dataBr;
    return '${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}';
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
        const SnackBar(content: Text('Data de vencimento deve estar no formato DD/MM/AAAA.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final vencFaturaBackend = _converterDataParaBackend(vencFatura);

    try {
      await ApiService.adicionarCartao(
        token: widget.token,
        limite: limite,
        vencFatura: vencFaturaBackend,
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _labelColor),
      filled: true,
      fillColor: _cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _buttonColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  void dispose() {
    _limiteController.dispose();
    _vencFaturaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 350,
          child: _isLoading
              ? const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adicionar Cartão',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: _inputDecoration('Conta'),
                    dropdownColor: _cardColor,
                    style: TextStyle(color: _textColor),
                    items: _contas.map((conta) {
                      return DropdownMenuItem<int>(
                        value: conta['id'],
                        child: Text(
                          conta['nome_conta'] ?? 'Conta sem nome',
                          style: TextStyle(color: _textColor),
                        ),
                      );
                    }).toList(),
                    value: _contaSelecionada,
                    onChanged: (int? novoValor) {
                      setState(() {
                        _contaSelecionada = novoValor;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Selecione uma conta' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _limiteController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: _textColor),
                    decoration: _inputDecoration('Limite'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o limite';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) ==
                          null) {
                        return 'Limite inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vencFaturaController,
                    keyboardType: TextInputType.datetime,
                    style: TextStyle(color: _textColor),
                    decoration: _inputDecoration('Vencimento da Fatura (DD/MM/AAAA)'),
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
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _adicionarCartao,
                      child: const Text('Salvar'),
                    ),
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
