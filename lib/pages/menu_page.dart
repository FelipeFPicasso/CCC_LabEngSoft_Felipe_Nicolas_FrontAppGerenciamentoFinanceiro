import 'package:flutter/material.dart';
import 'package:untitled/pages/transacao_page.dart';
import '../services/auth_services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  double saldoTotal = 0.0;
  bool carregandoSaldo = true;

  @override
  void initState() {
    super.initState();
    _buscarSaldoTotal();
  }

  Future<void> _buscarSaldoTotal() async {
    try {
      String? token = await AuthService.obterToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:8000/saldo_total/usuarios'),
        headers: {
          'Authorization': '$token',  // corrigido aqui
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          saldoTotal = double.parse(data['saldo_total'] ?? '0'); // corrigido aqui
          carregandoSaldo = false;
        });
      } else {
        setState(() {
          saldoTotal = 0.0;
          carregandoSaldo = false;
        });
      }
    } catch (e) {
      setState(() {
        saldoTotal = 0.0;
        carregandoSaldo = false;
      });
      print('Erro ao buscar saldo total: $e');
    }
  }

  Future<void> _logout() async {
    await AuthService.removerToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  String formatarSaldo(double valor) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatador.format(valor);
  }

  Widget _buildMenuButton(BuildContext context, String texto, VoidCallback onPressed) {
    return Container(
      width: 220,  // tamanho maior
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          minimumSize: const Size(220, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Menu Principal'),
        backgroundColor: Colors.white12,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.blue[600], size: 30),
        titleTextStyle: TextStyle(
          color: Colors.blue[600],
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blue, size: 30),
            tooltip: 'Deslogar',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            carregandoSaldo
                ? const CircularProgressIndicator(color: Colors.blue)
                : Text(
              'Saldo Total: ${formatarSaldo(saldoTotal)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[300],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuButton(context, 'Transações', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TransacaoPage()),
                        );
                      }),
                      const SizedBox(width: 14),
                      _buildMenuButton(context, 'Limite', () {
                        Navigator.pushNamed(context, '/limite');
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuButton(context, 'Contas', () {
                        Navigator.pushNamed(context, '/contas');
                      }),
                      const SizedBox(width: 14),
                      _buildMenuButton(context, 'Cartões', () {
                        Navigator.pushNamed(context, '/cartoes');
                      }),
                    ],
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
