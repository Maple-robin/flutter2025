import 'package:flutter/material.dart';
import 'quiz_screen.dart'; 
import 'hundred_char_screen.dart';

void main() {
  runApp(const QuizKnockApp());
}

class QuizKnockApp extends StatelessWidget {
  const QuizKnockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QK Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black, // クールな黒背景
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'QUIZKNOCK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const Text(
              'MOCK',
              style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () {
                // 問題画面へ遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizScreen()),
                );
              },
              child: const Text('クイズを開始する', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
            // main.dart の Column の中に追加してください
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blueGrey, // モードごとに色を変えると分かりやすいです
    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HundredCharScreen()),
    );
  },
  child: const Text('100文字クイズを開始', style: TextStyle(fontSize: 20, color: Colors.white)),
),
          ],
        ),
      ),
    );
  }
}