import 'package:flutter/material.dart';
import 'package:untitled/pages/adicionar_transacao_page.dart';
import 'pages/cadastro_page.dart';
import 'pages/login_page.dart';
import 'pages/recuperar_senha_page.dart';
import 'pages/menu_page.dart';
import 'pages/cartao_page.dart';
import 'pages/conta_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenc Finanças',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => MenuPage(),
        '/cadastro': (context) => CadastroPage(),
        '/recuperar-senha': (context) => RecuperarSenhaPage(),
        '/cartoes': (context) => CartaoPage(),
        '/contas': (context) => ContasPage(),
        '/adicionar_transacao': (context) => AdicionarTransacaoPage(),
      },
    );
  }
}
