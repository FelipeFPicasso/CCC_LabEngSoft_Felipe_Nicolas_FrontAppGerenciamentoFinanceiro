import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Método para realizar o logout e redirecionar ao login
  Future<void> _logout() async {
    await AuthService.removerToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Estilo padrão para os botões do menu
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue[800],
      elevation: 4,
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      appBar: AppBar(
        title: const Text('Menu Principal'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Deslogar',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: _buttonStyle(),
              onPressed: () => Navigator.pushNamed(context, '/transacoes'),
              child: const Text('Transações'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: _buttonStyle(),
              onPressed: () => Navigator.pushNamed(context, '/limite'),
              child: const Text('Limite'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: _buttonStyle(),
              onPressed: () => Navigator.pushNamed(context, '/contas'),
              child: const Text('Contas'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: _buttonStyle(),
              onPressed: () => Navigator.pushNamed(context, '/cartoes'),
              child: const Text('Cartões'),
            ),
          ],
        ),
      ),
    );
  }
}
