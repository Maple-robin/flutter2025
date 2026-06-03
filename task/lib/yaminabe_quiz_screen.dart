import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 元の個別のクイズデータを管理するクラス
class OriginalQuiz {
  final String question;
  final String answer;

  OriginalQuiz({required this.question, required this.answer});

  factory OriginalQuiz.fromJson(Map<String, dynamic> json) {
    return OriginalQuiz(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

// 闇鍋クイズ全体のデータを管理するクラス
class YaminabeQuizData {
  final String yaminabeQuestion;
  final List<OriginalQuiz> originalQuizzes;

  YaminabeQuizData({
    required this.yaminabeQuestion,
    required this.originalQuizzes,
  });

  factory YaminabeQuizData.fromJson(Map<String, dynamic> json) {
    final list = json['originalQuizzes'] as List? ?? [];
    final quizList = list
        .map((i) => OriginalQuiz.fromJson(i as Map<String, dynamic>))
        .toList();

    return YaminabeQuizData(
      yaminabeQuestion: json['yaminabeQuestion'] ?? '',
      originalQuizzes: quizList,
    );
  }
}

class YaminabeQuizScreen extends StatefulWidget {
  const YaminabeQuizScreen({super.key});

  @override
  State<YaminabeQuizScreen> createState() => _YaminabeQuizScreenState();
}

class _YaminabeQuizScreenState extends State<YaminabeQuizScreen> {
  YaminabeQuizData? quizData;
  bool _isLoading = true;
  bool _isAnswered = false;
  // クォータ超過時のクールダウン管理
  Timer? _cooldownTimer;
  DateTime? _cooldownUntil;
  int _cooldownRemaining = 0;

  // 4つの入力欄のためのコントローラー
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  // それぞれの正誤判定を保持するリスト
  List<bool> _isCorrectList = [false, false, false, false];
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _generateYaminabeQuiz();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  bool _isCooldownActive() {
    return _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    _cooldownUntil = DateTime.now().add(Duration(seconds: seconds));
    _cooldownRemaining = seconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final rem = _cooldownUntil!.difference(DateTime.now()).inSeconds;
      if (rem <= 0) {
        t.cancel();
        _cooldownUntil = null;
        setState(() => _cooldownRemaining = 0);
      } else {
        setState(() => _cooldownRemaining = rem);
      }
    });
  }

  Future<void> _generateYaminabeQuiz() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _score = 0;
      _isCorrectList = [false, false, false, false];
      for (final controller in _controllers) {
        controller.clear();
      }
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('APIキーが未設定です。.envファイルを確認してください。');
      }

      final prompt = '''
あなたはQuizKnockの「闇鍋クイズ」を作成するAIです。
以下のルールに則って、最高に面白い問題を1問作成し、必ず指定されたJSON形式のみを出力してください。

【ルール】
1. まず、お互いに全く関係のない一般的なクイズを「4つ」用意してください（歴史、科学、芸能、スポーツ、雑学などジャンルはバラバラに）。
2. その4つのクイズの問題文からキーワードや修飾語、名詞などを抽出し、それらを不自然に、かつ1つの滑稽な文章に煮込み合わせて「1つのウソのような闇鍋問題文」を作ってください。
3. プレイヤーはその闇鍋問題文を読んで、元になった4つの独立したクイズの答えを推理します。
4. JSON以外のテキスト（解説や挨拶）は一切出力しないでください。

【出力形式】
{
  "yaminabeQuestion": "合体・煮込み合わされた1つの闇鍋問題文",
  "originalQuizzes": [
    {"question": "元になったクイズ問題文1", "answer": "答え1"},
    {"question": "元になったクイズ問題文2", "answer": "答え2"},
    {"question": "元になったクイズ問題文3", "answer": "答え3"},
    {"question": "元になったクイズ問題文4", "answer": "答え4"}
  ]
}

【例】
元クイズ1: 「あかい」「まるい」「おおきい」「うまい」の頭文字から名付けられた、福岡県産のイチゴの品種は何でしょう？ (答: あまおう)
元クイズ2: ファースト、メリーロード、桃太郎などの品種がある、真っ赤な見た目が鮮やかな夏野菜は何でしょう？ (答: トマト)
元クイズ3: フランス語で「銀」という意味がある、ケーキなどに添えられる銀色をした粒状のお菓子は何でしょう？ (答: アラザン)
元クイズ4: 豆乳ににがりなどを投入して作られる、大豆製品といえば何でしょう？ (答: 豆腐)

闇鍋問題文: フランス語で「あかい銀」という意味がある、まるい豆乳ケーキにおおきい桃太郎などを投入して作られる、福岡県産の真っ赤な銀色が鮮やかな粒状の夏野菜製品といえば何でしょう？
''';

