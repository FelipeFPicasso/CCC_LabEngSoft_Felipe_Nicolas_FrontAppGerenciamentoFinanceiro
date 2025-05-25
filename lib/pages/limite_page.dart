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
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final url = Uri.parse('http://localhost:8000/limite/usuario');

    final response = await http.get(
      url,
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        // Assume que o backend retorna {"limites": [...]}
        _limites = List<Map<String, dynamic>>.from(data['limites']);
      });
    } else if (response.statusCode == 404) {
      setState(() {
        _limites = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum limite encontrado para o usuário')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar limites')),
      );
    }
  }

  Future<void> _excluirLimite(int idLimite) async {
    final token = await AuthService.obterToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final url = Uri.parse('http://localhost:8000/limite/$idLimite'); // DELETE

    final response = await http.delete(
      url,
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite excluído com sucesso')),
      );
      _carregarLimitesDoUsuario(); // Atualiza lista após exclusão
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir limite')),
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
        title: const Text('Meus Limites'),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _limites.isEmpty
            ? const Center(
          child: Text(
            'Nenhum limite encontrado.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        )
            : ListView(
          children: [
            const Text(
              'Limites cadastrados:',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ..._limites.map((limite) {
              return Card(
                color: Colors.grey[850],
                child: ListTile(
                  title: Text(
                    limite['titulo'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'R\$ ${limite['valor'] ?? '0.00'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/limite/editar',
                            arguments: limite,
                          ).then((_) => _carregarLimitesDoUsuario());
                        },
                        tooltip: 'Editar limite',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmar exclusão'),
                              content: const Text('Deseja realmente excluir esse limite?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Excluir',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            _excluirLimite(limite['id']);
                          }
                        },
                        tooltip: 'Excluir limite',
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/limite/adicionar')
              .then((_) => _carregarLimitesDoUsuario());
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.grey[900],
        tooltip: 'Adicionar limite',
      ),
    );
  }
}
