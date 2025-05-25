import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_services.dart';

class LimitePage extends StatefulWidget {
  const LimitePage({super.key});

  @override
  State<LimitePage> createState() => _LimitePageState();
}

class _LimitePageState extends State<LimitePage> {
  List<Map<String, dynamic>> _limites = [];

  Future<void> _carregarLimitesDoUsuario() async {
    final token = await AuthService.obterToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final url = Uri.parse('http://localhost:8000/limite/usuario');

    final response = await http.get(
      url,
      headers: {
        'Authorization': '$token',  // <-- aqui o Bearer antes do token
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _limites = List<Map<String, dynamic>>.from(data['limites']);
      });
    } else if (response.statusCode == 404) {
      setState(() {
        _limites = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum limite encontrado para o usuário')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar limites')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarLimitesDoUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Meus Limites'),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _limites.isEmpty
            ? Center(
          child: Text(
            'Nenhum limite encontrado.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        )
            : ListView(
          children: [
            Text(
              'Limites cadastrados:',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            ..._limites.map((limite) {
              return Card(
                color: Colors.grey[850],
                child: ListTile(
                  title: Text(
                    limite['titulo'],
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'R\$ ${limite['valor']}',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}