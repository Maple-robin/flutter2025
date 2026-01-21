import 'package:flutter/material.dart';

class ExplanationScreen extends StatelessWidget {
  final bool isCorrect;
  final String explanation;

  // ここが AnswerInputScreen から送られてくるデータを受け取る窓口です
  const ExplanationScreen({
    super.key,
    required this.isCorrect,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('解説'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isCorrect ? '正解！' : '不正解...',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              explanation,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                // タイトル（最初の画面）まで一気に戻る
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('タイトルへ戻る'),
            ),
          ],
        ),
      ),
    );
  }
}