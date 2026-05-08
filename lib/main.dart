import 'package:flutter/material.dart';
import 'pages/login_screen.dart';

void main() {
  runApp(const RotaExpressApp());
}

class RotaExpressApp extends StatelessWidget {
  const RotaExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}