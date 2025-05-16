import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';

class ContaDetalhesPage extends StatefulWidget {
  final int contaId;
  final String nomeBanco;

  const ContaDetalhesPage({Key? key, required this.contaId, required this.nomeBanco}) : super(key: key);

  @override
  _ContaDetalhesPageState createState() => _ContaDetalhesPageState();
}

class _ContaDetalhesPageState extends State<ContaDetalhesPage> {
  double? _saldoAtual;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarSaldoAtual();
  }

  /// Obtém o saldo atual da conta via API
  Future<void> _carregarSaldoAtual() async {
    try {
      final token = await AuthService.obterToken();
      if (token == null) {
        setState(() {
          _erro = 'Usuário não autenticado.';
          _carregando = false;
        });
        return;
      }

      final saldo = await ApiService.obterSaldoAtualConta(token, widget.contaId);
      setState(() {
        _saldoAtual = saldo;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar saldo.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      appBar: AppBar(
        title: const Text('Detalhes da Conta'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _carregando
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _erro != null
            ? Center(
          child: Text(
            _erro!,
            style: TextStyle(color: Colors.red[300], fontSize: 18),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banco:',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.nomeBanco,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Saldo Atual:',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${_saldoAtual?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent[400],
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
