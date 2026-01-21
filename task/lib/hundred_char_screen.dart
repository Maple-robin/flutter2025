import 'package:flutter/material.dart';
import 'answer_input_screen.dart';

class HundredCharScreen extends StatefulWidget {
  const HundredCharScreen({super.key});

  @override
  State<HundredCharScreen> createState() => _HundredCharScreenState();
}

class _HundredCharScreenState extends State<HundredCharScreen> {
  // 表示するヒントのリスト
  final List<String> _allHints = [
    "【10文字】1994年生まれ、",
    "【30文字】埼玉県出身。2016年に東大在学中に、",
    "【60文字】自らが編集長となって知的メディア「QuizKnock」を立ち上げた、",
    "【100文字】現在は株式会社batonのCEOを務める、日本のクイズプレイヤーは誰？"
  ];

  int _currentHintIndex = 0; // 現在どこまで表示しているか

  @override
  Widget build(BuildContext context) {
    // 現在表示すべきテキストを結合して作成
    String displayedText = _allHints.sublist(0, _currentHintIndex + 1).join("");

    return Scaffold(
      appBar: AppBar(
        title: const Text('100文字クイズ'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    displayedText,
                    style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ヒントがまだある場合は「次のヒント」ボタンを表示
            if (_currentHintIndex < _allHints.length - 1)
              _buildActionButton(
                label: '次のヒントを出す',
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    _currentHintIndex++;
                  });
                },
              ),
            const SizedBox(height: 10),
            // 回答ボタン（常に表示、または最後に出現）
_buildActionButton(
              label: '回答する',
              color: Colors.red,
              onPressed: () {
                // 直接解説ではなく、入力画面へ飛ばす
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnswerInputScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color == Colors.white ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}