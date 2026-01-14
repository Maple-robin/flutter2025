import 'package:flutter/material.dart';
import 'answer_page.dart'; // 作成したファイルをインポート

void main() {
  runApp(const QuizKnockApp());
}

class QuizKnockApp extends StatelessWidget {
  const QuizKnockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 右上のデバッグラベルを非表示
      title: '今日の一問 Mock',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B0000),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const QuestionPage(),
    );
  }
}

class QuestionPage extends StatelessWidget {
  const QuestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の一問', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF8B0000),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '【Q】',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8B0000)),
              ),
              const SizedBox(height: 20),
              const Text(
                '日本で一番高い山は富士山ですが、\n二番目に高い山は何でしょう？',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, height: 1.5),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  // answer_page.dartへ遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnswerPage()),
                  );
                },
                child: const Text('答えを見る', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}