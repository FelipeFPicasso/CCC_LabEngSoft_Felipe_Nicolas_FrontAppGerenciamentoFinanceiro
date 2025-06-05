import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ResumoTransacoesPage extends StatefulWidget {
  const ResumoTransacoesPage({super.key});

  @override
  State<ResumoTransacoesPage> createState() => _ResumoTransacoesPageState();
}

class _ResumoTransacoesPageState extends State<ResumoTransacoesPage> {
  List<String> categorias = [];
  String? categoriaSelecionada;
  String? tipoSelecionado;
  DateTime? dataInicio;
  DateTime? dataFim;
  List<Map<String, dynamic>> resumo = [];
  bool carregando = false;
  String? erro;

  static const baseUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    carregarCategorias();
    buscarResumo();
  }
}
