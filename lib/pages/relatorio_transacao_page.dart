import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_services.dart';

class ComprovanteDialog extends StatefulWidget {
  final int idTransacao;

  const ComprovanteDialog({required this.idTransacao});

  @override
  _ComprovanteDialogState createState() => _ComprovanteDialogState();
}

class _ComprovanteDialogState extends State<ComprovanteDialog> {
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
    return Stack(
      children: [
        // Fundo embaçado
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        // Dialog centralizado e compacto
        Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 320),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: _loading
                ? SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            )
                : _erro != null
                ? SizedBox(
              height: 120,
              child: Center(
                child: Text(_erro!, style: TextStyle(color: Colors.redAccent)),
              ),
            )
                : _relatorio != null
                ? SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Comprovante',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 12),
                  _info("Descrição", _relatorio!['descricao']),
                  _info("Valor", "R\$ ${_relatorio!['valor']}"),
                  _info("Data", _relatorio!['data']),
                  _info("Usuário", _relatorio!['nome_usuario']),
                  _info("Tipo", _relatorio!['tipo_transacao']),
                  _info("Banco", _relatorio!['nome_conta']),
                  _info("Categoria", _relatorio!['nome_categoria']),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Fechar"),
                    ),
                  ),
                ],
              ),
            )
                : SizedBox(
              height: 120,
              child: Center(
                child: Text("Relatório não encontrado",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        "$label: $value",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