      final responseText = await _generateQuizResponse(apiKey, prompt);

      if (responseText.isEmpty) {
        throw Exception('AIからの返答が空でした。');
      }

      debugPrint('--- AI Response Raw (Yaminabe) ---');
      debugPrint(responseText);

      String jsonString = responseText.trim();
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(jsonString);
      if (jsonMatch != null) {
        jsonString = jsonMatch;
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (mounted) {
        setState(() {
          quizData = YaminabeQuizData.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('--- Error Detail ---');
      debugPrint('message: ${e.toString()}');

      final message = e.toString();
      // クォータ超過を検出してクールダウンを開始
      if (message.toLowerCase().contains('quota') ||
          message.toLowerCase().contains('you exceeded')) {
        // Google のエラーメッセージに "Please retry in XXs" が含まれる場合がある
        final retryMatch = RegExp(
          r'Please retry in ([0-9]+(?:\.[0-9]+)?)s',
          caseSensitive: false,
        ).firstMatch(message);
        int waitSeconds = 60; // デフォルト
        if (retryMatch != null) {
          try {
            final secs = double.parse(retryMatch.group(1)!);
            waitSeconds = secs.ceil();
          } catch (_) {}
        }

        _startCooldown(waitSeconds);

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('クイズ生成エラー: クォータ超過。$waitSeconds秒後に再試行できます。'),
              backgroundColor: Colors.black87,
            ),
          );
        }
      } else {
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
  }

  // 大澤さんが構築した頑強な複数モデルフォールバック通信ロジック
  Future<String> _generateQuizResponse(String apiKey, String prompt) async {
    final modelCandidates = [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
    ];
    const maxRetry = 2;

    for (final modelName in modelCandidates) {
      for (var attempt = 1; attempt <= maxRetry; attempt++) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            requestOptions: const RequestOptions(apiVersion: 'v1'),
          );

          final response = await model.generateContent([Content.text(prompt)]);
          final responseText = response.text;

          if (responseText == null || responseText.isEmpty) {
            throw Exception('AIからの返答が空でした。');
          }

          return responseText;
        } catch (error) {
          final message = error.toString();
          debugPrint('--- Model Error ---');
          debugPrint('model=$modelName attempt=$attempt');
          debugPrint('message=$message');

          // クォータやレートリミット関連の明示的検出
          final lower = message.toLowerCase();
          if (lower.contains('quota') ||
              lower.contains('rate limit') ||
              lower.contains('you exceeded')) {
            throw Exception('Quota exceeded or rate-limited by API: $message');
          }

          if (attempt < maxRetry && _isTemporaryServerError(message)) {
            await Future.delayed(Duration(seconds: 2 * attempt));
            continue; // 同モデルをリトライ
          }

          // ここでは次のモデル候補へ移行
          break;
        }
      }
    }

    // すべて全滅した場合の最終手段として1.5-flashを直接試みる
    final fallbackModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );
    final response = await fallbackModel.generateContent([
      Content.text(prompt),
    ]);
    return response.text ?? '';
  }

  bool _isTemporaryServerError(String message) {
    return message.contains('503') ||
        message.contains('UNAVAILABLE') ||
        message.contains('high demand') ||
        message.contains('currently experiencing high demand');
  }

  // 回答ボタンを押したときの判定ロジック
  // 回談ボタンを押したときの判定ロジック（順不同対応版）
  void _checkAnswers() {
    if (quizData == null) return;

    // 1. AIが用意した4つの正しい答えをリスト化（トリム・小文字化して表記揺れを軽減）
    final List<String> correctAnswers = quizData!.originalQuizzes
        .map((q) => q.answer.trim().toLowerCase())
        .toList();

    // 2. ユーザーが4つの入力欄に書き込んだ答えをリスト化
    final List<String> userAnswers = _controllers
        .map((c) => c.text.trim().toLowerCase())
        .toList();

    int currentScore = 0;
    List<bool> currentCorrectList = [false, false, false, false];

    // まだ使われていない（マッチしていない）正解を管理する一時的なリスト
    final List<String> remainingCorrectAnswers = List.from(correctAnswers);

    // 3. 入力欄ごとに「いずれかの正解」とマッチするか検証
    for (int i = 0; i < 4; i++) {
      final userAnswer = userAnswers[i];
      if (userAnswer.isEmpty) continue;

      // まだマッチしていない正解リストの中から、部分一致または完全一致するものを探す
      String? matchedAnswer;
      for (final correct in remainingCorrectAnswers) {
        if (correct.contains(userAnswer) || userAnswer.contains(correct)) {
          matchedAnswer = correct;
          break;
        }
      }

      // 見つかった場合は正解とし、同じ正解が重複して判定されないようにリストから除外する
      if (matchedAnswer != null) {
        currentCorrectList[i] = true;
        currentScore++;
        remainingCorrectAnswers.remove(matchedAnswer);
      }
    }

    setState(() {
      _isCorrectList = currentCorrectList;
      _score = currentScore;
      _isAnswered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '闇鍋クイズ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE60012),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isLoading || _isCooldownActive())
                ? null
                : _generateYaminabeQuiz,
            tooltip: _isCooldownActive()
                ? '再試行まで残り $_cooldownRemaining秒'
                : '更新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE60012)),
                  SizedBox(height: 20),
                  Text(
                    'AIが4つの問題を煮込み中...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (quizData != null) ...[
                    // 闇鍋問題の表示カード
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C), // 闇鍋感を出すダークカラー
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE60012),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('🍲', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 8),
                              Text(
                                '煮込まれた問題文',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            quizData!.yaminabeQuestion,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 4つの入力欄の生成
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _isAnswered
                                  ? (_isCorrectList[index]
                                        ? Colors.green
                                        : Colors.red)
                                  : const Color(0xFFE60012),
                              child: Text(
                                _isAnswered
                                    ? (_isCorrectList[index] ? '✓' : '✗')
                                    : '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _controllers[index],
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: '答え ${index + 1}',
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                enabled: !_isAnswered,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 15),

                    // 回答・結果ボタン
                    if (!_isAnswered)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE60012),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _checkAnswers,
                          child: const Text(
                            '具材をすべて当てる（回答する）',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // 正解発表・解説エリア（回答後に表示）
                    if (_isAnswered) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '結果: 4問中 $_score 問正解！ 🎉',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '【元になった4つのクイズ】',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE60012),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 4つの元問題と答えのリスト表示
                      ...List.generate(4, (index) {
                        final original = quizData!.originalQuizzes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '問題 ${index + 1}: ${original.question}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      '正解: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Text(
                                      original.answer,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      '(あなたの回答: ${_controllers[index].text.isEmpty ? "未入力" : _controllers[index].text})',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        onPressed: _generateYaminabeQuiz,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          '次の闇鍋を煮込む（次の問題）',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
