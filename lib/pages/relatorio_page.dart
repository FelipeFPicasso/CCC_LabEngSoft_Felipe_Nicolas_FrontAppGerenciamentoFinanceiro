import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/auth_services.dart';
import '../services/api_service.dart';
import '../services/aux_calc.dart';
import 'dart:ui';

class RelatorioTransacoesPage extends StatefulWidget {
  @override
  _RelatorioTransacoesPageState createState() => _RelatorioTransacoesPageState();
}

class _RelatorioTransacoesPageState extends State<RelatorioTransacoesPage> {
  static const Color primaryColor = Color.fromARGB(255, 65, 65, 65);
  static const Color backgroundColor = Colors.black87;
  static const Color shadowColor = Color(0x22000000);

  DateTime? dataInicio;
  DateTime? dataFim;
  bool carregandoCategorias = true;
  String? tipoSelecionado;
  List<MapEntry<String, double>> saldoAcumulado = [];
  late String? token;
  List<String> categoriasSelecionadas = [];
  List<String> categorias = [];
  List<Map<String, dynamic>> relatorio = [];
  List<Map<String, dynamic>>? transacoesDetalhadas = [];
  List<Map<String, dynamic>> receitasPorMes = [];
  List<Map<String, dynamic>> despesasPorMes = [];

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
      final resultado = await ApiService.obterRelatorioFiltrado(
        token!,
        dataInicio: dataInicio != null ? DateFormat('dd/MM/yyyy').format(dataInicio!) : null,
        dataFim: dataFim != null ? DateFormat('dd/MM/yyyy').format(dataFim!) : null,
        tipo: tipoSelecionado,
        categorias: categoriasSelecionadas,
      );

      final detalhes = await ApiService.carregarTransacoesDetalhadas(
        token!,
        dataInicio: dataInicio != null ? DateFormat('dd/MM/yyyy').format(dataInicio!) : null,
        dataFim: dataFim != null ? DateFormat('dd/MM/yyyy').format(dataFim!) : null,
        tipo: tipoSelecionado,
        categorias: categoriasSelecionadas,
      );

      Map<String, double> receitasPorMes = agruparPorMes(detalhes, 'Receita');
      Map<String, double> despesasPorMes = agruparPorMes(detalhes, 'Despesa');

      Map<String, double> saldoPorMes = {};
      final meses = {...receitasPorMes.keys, ...despesasPorMes.keys};
      for (var mes in meses) {
        double r = receitasPorMes[mes] ?? 0;
        double d = despesasPorMes[mes] ?? 0;
        saldoPorMes[mes] = r - d;
      }

      final acumulado = calcularSaldoAcumulado(saldoPorMes);

      setState(() {
        relatorio = resultado;
        transacoesDetalhadas = detalhes;
        saldoAcumulado = acumulado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Relatório carregado com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar relatório!"),
          backgroundColor: Colors.red,
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

  String formatarData(String data) {
    try {
      final formatoEntrada = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US');
      final date = formatoEntrada.parseUtc(data);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return data;
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
        buildResumoCard('Saldo', saldo, saldo >= 0 ? Colors.green : Colors.red),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  Widget buildGraficoLinhaSaldo(List<MapEntry<String, double>> saldoAcumulado) {
    if (saldoAcumulado.isEmpty || saldoAcumulado.length < 2) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          'Dados insuficientes para gerar o gráfico',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        final spots = <FlSpot>[];
        double minY = saldoAcumulado.first.value;
        double maxY = saldoAcumulado.first.value;

        for (int i = 0; i < saldoAcumulado.length; i++) {
          final valor = saldoAcumulado[i].value;
          spots.add(FlSpot(i.toDouble(), valor));

          if (valor < minY) minY = valor;
          if (valor > maxY) maxY = valor;
        }

        final delta = (maxY - minY).abs() * 0.2;
        final minGraphY = (minY - delta).ceilToDouble();
        final maxGraphY = (maxY + delta).ceilToDouble();

        final saldoFinal = saldoAcumulado.last.value;
        final corLinha = saldoFinal >= 0 ? Colors.green : Colors.red;
        final corArea = (saldoFinal >= 0
            ? Colors.green
            : Colors.red)
            .withAlpha(130);

        return Container(
          height: 275,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.black.withAlpha(130),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      return LineTooltipItem(
                        'R\$ ${touchedSpot.y.toStringAsFixed(2)}',
                        TextStyle(
                          color: Colors.white,
                        ),
                      );
                    }).toList();
                  },
                ),
                touchCallback: (FlTouchEvent event, LineTouchResponse? response) {},
                getTouchedSpotIndicator:
                    (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(color: Colors.white24, strokeWidth: 2),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 6,
                              color: Colors.amberAccent,
                              strokeWidth: 1,
                              strokeColor: Colors.black,
                            ),
                      ),
                    );
                  }).toList();
                },
              ),
              backgroundColor: Colors.grey[900]!,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                drawHorizontalLine: false,
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= saldoAcumulado.length) {
                        return Container();
                      }

                      String mes = saldoAcumulado[index].key;
                      DateTime dt = DateTime.parse('$mes-01');
                      String label = DateFormat('MM/yyyy').format(dt);

                      if (isMobile && index % 2 != 0) return Container();

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isMobile ? 9 : 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxGraphY - minGraphY) / 5,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        'R\$${value.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isMobile ? 9 : 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white24),
              ),
              minX: 0,
              maxX: (saldoAcumulado.length - 1).toDouble(),
              minY: minGraphY,
              maxY: maxGraphY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: corLinha,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 4,
                      color: corLinha,
                      strokeWidth: 1,
                      strokeColor: Colors.black,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: corArea,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget legenda(double totalGeral) {

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withAlpha(150),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[600]!.withAlpha(200),
            width: 1,
            ),
          ),
          child: IntrinsicWidth(
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
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget grafico(double totalGeral) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxWidth < 600 ? 240 : 280;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 8,
                    offset: Offset(0, 0),
                  ),
                ],
                color: Colors.grey[900]!.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[600]!.withAlpha(200),
                  width: 1,
                ),
              ),
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
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
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
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              color: cor,
              fontSize: 17,
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
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
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 1350;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.start,
                  children: [
                    SizedBox(
                      width: isWide ? (constraints.maxWidth / 2) - 8 : constraints.maxWidth,
                      child: buildGraficoPizza(),
                    ),
                    SizedBox(
                      width: isWide ? (constraints.maxWidth / 2) - 8 : constraints.maxWidth,
                      child: buildGraficoLinhaSaldo(saldoAcumulado),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 16),

            transacoesDetalhadas == null || transacoesDetalhadas!.isEmpty
                ? Center(
              child: Text(
                'Nenhuma transação encontrada.',
                style: TextStyle(color: Colors.white70),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: transacoesDetalhadas!.length,
              itemBuilder: (context, index) {
                final item = transacoesDetalhadas![index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['categoria'] ?? 'Sem categoria',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.white54, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Data: ${formatarData(item['data'])}',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item['tipo'] == 'Receita' ? Icons.arrow_upward : Icons.arrow_downward,
                                color: item['tipo'] == 'Receita' ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                item['tipo'],
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                          Text(
                            'R\$ ${item['total'].toString()}',
                            style: TextStyle(
                              color: item['total'] >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
