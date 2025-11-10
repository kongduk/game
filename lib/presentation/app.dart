import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class OneCardApp extends StatelessWidget {
  const OneCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '원카드 게임',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
