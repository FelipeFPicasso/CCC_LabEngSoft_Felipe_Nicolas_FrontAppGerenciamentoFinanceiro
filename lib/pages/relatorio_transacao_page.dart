import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_services.dart';

class ComprovantePage extends StatefulWidget {
  final int idTransacao;

  const ComprovantePage({super.key, required this.idTransacao});

  @override
  _ComprovantePageState createState() => _ComprovantePageState();
}

class _ComprovantePageState extends State<ComprovantePage> {
  Map<String, dynamic>? _relatorio;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final token = await AuthService.obterToken();
      final response = await http.get(
        Uri.parse('http://localhost:8000/relatorio_transacao/transacao/${widget.idTransacao}'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _relatorio = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _erro = 'Erro ao buscar relatório: ${response.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao conectar: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Comprovante', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _erro != null
          ? Center(
        child: Text(_erro!, style: TextStyle(color: Colors.redAccent)),
      )
          : _relatorio != null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _info("Descrição", _relatorio!['descricao']),
            _info("Valor", "R\$ ${_relatorio!['valor']}"),
            _info("Data", _relatorio!['data']),
            _info("Usuário", _relatorio!['nome_usuario']),
            _info("Tipo", _relatorio!['tipo_transacao']),
            _info("Banco", _relatorio!['nome_conta']),
            _info("Categoria", _relatorio!['nome_categoria']),
          ],
        ),
      )
          : Center(child: Text("Relatório não encontrado", style: TextStyle(color: Colors.white))),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        "$label: $value",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
