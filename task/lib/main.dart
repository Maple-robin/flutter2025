import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'akuma_gattai_quiz_screen.dart';
import 'mashimashi_quiz_screen.dart';
import 'uso_quiz_screen.dart';
import 'yaminabe_quiz_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuizKnock Special',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE60012)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizModes = [
      _QuizMode(
        title: 'ウソ800クイズ',
        icon: Icons.change_circle,
        builder: (_) => const UsoQuizScreen(),
      ),
      _QuizMode(
        title: '闇鍋クイズ',
        icon: Icons.soup_kitchen,
        builder: (_) => const YaminabeQuizScreen(),
      ),
      _QuizMode(
        title: '難易度マシマシクイズ',
        icon: Icons.trending_up,
        builder: (_) => const MashimashiQuizScreen(),
      ),
      _QuizMode(
        title: '悪魔合体クイズ',
        icon: Icons.auto_awesome,
        builder: (_) => const AkumaGattaiQuizScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'QuizKnock Special',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE60012),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: quizModes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final mode = quizModes[index];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(mode.icon, color: const Color(0xFFE60012)),
              title: Text(
                mode.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: mode.builder),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _QuizMode {
  const _QuizMode({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}
