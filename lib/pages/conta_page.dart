import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';
import 'detalhes_conta_page.dart';

class ContasPage extends StatefulWidget {
  const ContasPage({super.key});

  @override
  _ContasPageState createState() => _ContasPageState();
}

class _ContasPageState extends State<ContasPage> {
  List<Map<String, dynamic>> contas = [];
  bool carregando = true;
  String? erro;

  final _nomeBancoController = TextEditingController();
  final _saldoInicialController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarContas();
  }

  Future<void> carregarContas() async {
    try {
      final token = await AuthService.obterToken();
      if (token == null) {
        setState(() {
          erro = 'Usuário não autenticado. Faça login novamente.';
          carregando = false;
        });
        return;
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      String userId = decodedToken['usuario_id']?.toString() ?? '';

      if (userId.isEmpty || userId == 'null') {
        setState(() {
          erro = 'ID do usuário inválido no token.';
          carregando = false;
        });
        return;
      }

      final response = await ApiService.listarContasUsuario(token, userId);
      setState(() {
        contas = response;
        carregando = false;
      });
    } catch (e) {
      setState(() {
        erro = 'Nenhuma conta adicionada.';
        carregando = false;
      });
    }
  }

  Future<void> adicionarConta() async {
    final token = await AuthService.obterToken();
    if (token == null) return;

    final nomeBanco = _nomeBancoController.text.trim();
    final saldoInicial = _saldoInicialController.text.trim();

    if (nomeBanco.isEmpty || saldoInicial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todos os campos são obrigatórios')),
      );
      return;
    }

    final novaConta = {
      "nome_banco": nomeBanco,
      "saldo_inicial": double.tryParse(saldoInicial)
    };

    final sucesso = await ApiService.criarConta(token, novaConta);

    if (sucesso) {
      Navigator.of(context).pop(); // Fechar o dialog
      _nomeBancoController.clear();
      _saldoInicialController.clear();
      carregarContas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar conta')),
      );
    }
  }

  void mostrarDialogAdicionarConta() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Adicionar Conta'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nomeBancoController,
                decoration: InputDecoration(labelText: 'Nome do Banco'),
              ),
              TextField(
                controller: _saldoInicialController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Saldo Inicial'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            onPressed: adicionarConta,
            child: Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  static const Color primaryColor = Color.fromARGB(255,46,46,46);
  static const Color backgroundColor = Colors.black87;
  static const Color cardColor = Colors.white;
  static const Color shadowColor = Color(0x22000000);

  TextStyle tituloContaStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: primaryColor,
    letterSpacing: 0.3,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
        title: Text(
          'Minhas Contas',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 2,
        shadowColor: shadowColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: carregando
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : erro != null
            ? Center(
          child: Text(
            erro!,
            style: TextStyle(color: Colors.red.shade700, fontSize: 16),
          ),
        )
            : ListView.separated(
          itemCount: contas.length,
          separatorBuilder: (_, __) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final conta = contas[index];

            return Material(
              elevation: 4,
              shadowColor: shadowColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContaDetalhesPage(
                        contaId: conta['id'],
                        nomeBanco: conta['nome_banco'] ?? 'Sem nome',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, size: 40, color: primaryColor),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(conta['nome_banco'] ?? 'Sem nome', style: tituloContaStyle),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 18),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: Icon(Icons.add),
        label: Text('Adicionar'),
        onPressed: mostrarDialogAdicionarConta,
      ),
    );
  }
}
