import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizKnock Special',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // クイズモードのリスト定義
    final List<Map<String, String>> quizModes = [
      {'title': 'ウソ800クイズ', 'icon': '🤥'},
      {'title': '闇鍋クイズ', 'icon': '🍲'},
      {'title': '難易度マシマシクイズ', 'icon': '🍜'},
      {'title': '悪魔合体クイズ', 'icon': '😈'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 薄いグレー
      appBar: AppBar(
        title: const Text(
          'QuizKnock Special',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE60012), // 正しいブランドカラーの赤
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'プレイするモードを選択してください',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: quizModes.length,
                itemBuilder: (context, index) {
                  return _buildQuizModeCard(
                    context,
                    quizModes[index]['title']!,
                    quizModes[index]['icon']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizModeCard(BuildContext context, String title, String icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Text(icon, style: const TextStyle(fontSize: 30)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          // TODO: 各モードの画面へ遷移する処理
          print('$title を選択しました');
        },
      ),
    );
  }
}
