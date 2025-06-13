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

  String? tipoSelecionado;
  String? categoriaSelecionada;
  List<String> categorias = [];
  DateTime? dataInicio;
  DateTime? dataFim;
  bool carregandoCategorias = true;

  @override
  void initState() {
    super.initState();
    carregarCategorias();
  }

  Future<void> carregarCategorias() async {
    final token = await AuthService.obterToken();
    if (token == null) return;

    try {
      final resultado = await ApiService.obterCategorias(token: token);
      setState(() {
        categorias = resultado.map((cat) => cat['nome'].toString()).toList();
        carregandoCategorias = false;
      });
    } catch (e) {
      setState(() {
        categorias = [];
        carregandoCategorias = false;
      });
    }
  }
  Future<void> _selecionarData(BuildContext context, bool inicio) async {
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );
    if (dataSelecionada != null) {
      setState(() {
        if (inicio) {
          dataInicio = dataSelecionada;
        } else {
          dataFim = dataSelecionada;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: Colors.white);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Resumo de Transações'),
        backgroundColor: primaryColor,
        shadowColor: shadowColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: tipoSelecionado,
              dropdownColor: primaryColor,
              decoration: InputDecoration(
                filled: true,
                fillColor: primaryColor,
                labelText: 'Tipo',
                labelStyle: textStyle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Receita', 'Despesa'].map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo, style: textStyle),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  tipoSelecionado = valor;
                });
              },
            ),
            SizedBox(height: 12),
              carregandoCategorias
                  ? CircularProgressIndicator(color: Colors.white)
                  : DropdownButtonFormField<String>(
                value: categoriaSelecionada,
                dropdownColor: primaryColor,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: primaryColor,
                  labelText: 'Categoria',
                  labelStyle: textStyle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: categorias.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: textStyle),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    categoriaSelecionada = valor;
                  });
                },
              ),
            SizedBox(height: 12),
            // Datas
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selecionarData(context, true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        dataInicio == null
                            ? 'Data Início'
                            : DateFormat('dd/MM/yyyy').format(dataInicio!),
                        style: textStyle,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selecionarData(context, false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        dataFim == null
                            ? 'Data Fim'
                            : DateFormat('dd/MM/yyyy').format(dataFim!),
                        style: textStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Chamará a função para carregar os dados do relatório
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.filter_alt, color: Colors.white),
              label: Text('Aplicar Filtros', style: textStyle),
            ),
            SizedBox(height: 24),
            // Aqui virá a visualização dos resultados (cards, gráfico, etc.)
            Expanded(
              child: Center(
                child: Text(
                  'Resultados serão exibidos aqui...',
                  style: textStyle.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
