// cartao_page.dart

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';
import 'adicionar_cartao_page.dart';

class CartaoPage extends StatefulWidget {
  const CartaoPage({super.key});

  @override
  State<CartaoPage> createState() => _CartaoPageState();
}

class _CartaoPageState extends State<CartaoPage> {
  List<Map<String, dynamic>> cartoes = [];
  bool carregando = true;
  String? erro;

  // Paleta escura para manter consistência visual com o restante do app
  static const Color primaryColor = Color(0xFF1B263B);
  static const Color backgroundColor = Color(0xFF0D1B2A);
  static const Color cardColor = Color(0xFF415A77);
  static const Color textColor = Color(0xFFE0E1DD);
  static const Color accentColor = Color(0xFF778DA9);
  static const Color shadowColor = Color(0x44000000);

  TextStyle tituloCartaoStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textColor,
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
                onTap: () {
                  // Ação ao tocar no cartão (ex: detalhes)
                },
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
                            Text('Conta: $nomeConta', style: TextStyle(color: textColor)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mostrarDialogAdicionarCartao,
        backgroundColor: accentColor,
        label: const Text('Adicionar'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
