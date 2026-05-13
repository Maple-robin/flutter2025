import 'package:flutter/material.dart';
import 'uso_quiz_screen.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Flutterのエンジンが起動するのを待機（これがないとdotenvが失敗することがあります）
  WidgetsFlutterBinding.ensureInitialized();
  
  // .envファイルを読み込み
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // デバッグラベルを非表示
      title: 'QuizKnock Special',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> quizModes = [
      {'title': 'ウソ8OOクイズ', 'icon': '🤥'},
      {'title': '闇鍋クイズ', 'icon': '🍲'},
      {'title': '難易度マシマシクイズ', 'icon': '🍜'},
      {'title': '悪魔合体クイズ', 'icon': '😈'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuizKnock Special', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE60012),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizModes.length,
        itemBuilder: (context, index) {
          final mode = quizModes[index];
          return Card(
            child: ListTile(
              leading: Text(mode['icon']!, style: const TextStyle(fontSize: 30)),
              title: Text(mode['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                if (mode['title'] == 'ウソ8OOクイズ') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UsoQuizScreen()),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}