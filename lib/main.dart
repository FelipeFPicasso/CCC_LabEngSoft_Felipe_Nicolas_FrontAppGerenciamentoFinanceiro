import 'package:flutter/material.dart';
import 'pages/cadastro_page.dart';
import 'pages/login_page.dart';
import 'pages/recuperar_senha_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenc Finanças',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/cadastro': (context) => CadastroPage(),
        '/recuperar-senha': (context) => RecuperarSenhaPage(),
      },
    );
  }
}
