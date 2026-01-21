import 'package:flutter/material.dart';

class ExplanationScreen extends StatelessWidget {
  final bool isCorrect;
  final String explanation;

  const ExplanationScreen({
    super.key,
    required this.isCorrect,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isCorrect ? '正解！' : '不正解...',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '【解説】',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                explanation,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  // 前の画面（クイズ画面）に戻る、もしくは次の問題へ
                  Navigator.pop(context);
                },
                child: const Text('次へ進む'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}