import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';
import 'adicionar_cartao_page.dart';

class CartaoPage extends StatefulWidget {
  const CartaoPage({Key? key}) : super(key: key);

  @override
  State<CartaoPage> createState() => _CartaoPageState();
}

class _CartaoPageState extends State<CartaoPage> {
  List<Map<String, dynamic>> cartoes = [];
  bool carregando = true;
  String? erro;

  static const Color primaryColor = Color(0xFF1B263B);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color shadowColor = Color(0x22000000);

  TextStyle tituloCartaoStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: primaryColor,
    letterSpacing: 0.3,
  );

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

      if (token == null) {
        setState(() {
          erro = 'Usuário não autenticado. Faça login novamente.';
          carregando = false;
        });
        return;
      }

      if (JwtDecoder.isExpired(token)) {
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

      final dados = await ApiService.getCartoesPorUsuario(token, int.parse(userId));

      setState(() {
        cartoes = dados;
        carregando = false;
      });
    } catch (e) {
      setState(() {
        erro = 'Erro ao carregar cartões: $e';
        carregando = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Meus Cartões',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 2,
        shadowColor: shadowColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: carregarCartoes,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: carregando
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : erro != null
            ? Center(
          child: Text(
            erro!,
            style: TextStyle(color: Colors.red.shade700, fontSize: 16),
          ),
        )
            : cartoes.isEmpty
            ? const Center(child: Text('Nenhum cartão encontrado.'))
            : ListView.separated(
          itemCount: cartoes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final cartao = cartoes[index];
            final limite = cartao['limite']?.toString() ?? 'Limite não informado';
            final vencFatura = cartao['venc_fatura'] ?? 'Vencimento não informado';
            final nomeConta = cartao['nome_conta'] ?? 'Conta não informada';

            return Material(
              elevation: 4,
              shadowColor: shadowColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Aqui pode abrir detalhes do cartão
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, size: 40, color: primaryColor),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Limite: $limite', style: tituloCartaoStyle),
                            const SizedBox(height: 4),
                            Text('Vencimento da fatura: $vencFatura'),
                            Text('Conta: $nomeConta'),
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
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
        onPressed: mostrarDialogAdicionarCartao,
      ),
    );
  }
}
