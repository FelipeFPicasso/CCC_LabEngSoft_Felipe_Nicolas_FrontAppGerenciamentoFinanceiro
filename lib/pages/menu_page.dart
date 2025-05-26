import 'package:flutter/material.dart';
import 'package:untitled/pages/transacao_page.dart';
import '../services/auth_services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'limite_page.dart';
import 'editar_usuario_page.dart'; // certifique-se de ter esse arquivo criado

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  double saldoTotal = 0.0;
  bool carregandoSaldo = true;

  String nomeUsuario = "Usuário";
  String emailUsuario = "";
  String dataNascUsuario = "";

  @override
  void initState() {
    super.initState();
    _buscarSaldoTotal();
    _buscarDadosUsuario();
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
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          saldoTotal = double.parse(data['saldo_total'] ?? '0');
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

  Future<void> _buscarDadosUsuario() async {
    final token = await AuthService.obterToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://localhost:8000/usuario'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        nomeUsuario = data['nome'] ?? 'Usuário';
        emailUsuario = data['email'] ?? '';
        dataNascUsuario = data['data_nasc'] ?? '';
      });
    } else {
      setState(() {
        nomeUsuario = 'Usuário';
        emailUsuario = '';
        dataNascUsuario = '';
      });
      debugPrint('Erro ao buscar dados do usuário: ${response.body}');
    }
  }

  Future<void> _logout() async {
    await AuthService.removerToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  String formatarSaldo(double valor) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: ' R\$');
    return formatador.format(valor);
  }

  Widget _buildMenuButton(BuildContext context, String texto, VoidCallback onPressed) {
    return Container(
      width: 220,
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

  static const Color primaryColor = Color.fromARGB(255, 46, 46, 46);
  static const Color backgroundColor = Colors.black87;
  static Color? cardColor = Colors.blue[600];

  void _abrirPopupEditarUsuario() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return Center(
          child: EditarUsuarioPopup(
            nomeAtual: nomeUsuario,
            emailAtual: emailUsuario,
            dataNascAtual: dataNascUsuario,
          ),
        );
      },
    );

    // Atualiza os dados do usuário após fechar o popup (se foi editado)
    _buscarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Menu Principal'),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: cardColor, size: 30),
        titleTextStyle: TextStyle(
          color: cardColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          TextButton(
            onPressed: _abrirPopupEditarUsuario,
            child: Text(
              nomeUsuario,
              style: const TextStyle(color: Colors.blue, fontSize: 18),
            ),
          ),
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
                color: Colors.blue[400],
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LimitePage()),
                        );
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