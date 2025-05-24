import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/auth_services.dart';
import 'adicionar_cartao_page.dart';
import '../widgets/form_dialog.dart';

class CartaoPage extends StatefulWidget {
  const CartaoPage({super.key});

  @override
  State<CartaoPage> createState() => _CartaoPageState();
}

class _CartaoPageState extends State<CartaoPage> {
  List<Map<String, dynamic>> cartoes = [];
  bool carregando = true;
  String? erro;

  static const Color primaryColor = Color.fromARGB(255, 43, 43, 43);
  static const Color backgroundColor = Colors.black87;
  static const Color cardColor = Color.fromARGB(255, 65, 65, 65);
  static const Color textColor = Color(0xFFE0E1DD);
  static const Color accentColor = Color(0xFFAAAAAA);
  static const Color shadowColor = Color(0x44000000);

  TextStyle tituloCartaoStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textColor,
    letterSpacing: 0.3,
  );

  static const String baseUrl = 'http://localhost:8000'; // Ajuste a URL do seu backend

  @override
  void initState() {
    super.initState();
    carregarCartoes();
  }

  Future<void> carregarCartoes() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final token = await AuthService.obterToken();

      if (token == null || JwtDecoder.isExpired(token)) {
        setState(() {
          erro = 'Sessão expirada. Faça login novamente.';
          carregando = false;
        });
        return;
      }

      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['usuario_id']?.toString();

      if (userId == null || userId.isEmpty || userId == 'null') {
        setState(() {
          erro = 'ID do usuário inválido no token.';
          carregando = false;
        });
        return;
      }

      final url = Uri.parse('$baseUrl/cartoes/usuario/$userId');
      final response = await http.get(
        url,
        headers: {'Authorization': '$token'},
      );

      if (response.statusCode == 200) {
        final List dadosJson = jsonDecode(response.body);
        setState(() {
          cartoes = List<Map<String, dynamic>>.from(dadosJson);
          carregando = false;
        });
      } else {
        setState(() {
          erro = 'Erro ao buscar cartões: ${response.statusCode}';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        erro = 'Erro ao carregar cartões: $e';
        carregando = false;
      });
    }
  }

  Future<bool> deletarCartao(String token, int idCartao) async {
    final url = Uri.parse('$baseUrl/cartoes/$idCartao');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Erro ao deletar cartão: $e');
      return false;
    }
  }

  Future<bool> editarCartao(String token, Map<String, dynamic> cartaoAtualizado) async {
    if (cartaoAtualizado['id'] == null) return false;

    final url = Uri.parse('$baseUrl/cartoes/${cartaoAtualizado['id']}');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(cartaoAtualizado),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao editar cartão: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao editar cartão: $e');
      return false;
    }
  }

  void mostrarDialogAdicionarCartao() async {
    final token = await AuthService.obterToken();

    if (token == null || JwtDecoder.isExpired(token)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado ou sessão expirada.')),
      );
      return;
    }

    final decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['usuario_id']?.toString();

    if (userId == null || userId.isEmpty || userId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID do usuário inválido no token.')),
      );
      return;
    }

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdicionarCartaoPage(
          token: token,
          usuarioId: int.parse(userId),
        ),
      ),
    );

    if (resultado == true) {
      carregarCartoes();
    }
  }

  String formatarData(dynamic data) {
    try {
      DateTime dateTime;
      if (data is String) {
        dateTime = DateTime.parse(data);
      } else if (data is DateTime) {
        dateTime = data;
      } else {
        return data.toString();
      }

      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return data.toString();
    }
  }

  void abrirEditarCartao(Map<String, dynamic> cartao) async {
    final token = await AuthService.obterToken();
    if (token == null || JwtDecoder.isExpired(token)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado ou sessão expirada.')),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: EditarCartaoDialog(
          token: token,
          cartao: cartao,
          onSalvar: (cartaoAtualizado) async {
            final sucesso = await editarCartao(token, cartaoAtualizado);
            return sucesso;
          },
        ),
      ),
    );

    if (resultado == true) {
      carregarCartoes();
    }
  }

  void confirmarExcluirCartao(int idCartao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este cartão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);

              final token = await AuthService.obterToken();
              if (token == null || JwtDecoder.isExpired(token)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuário não autenticado ou sessão expirada.')),
                );
                return;
              }

              final sucesso = await deletarCartao(token, idCartao);
              if (sucesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cartão excluído com sucesso.')),
                );
                carregarCartoes();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Falha ao excluir cartão.')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        shadowColor: shadowColor,
        elevation: 3,
        title: const Text(
          'Meus Cartões',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: carregarCartoes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: mostrarDialogAdicionarCartao,
        backgroundColor: accentColor,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: carregando
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : erro != null
            ? Center(
          child: Text(
            erro!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        )
            : cartoes.isEmpty
            ? const Center(
          child: Text(
            'Nenhum cartão encontrado.',
            style: TextStyle(color: textColor),
          ),
        )
            : ListView.separated(
          itemCount: cartoes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final cartao = cartoes[index];
            final limite = cartao['limite']?.toString() ?? 'Limite não informado';
            final vencFatura = cartao['venc_fatura'] != null
                ? formatarData(cartao['venc_fatura'])
                : 'Vencimento não informado';
            final nomeConta = cartao['nome_conta'] ?? 'Conta não informada';

            return Material(
              color: Colors.transparent,
              elevation: 5,
              shadowColor: shadowColor,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => abrirEditarCartao(cartao),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, size: 40, color: accentColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Limite: $limite', style: tituloCartaoStyle),
                            const SizedBox(height: 4),
                            Text('Vencimento: $vencFatura', style: TextStyle(color: textColor)),
                            const SizedBox(height: 4),
                            Text('Conta: $nomeConta', style: TextStyle(color: textColor)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        onPressed: () => confirmarExcluirCartao(cartao['id']),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class EditarCartaoDialog extends StatefulWidget {
  final String token;
  final Map<String, dynamic> cartao;
  final Future<bool> Function(Map<String, dynamic>) onSalvar;

  const EditarCartaoDialog({
    Key? key,
    required this.token,
    required this.cartao,
    required this.onSalvar,
  }) : super(key: key);

  @override
  State<EditarCartaoDialog> createState() => _EditarCartaoDialogState();
}

class _EditarCartaoDialogState extends State<EditarCartaoDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController limiteController;
  late TextEditingController vencFaturaController;
  late TextEditingController nomeContaController;

  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();

    // Inicializa os controllers com os valores atuais do cartão
    limiteController = TextEditingController(
      text: widget.cartao['limite']?.toString() ?? '',
    );

    vencFaturaController = TextEditingController(
      text: widget.cartao['venc_fatura'] ?? '',
    );

    nomeContaController = TextEditingController(
      text: widget.cartao['nome_conta'] ?? '',
    );
  }

  @override
  void dispose() {
    limiteController.dispose();
    vencFaturaController.dispose();
    nomeContaController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      salvando = true;
      erro = null;
    });

    // Monta o mapa atualizado do cartão para enviar ao backend
    final cartaoAtualizado = {
      'id': widget.cartao['id'],
      'limite': double.tryParse(limiteController.text) ?? 0,
      'venc_fatura': vencFaturaController.text,
      'nome_conta': nomeContaController.text,
    };

    final sucesso = await widget.onSalvar(cartaoAtualizado);

    setState(() {
      salvando = false;
    });

    if (sucesso) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        erro = 'Falha ao salvar alterações. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      titulo: 'Editar Cartão',
      formFields: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: limiteController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Limite',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o limite';
                }
                if (double.tryParse(value) == null) {
                  return 'Limite inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: vencFaturaController,
              decoration: const InputDecoration(
                labelText: 'Vencimento da Fatura (AAAA-MM-DD)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a data de vencimento';
                }
                final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                if (!regex.hasMatch(value)) {
                  return 'Data deve estar no formato AAAA-MM-DD';
                }
                try {
                  DateTime.parse(value);
                } catch (_) {
                  return 'Data inválida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nomeContaController,
              decoration: const InputDecoration(
                labelText: 'Nome da Conta',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome da conta';
                }
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
    );
  }
}

