import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/auth_services.dart';
import 'adicionar_cartao_page.dart';
import 'editar_cartao_page.dart'; // Importação da página de edição
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

  static const Color primaryColor = Color.fromARGB(255, 65, 65, 65);
  static const Color backgroundColor = Colors.black87;
  static const Color cardColor = Color.fromARGB(255, 61, 61, 61);
  static const Color textColor = Color(0xFFE0E1DD);
  static const Color accentColor = Color(0xFFAAAAAA);
  static const Color shadowColor = Color(0x44000000);

  TextStyle tituloCartaoStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textColor,
    letterSpacing: 0.3,
  );

  static const String baseUrl = 'http://localhost:8000';

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

  String formatarValor(dynamic valor) {
    if (valor == null) return 'Limite não informado';
    try {
      final numero = double.tryParse(valor.toString());
      if (numero == null) return 'Limite inválido';
      final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
      return formatador.format(numero);
    } catch (_) {
      return 'Erro ao formatar';
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
                carregarCartoes();  // Atualiza a lista após exclusão
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
            : FutureBuilder<String?>(
          future: AuthService.obterToken(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: accentColor));
            }
            if (!snapshot.hasData || snapshot.data == null || JwtDecoder.isExpired(snapshot.data!)) {
              return Center(
                child: Text(
                  'Sessão expirada. Faça login novamente.',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final token = snapshot.data!;

            return ListView.separated(
              itemCount: cartoes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final cartao = cartoes[index];
                final limite = formatarValor(cartao['limite']);
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
                    // Removi o onTap para não abrir ao clicar no cartão
                    onTap: null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.credit_card,
                            color: accentColor,
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nomeConta,
                                  style: tituloCartaoStyle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Limite: $limite',
                                  style: const TextStyle(color: accentColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vencimento fatura: $vencFatura',
                                  style: const TextStyle(color: accentColor),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () async {
                              final resultado = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditarCartaoPage(
                                    cartaoId: cartao['id'],
                                    token: token,
                                  ),
                                ),
                              );
                              if (resultado == true) {
                                carregarCartoes();
                              }
                            },
                            tooltip: 'Editar cartão',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => confirmarExcluirCartao(cartao['id']),
                            tooltip: 'Excluir cartão',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}