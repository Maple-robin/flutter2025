import 'package:flutter/material.dart';
import 'explanation_screen.dart';

class AnswerInputScreen extends StatefulWidget {
  const AnswerInputScreen({super.key});

  @override
  State<AnswerInputScreen> createState() => _AnswerInputScreenState();
}

class _AnswerInputScreenState extends State<AnswerInputScreen> {
  final TextEditingController _controller = TextEditingController();

  void _checkAnswer() {
    String userAnswer = _controller.text.trim();
    // 正解判定（ひらがなや漢字の揺れを考慮する場合は工夫が必要ですが、今回はシンプルに）
    bool isCorrect = (userAnswer == "伊沢拓司" || userAnswer == "いざわたくし");
    
    String message = isCorrect 
        ? "正解です！さすがですね！" 
        : "残念！正解は「伊沢拓司」でした。";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExplanationScreen(
          isCorrect: isCorrect,
          explanation: "$message\n\n1994年生まれ、株式会社batonのCEOであり、QuizKnockの編集長です。",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('回答入力'), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '答えを入力してください',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true, // 画面が開いたらすぐキーボードを出す
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                hintText: '例：伊沢拓司',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: _checkAnswer,
              child: const Text('決定', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}