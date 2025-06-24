import 'package:intl/intl.dart';

Map<String, double> agruparPorMes(List<dynamic> transacoes, String tipoFiltro) {
  Map<String, double> totalPorMes = {};
  final formatadorData = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US');

  for (var t in transacoes) {
    final tipo = t['tipo'] as String?;
    if (tipoFiltro != null && tipo != tipoFiltro) continue;

    final dataStr = t['data'] as String?;
    if (dataStr == null) continue;

    DateTime data;
    try {
      final dataLimpa = dataStr.replaceAll(' GMT', '');
      data = formatadorData.parse(dataLimpa);
      data = formatadorData.parse(dataStr);
    } catch (_) {
      continue;
    }

    final mes = '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}';
    final valorBruto = (t['total'] ?? 0).toDouble();

    final valor = tipo == 'Despesa' ? valorBruto.abs(): valorBruto;

    totalPorMes[mes] = (totalPorMes[mes] ?? 0) + valor;
  }

  return totalPorMes;
}


List<MapEntry<String, double>> calcularSaldoAcumulado(Map<String, double> saldoMes) {
  var mesesOrdenados = saldoMes.keys.toList()..sort();
  List<MapEntry<String, double>> acumulado = [];
  double soma = 0;

  for (var mes in mesesOrdenados) {
    soma += saldoMes[mes]!;
    acumulado.add(MapEntry(mes, soma));
  }

  return acumulado;
}
