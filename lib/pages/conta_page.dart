import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';
import 'detalhes_conta_page.dart';
import '../widgets/form_dialog.dart';

class ContasPage extends StatefulWidget {
  @override
  _ContasPageState createState() => _ContasPageState();
}

class _ContasPageState extends State<ContasPage> {
  List<Map<String, dynamic>> contas = [];
  Map<int, double> saldosAtuais = {}; // Saldo atual por contaId
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
      if (!mounted) return;
      setState(() {
        contas = response;
        carregando = false;
      });

      // Carregar saldos atuais para cada conta
      for (var conta in contas) {
        final saldoAtual = await ApiService.obterSaldoAtualConta(token, conta['id']);
        setState(() {
          saldosAtuais[conta['id']] = saldoAtual;
        });
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conta criada com sucesso!')),
      );
      _nomeBancoController.clear();
      _saldoInicialController.clear();

      await carregarContas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar conta')),
      );
    }
  }

  Future<void> editarConta(Map<String, dynamic> conta, String nomeBanco, String saldoInicial) async {
    final token = await AuthService.obterToken();
    if (token == null) return;


    if (nomeBanco.isEmpty || saldoInicial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todos os campos são obrigatórios')),
      );
      return;
    }

    final contaEdit = {
      "id": conta['id'],
      "nome_banco": nomeBanco.trim(),
      "saldo_inicial": double.tryParse(saldoInicial.trim())
    };

    final sucesso = await ApiService.editarConta(token, contaEdit);

    if (sucesso) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conta editada com sucesso!')),
      );
      _nomeBancoController.clear();
      _saldoInicialController.clear();
      await carregarContas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao editar conta')),
      );
    }
  }

  Future<void> deletarConta(conta) async {
    final token = await AuthService.obterToken();
    if (token == null) return;

    final sucesso = await ApiService.deletarConta(token, conta);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conta excluída com sucesso!')),
      );
      carregarContas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir conta')),
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
            child: Text('Adicionar'),
            onPressed: adicionarConta,
          ),
        ],
      ),
    );
  }

  void mostrarDialogEditarConta(BuildContext context, Map<String, dynamic> conta) {
    final _formKey = GlobalKey<FormState>();
    final _nomeBancoController = TextEditingController(text: conta['nome_banco']);
    final _saldoInicialController =
    TextEditingController(text: conta['saldo_inicial'].toString());

    bool salvando = false;
    String? erro;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            void salvar() async {
              if (!_formKey.currentState!.validate()) return;

              setState(() => salvando = true);

              try {
                await editarConta(conta, _nomeBancoController.text,
                    _saldoInicialController.text);
                Navigator.of(context).pop(true);
              } catch (e) {
                setState(() {
                  erro = e.toString();
                  salvando = false;
                });
              }
            }

            return AlertDialog(
              content: SizedBox(
                width: 400,
                child: FormDialog(
                  titulo: 'Editar Conta',
                  formFields: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nomeBancoController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do banco',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Informe o nome'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _saldoInicialController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Saldo Inicial',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Informe o saldo';
                            if (double.tryParse(value) == null) return 'Formato de saldo inválido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  erro: erro,
                  salvando: salvando,
                  onSalvar: salvar,
                  onCancelar: () => Navigator.of(context).pop(false),
                ),
              ),
            );
          },
        );
      },
    );
  }


  static const Color primaryColor = Color.fromARGB(255, 65, 65, 65);
  static const Color backgroundColor = Colors.black87;
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
            final saldoAtual = saldosAtuais[conta['id']] ?? 0.0;

            return Material(
              elevation: 4,
              shadowColor: shadowColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Parte esquerda: informações da conta
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conta['nome_banco'] ?? 'Banco',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Saldo: R\$ ${saldoAtual.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                      ),

                      // Parte direita: ícones de ação
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.white70),
                            onPressed: () {
                              mostrarDialogEditarConta(context, conta);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.white70),
                            onPressed: () {
                              deletarConta(conta);
                            },
                          ),
                        ],
                      ),
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