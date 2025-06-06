import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/auth_services.dart';
import '../services/api_service.dart';

class RelatorioTransacoesPage extends StatefulWidget {
  @override
  _RelatorioTransacoesPageState createState() => _RelatorioTransacoesPageState();
}

class _RelatorioTransacoesPageState extends State<RelatorioTransacoesPage> {
  static const Color primaryColor = Color.fromARGB(255, 65, 65, 65);
  static const Color backgroundColor = Colors.black87;
  static const Color shadowColor = Color(0x22000000);

  bool carregando = true;
  String? erro;
  List<dynamic> dadosRelatorio = [];

  @override
  void initState() {
    super.initState();
    carregarRelatorio();
  }

  Future<void> carregarRelatorio() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    final token = await AuthService.obterToken();
    if (token == null) {
      setState(() {
        erro = 'Usuário não autenticado. Faça login novamente.';
        carregando = false;
      });
      return;
    }

    try {
      final resposta = await ApiService.obterRelatorioTransacoes(token);
      if (!mounted) return;
      setState(() {
        dadosRelatorio = resposta;
        carregando = false;
      });
    } catch (e) {
      setState(() {
        erro = 'Erro ao carregar relatório: $e';
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Relatório de Transações'),
        backgroundColor: primaryColor,
        shadowColor: shadowColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: carregando
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : erro != null
            ? Center(child: Text(erro!, style: TextStyle(color: Colors.red)))
            : ListView.builder(
          itemCount: dadosRelatorio.length,
          itemBuilder: (_, index) {
            final item = dadosRelatorio[index];
            return Card(
              color: primaryColor,
              shadowColor: shadowColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['categoria'] ?? 'Sem categoria',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Total: R\$ ${item['total'].toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.refresh),
        onPressed: carregarRelatorio,
      ),
    );
  }
}
