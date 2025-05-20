import 'package:flutter/material.dart';
import 'package:untitled/pages/transacao_page.dart';
import '../services/auth_services.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  Future<void> _logout() async {
    await AuthService.removerToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 2,
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      shadowColor: Colors.black,
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (states) {
          if (states.contains(MaterialState.pressed)) {
            return Colors.blue[800];
          } else if (states.contains(MaterialState.hovered)) {
            return Colors.blue[700];
          }
          return null;
        },
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: _buttonStyle(),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TransacaoPage()),
              ),
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
