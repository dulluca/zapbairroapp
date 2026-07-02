import 'package:flutter/material.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3000), () {});
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TelaCategorias()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width:
              MediaQuery.of(context).size.width *
              0.85, // Ocupa 85% da largura da tela do S21+
          height:
              MediaQuery.of(context).size.width *
              0.85, // Mantém a proporção quadrada perfeita
          fit: BoxFit.contain, // Aumenta ao máximo sem distorcer o desenho
        ), // Image.asset
      ), // Center
    );
  }
} // <--- Essa é a chave que estava faltando fechar o arquivo!
