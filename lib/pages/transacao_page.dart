import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_services.dart';
import 'adicionar_transacao_page.dart';
// Importa o ComprovanteDialog que criamos
import 'relatorio_transacao_page.dart'; // Aqui só se precisar de algo mais

class TransacaoPage extends StatefulWidget {
  static const String baseUrl = 'http://localhost:8000';

  const TransacaoPage({super.key});

  @override
  _TransacaoPageState createState() => _TransacaoPageState();
}

class _TransacaoPageState extends State<TransacaoPage> {
  bool _loading = true;
  List<dynamic> _transacoes = [];
  List<dynamic> _transacoesFiltradas = [];
  String _filtro = '';
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarTransacoes();
  }

  Future<void> _carregarTransacoes() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final token = await AuthService.obterToken();
      if (token == null) {
        setState(() {
          _erro = 'Usuário não autenticado.';
          _loading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${TransacaoPage.baseUrl}/relatorio-transacao/usuario'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _transacoes = jsonResponse['relatorios'];
          _transacoesFiltradas = _transacoes;
          _loading = false;
        });
      } else {
        setState(() {
          _erro = 'Erro ao carregar transações: ${response.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao conectar ao servidor: $e';
        _loading = false;
      });
    }
  }

  void _filtrarTransacoes(String filtro) {
    setState(() {
      _filtro = filtro.toLowerCase();
      _transacoesFiltradas = _transacoes.where((transacao) {
        final nomeBanco = (transacao['nome_conta'] ?? '').toString().toLowerCase();
        return nomeBanco.contains(_filtro);
      }).toList();
    });
  }

  void _confirmarExclusao(int idTransacao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
        content: Text('Tem certeza que deseja excluir esta transação?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(color: Colors.blueAccent)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Excluir', style: TextStyle(color: Colors.redAccent)),
            onPressed: () async {
              Navigator.pop(context);
              await _excluirTransacao(idTransacao);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _excluirTransacao(int idTransacao) async {
    try {
      final token = await AuthService.obterToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário não autenticado')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('${TransacaoPage.baseUrl}/transacao/$idTransacao'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transação excluída com sucesso!')),
        );
        _carregarTransacoes();
      } else {
        final erro = jsonDecode(response.body)['erro'] ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $erro')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  Widget _buildLista() {
    if (_transacoesFiltradas.isEmpty) {
      return Center(
        child: Text('Nenhuma transação encontrada.', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.separated(
      itemCount: _transacoesFiltradas.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[700]),
      itemBuilder: (context, index) {
        final transacao = _transacoesFiltradas[index];
        return ListTile(
          title: Text(transacao['descricao'] ?? 'Sem descrição', style: TextStyle(color: Colors.white)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Valor: R\$ ${transacao['valor'].toString()}', style: TextStyle(color: Colors.white70)),
              Text('Banco: ${transacao['nome_conta'] ?? 'Desconhecido'}', style: TextStyle(color: Colors.white60)),
              Text('Tipo: ${transacao['tipo_transacao']}', style: TextStyle(color: Colors.white60)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.receipt_long, color: Colors.blueAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ComprovanteDialog(idTransacao: transacao['fk_id_transacao']),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _confirmarExclusao(transacao['fk_id_transacao']),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Transações', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: _filtrarTransacoes,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome do banco',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _erro != null
          ? Center(
        child: Text(_erro!, style: TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
      )
          : _buildLista(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdicionarTransacaoPage()),
          );
          if (resultado != null) {
            _carregarTransacoes();
          }
        },
      ),
    );
  }
}
