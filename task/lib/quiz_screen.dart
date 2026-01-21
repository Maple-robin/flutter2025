import 'package:flutter/material.dart';
import 'explanation_screen.dart'; // 解説画面をインポート

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('第1問'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text(
                  'QuizKnockの「東大王」でもおなじみ、伊沢拓司がCEOを務める会社は何？',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _buildAnswerButton(
              context, 
              '株式会社baton', 
              true, 
              '正解！「遊び」と「学び」を繋ぐ「バトン」のような存在になりたいという思いや、リレーのバトンのように知識を繋いでいくという意味が込められています。'
            ),
            _buildAnswerButton(
              context, 
              '株式会社QuizKnock', 
              false, 
              '残念！QuizKnockはメディア名で、運営している会社名は「株式会社baton」です。「学びのバトンを繋ぐ」という由来があります。'
            ),
            _buildAnswerButton(
              context, 
              '株式会社東大', 
              false, 
              '残念！伊沢さんは東大経済学部卒ですが、会社名は「株式会社baton」です。'
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 引数に isCorrect（正解判定）と explanation（解説文）を追加しました
  Widget _buildAnswerButton(BuildContext context, String text, bool isCorrect, String explanation) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black, 
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(15),
        ),
        onPressed: () {
          // ボタンを押したときに explanation_screen.dart へ遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExplanationScreen(
                isCorrect: isCorrect,
                explanation: explanation,
              ),
            ),
          );
        },
        child: Text(text, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}