import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// クイズデータを管理するクラス
class UsoQuizData {
  final String usoQuestion;
  final String originalQuestion;
  final String answer;

  UsoQuizData({
    required this.usoQuestion,
    required this.originalQuestion,
    required this.answer,
  });

  factory UsoQuizData.fromJson(Map<String, dynamic> json) {
    return UsoQuizData(
      usoQuestion: json['usoQuestion'] ?? '',
      originalQuestion: json['originalQuestion'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

class UsoQuizScreen extends StatefulWidget {
  const UsoQuizScreen({super.key});

  @override
  State<UsoQuizScreen> createState() => _UsoQuizScreenState();
}

class _UsoQuizScreenState extends State<UsoQuizScreen> {
  UsoQuizData? quiz;
  bool _isLoading = true;
  bool _isAnswered = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _controller.clear();
    });

    String? apiKey;
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('APIキーが未設定です。.envファイルを確認してください。');
      }

      // モデルの指定（公式サンプルに合わせた Gemini 2.5 Flash）
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        requestOptions: const RequestOptions(apiVersion: 'v1'),
      );

      final prompt = '''
あなたはQuizKnockの「ウソ8OOクイズ」を作成するAIです。
以下のルールで1問作成し、必ずJSON形式のみを出力してください。

【ルール】
1. 一般的なクイズの問題文の各単語を、反対語や関連する別の言葉に置き換えて「ウソの問題文」を作ってください。
2. JSON以外のテキスト（解説や挨拶）は一切出力しないでください。

【出力形式】
{
  "usoQuestion": "ウソに変換された問題文",
  "originalQuestion": "元の正しい問題文",
  "answer": "答え（名詞）"
}

【例】
元の文：日本で一番高い山は？
ウソの文：海外で一番低い谷は？
答え：富士山
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('AIからの返答が空でした。');
      }

      // デバッグ用：AIが実際に何を返したかコンソールに出力
      debugPrint('--- AI Response Raw ---');
      debugPrint(responseText);

      // JSON部分を抽出するロジック（Markdownの枠 ```json ... ``` を除去）
      String jsonString = responseText.trim();
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(jsonString);
      if (jsonMatch != null) {
        jsonString = jsonMatch;
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      if (mounted) {
        setState(() {
          quiz = UsoQuizData.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('--- Error Detail ---');
      debugPrint('type: ${e.runtimeType}');
      debugPrint('message: ${e.toString()}');
      debugPrint('stack: $st');

      if (apiKey != null && apiKey.isNotEmpty && _isModelError(e)) {
        await _debugListModels(apiKey);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('クイズ生成エラー: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  bool _isModelError(Object error) {
    final message = error.toString();
    return message.contains('ListModels') ||
        message.contains('not found') ||
        message.contains('supported for generateContent');
  }

  Future<void> _debugListModels(String apiKey) async {
    final versions = ['v1beta', 'v1'];
    for (final version in versions) {
      try {
        final uri = Uri.https(
          'generativelanguage.googleapis.com',
          '/$version/models',
          {'key': apiKey},
        );
        debugPrint('--- ListModels Request URI ---');
        debugPrint(uri.toString());

        final client = HttpClient();
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        debugPrint('--- ListModels Response Version --- $version');
        debugPrint('--- ListModels Response Status --- ${response.statusCode}');
        debugPrint(body);
        client.close(force: true);

        if (response.statusCode == 200) {
          return;
        }
      } catch (error, st) {
        debugPrint('--- ListModels Debug Failed for $version ---');
        debugPrint(error.toString());
        debugPrint(st.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ウソ8OOクイズ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE60012),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _generateQuiz,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE60012)),
                  SizedBox(height: 20),
                  Text('AIが問題を生成中...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (quiz != null) ...[
                    // 問題表示
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE60012), width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: Text(
                        quiz!.usoQuestion,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // 入力欄
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '答えを入力',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      enabled: !_isAnswered,
                    ),
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE60012)),
                        onPressed: _isAnswered ? null : () => setState(() => _isAnswered = true),
                        child: const Text('回答する', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // 回答後の解説表示
                    if (_isAnswered) ...[
                      const SizedBox(height: 40),
                      const Divider(thickness: 2),
                      const SizedBox(height: 20),
                      const Text('【元の問題】', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      Text(quiz!.originalQuestion, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      const Text('【正解】', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      Text(quiz!.answer, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 40),
                      TextButton.icon(
                        onPressed: _generateQuiz,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('次の問題へ', style: TextStyle(fontSize: 18)),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFE60012)),
                      ),
                    ],
                  ]
                ],
              ),
            ),
    );
  }
}