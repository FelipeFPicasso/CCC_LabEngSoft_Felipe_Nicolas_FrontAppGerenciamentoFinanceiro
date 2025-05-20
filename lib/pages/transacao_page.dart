import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:untitled/pages/adicionar_transacao_page.dart';
import '../services/auth_services.dart';
import 'package:http/http.dart' as http;

class TransacaoPage extends StatefulWidget {
  static const String baseUrl = 'http://localhost:8000';
  @override
  _TransacaoPageState createState() => _TransacaoPageState();
}

class _TransacaoPageState extends State<TransacaoPage> {
  bool _loading = true;
  List<dynamic> _transacoes = [];
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
        Uri.parse('http://localhost:8000/transacao/usuario'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _transacoes = jsonResponse['transacoes'];
          _loading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _transacoes = [];
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _erro = 'Sessão expirada. Faça login novamente.';
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

  Widget _buildLista() {
    if (_transacoes.isEmpty) {
      return Center(
          child: Text(
            'Nenhuma transação encontrada.',
            style: TextStyle(color: Colors.white70),
          ));
    }
    return ListView.separated(
      itemCount: _transacoes.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[700]),
      itemBuilder: (context, index) {
        final transacao = _transacoes[index];
        return ListTile(
          title: Text(
            transacao['descricao'] ?? 'Sem descrição',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Valor: R\$ ${transacao['valor'].toString()}',
            style: TextStyle(color: Colors.white70),
          ),
          trailing: Text(
            transacao['data'] ?? '',
            style: TextStyle(color: Colors.white54),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // fundo preto
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // cinza escuro
        title: Text(
          'Transações',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white), // ícones brancos
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _erro != null
          ? Center(
          child: Text(
            _erro!,
            style: TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ))
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
