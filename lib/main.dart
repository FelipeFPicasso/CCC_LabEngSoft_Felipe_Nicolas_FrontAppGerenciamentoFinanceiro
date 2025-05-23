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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.white,        // Cor de destaque
          onPrimary: Colors.white,      // Texto sobre o botão primário
          secondary: Colors.grey,       // Cor secundária
          onSecondary: Colors.white,    // Texto sobre o botão secundário
          error: Colors.red,
          onError: Colors.red,
          background: Colors.black,  // Scaffold background
          onBackground: Colors.white,
          surface: Color.fromARGB(255,45,45,45),        // Cor do AlertDialog, Card, etc.
          onSurface: Colors.white,      // Texto em cima do `surface`
        ),
      ),
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
