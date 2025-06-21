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
  List<String> categoriasSelecionadas = [];
  List<String> categorias = [];
  List<Map<String, dynamic>> relatorio = [];
  DateTime? dataInicio;
  DateTime? dataFim;
  bool carregandoCategorias = true;
  late String? token;


  @override
  void initState() {
    super.initState();
    carregarCategorias();
    carregarRelatorio();
  }

  bool filtrosAtivos() {
    return dataInicio != null ||
        dataFim != null ||
        tipoSelecionado != null ||
        categoriasSelecionadas.isNotEmpty;
  }

  Future<void> carregarRelatorio() async {
    try {
      if (filtrosAtivos()) {
        final resultado = await ApiService.obterRelatorioFiltrado(
          token!,
          dataInicio: dataInicio != null ? DateFormat('dd/MM/yyyy').format(dataInicio!) : null,
          dataFim: dataFim != null ? DateFormat('dd/MM/yyyy').format(dataFim!) : null,
          tipo: tipoSelecionado,
          categorias: categoriasSelecionadas,
        );
        setState(() {
          relatorio = resultado;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Relatório carregado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final resultado = await ApiService.obterResumoPorCategoria(token!);
        setState(() {
          relatorio = resultado;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar relatório!"),
          backgroundColor: Colors.green,
        ),

      );
    }
  }

  Future<void> carregarCategorias() async {
    final tempToken = await AuthService.obterToken();
    if (tempToken == null) return;

    token = tempToken;

    try {
      final resultado = await ApiService.obterCategorias(token!);
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

  Widget buildResumo() {
    double totalReceita = relatorio
        .where((item) => (item['total'] ?? 0) > 0)
        .fold(0.0, (sum, item) => sum + (item['total'] as num).toDouble());

    double totalDespesa = relatorio
        .where((item) => (item['total'] ?? 0) < 0)
        .fold(0.0, (sum, item) => sum + (item['total'] as num).toDouble());

    double saldo = totalReceita + totalDespesa;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildResumoCard('Receitas', totalReceita, Colors.green),
        buildResumoCard('Despesas', totalDespesa, Colors.red),
        buildResumoCard('Saldo', saldo, saldo >= 0 ? Colors.blue : Colors.red),
      ],
    );
  }

  Widget buildGraficoPizza() {
    if (relatorio.isEmpty) {
      return Center(
        child: Text('Sem dados para o gráfico.', style: TextStyle(color: Colors.white70)),
      );
    }

    double totalGeral = relatorio.fold(
      0.0, (sum, item) => sum + (item['total'].abs() as double),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              grafico(totalGeral),
              SizedBox(height: 16),
              legenda(totalGeral),
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: legenda(totalGeral),
              ),
              SizedBox(width: 50),
              Expanded(
                flex: 1,
                child: grafico(totalGeral),
              )
            ],
          ),
        );
      },
    );
  }

  Widget legenda(double totalGeral) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Categoria',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '%',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          ...relatorio.map((item) {
            final percentual = (item['total'].abs() / totalGeral) * 100;
            final color = getColorForCategory(item['categoria']);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['categoria'],
                            style: TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      'R\$ ${item['total'].abs().toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      '${percentual.toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget grafico(double totalGeral) {
    return SizedBox(
      width: 200,
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: relatorio.map((item) {
            final percentual = (item['total'].abs() / totalGeral) * 100;
            return PieChartSectionData(
              color: getColorForCategory(item['categoria']),
              value: item['total'].abs().toDouble(),
              title: '${percentual.toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }


  Color getColorForCategory(String categoria) {
    final cores = {
      'Alimentação': Colors.red,
      'Transporte': Colors.blue,
      'Lazer': Colors.green,
      'Investimento': Colors.orange,
      'Outros': Colors.purple,
    };
    return cores[categoria] ?? Colors.grey;
  }

  Widget buildResumoCard(String titulo, double valor, Color cor) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 4),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              color: cor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  //Style variables
  double borderValue = 8;
  final double containerHeight = 45;
  final double containerMinWidth = 180;
  final double containerMaxWidth = 220;
  final double borderRadiusValue = 12;
  final Color borderColor = Colors.white24;

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
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  width: 200,
                  padding: EdgeInsets.symmetric(
                      vertical: borderValue,
                      horizontal: borderValue
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                tipoSelecionado = tipoSelecionado == 'Receita'
                                    ? null : 'Receita';
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                color: tipoSelecionado == 'Receita'
                                    ? const Color(0xFF009933)
                                    : primaryColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: borderValue,
                                  horizontal: borderValue
                              ),
                              child: const Text(
                                'Receita',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                tipoSelecionado = tipoSelecionado == 'Despesa'
                                    ? null : 'Despesa';
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                color: tipoSelecionado == 'Despesa'
                                    ? const Color(0xffcc0000)
                                    : primaryColor,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: borderValue,
                                  horizontal: borderValue
                              ),
                              child: const Text(
                                'Despesa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão Selecionar Categorias
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          List<String> tempSelecionadas = List.from(categoriasSelecionadas);
                          return StatefulBuilder(
                            builder: (context, setStateDialog) {
                              return AlertDialog(
                                backgroundColor: primaryColor,
                                title: Text('Selecione as categorias', style: TextStyle(color: Colors.white)),
                                content: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: categorias.map((cat) {
                                      final selecionado = tempSelecionadas.contains(cat);
                                      return MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            setStateDialog(() {
                                              if (selecionado) {
                                                tempSelecionadas.remove(cat);
                                              } else {
                                                tempSelecionadas.add(cat);
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: selecionado ? Colors.blue : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.white24),
                                            ),
                                            child: Text(
                                              cat,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('Cancelar', style: TextStyle(color: Colors.white70)),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    child: Text('Aplicar'),
                                    onPressed: () {
                                      setState(() {
                                        categoriasSelecionadas = List.from(tempSelecionadas);
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      constraints: BoxConstraints(minWidth: 180, maxWidth: 300),
                      padding: EdgeInsets.all(borderValue),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(borderValue),
                        border: Border.all(color: Colors.white24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        categoriasSelecionadas.isEmpty
                            ? 'Selecionar Categorias'
                            : 'Categorias: ${categoriasSelecionadas.join(', ')}',
                        style: TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _selecionarData(context, true),
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(
                        vertical: borderValue,
                        horizontal: borderValue,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(borderValue),
                        border: Border.all(color: borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dataInicio == null
                            ? 'Data Início'
                            : DateFormat('dd/MM/yyyy').format(dataInicio!),
                        style: textStyle,
                      ),
                    ),
                  ),
                ),

                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child:GestureDetector(
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(
                          vertical: borderValue,
                          horizontal: borderValue
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(borderValue),
                        border: Border.all(color: borderColor),
                      ),
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => _selecionarData(context, false),
                        child: Text(
                          dataFim == null
                              ? 'Data Fim'
                              : DateFormat('dd/MM/yyyy').format(dataFim!),
                          style: textStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 180,
                maxWidth: 300,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  carregarRelatorio();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderValue),
                  ),
                ),
                icon: Icon(Icons.filter_alt, color: Colors.white),
                label: Text('Aplicar Filtros', style: textStyle),
              ),
            ),
            SizedBox(height: 16),
            buildResumo(),
            SizedBox(height: 16),
            buildGraficoPizza(),
            SizedBox(height: 24),
            Expanded(
              child: relatorio.isEmpty
                  ? Center(
                child: Text(
                  'Nenhum dado encontrado.',
                  style: textStyle.copyWith(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: relatorio.length,
                itemBuilder: (context, index) {
                  final item = relatorio[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['categoria'] ?? 'Sem categoria',
                          style: textStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Total: R\$ ${item['total'].toString()}',
                          style: textStyle,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
