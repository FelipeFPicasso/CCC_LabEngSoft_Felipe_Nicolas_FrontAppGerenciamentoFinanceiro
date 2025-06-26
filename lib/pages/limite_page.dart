import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/pages/editar_limite_page.dart';
import '../services/auth_services.dart';

class LimitePage extends StatefulWidget {
  const LimitePage({super.key});

  @override
  State<LimitePage> createState() => _LimitePageState();
}

class _LimitePageState extends State<LimitePage> {
  List<Map<String, dynamic>> _limites = [];
  List<Map<String, dynamic>> _limitesFiltrados = [];
  String _textoPesquisa = '';

  Future<void> _carregarLimitesDoUsuario() async {
    final token = await AuthService.obterToken();

    if (token == null) {
      if (!mounted) return;
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

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        _limites = List<Map<String, dynamic>>.from(data['limites']);
        _filtrarLimites(_textoPesquisa);
      });
    } else if (response.statusCode == 404) {
      if (!mounted) return;
      setState(() {
        _limites = [];
        _limitesFiltrados = [];
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

  void _filtrarLimites(String texto) {
    setState(() {
      _textoPesquisa = texto;
      if (texto.isEmpty) {
        _limitesFiltrados = List.from(_limites);
      } else {
        _limitesFiltrados = _limites.where((limite) {
          final titulo = limite['titulo']?.toLowerCase() ?? '';
          return titulo.contains(texto.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _excluirLimite(int idLimite) async {
    final token = await AuthService.obterToken();

    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final url = Uri.parse('http://localhost:8000/limite/$idLimite');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite excluído com sucesso')),
      );
      await _carregarLimitesDoUsuario();
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
        child: Column(
          children: [
            // Barra de pesquisa
            TextField(
              onChanged: _filtrarLimites,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar por título',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: Colors.grey[850],
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // Conteúdo da lista (filtrada)
            Expanded(
              child: _limitesFiltrados.isEmpty
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
                  ..._limitesFiltrados.map((limite) {
                    return Card(
                      color: Colors.grey[850],
                      child: ListTile(
                        title: Text(
                          limite['titulo'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'R\$ ${double.tryParse(limite['valor'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Categoria: ${limite['nome_categoria'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            Text(
                              'Recorrência: ${limite['nome_recorrencia'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final atualizado = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => EditarLimitePopup(limite: limite),
                                );

                                if (atualizado == true) {
                                  _carregarLimitesDoUsuario();
                                }
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
