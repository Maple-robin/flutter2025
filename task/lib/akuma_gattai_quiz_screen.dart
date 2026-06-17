import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AkumaGattaiQuizData {
  final String question;
  final String wordA;
  final String wordB;
  final String answer;
  final String reading;
  final String overlap;
  final String explanation;

  AkumaGattaiQuizData({
    required this.question,
    required this.wordA,
    required this.wordB,
    required this.answer,
    required this.reading,
    required this.overlap,
    required this.explanation,
  });

  factory AkumaGattaiQuizData.fromJson(Map<String, dynamic> json) {
    return AkumaGattaiQuizData(
      question: (json['question'] ?? '').toString(),
      wordA: (json['wordA'] ?? '').toString(),
      wordB: (json['wordB'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      reading: (json['reading'] ?? '').toString(),
      overlap: (json['overlap'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
    );
  }
}

class AkumaGattaiQuizScreen extends StatefulWidget {
  const AkumaGattaiQuizScreen({super.key});

  @override
  State<AkumaGattaiQuizScreen> createState() => _AkumaGattaiQuizScreenState();
}

class _AkumaGattaiQuizScreenState extends State<AkumaGattaiQuizScreen> {
  AkumaGattaiQuizData? quiz;
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  bool _isAnswered = false;
  bool _isCorrect = false;
  Timer? _cooldownTimer;
  DateTime? _cooldownUntil;
  int _cooldownRemaining = 0;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool _isCooldownActive() {
    return _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    _cooldownUntil = DateTime.now().add(Duration(seconds: seconds));
    _cooldownRemaining = seconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _cooldownUntil!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        timer.cancel();
        _cooldownUntil = null;
        if (mounted) setState(() => _cooldownRemaining = 0);
      } else {
        if (mounted) setState(() => _cooldownRemaining = remaining);
      }
    });
  }

  Future<void> _generateQuiz() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _isCorrect = false;
      _controller.clear();
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEYが設定されていません。.envを確認してください。');
      }

      AkumaGattaiQuizData? parsedQuiz;
      Object? lastValidationError;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          final responseText = await _generateQuizResponse(
            apiKey,
            _buildPrompt(),
          );
          final data = _parseJsonObject(responseText);
          final candidateQuiz = AkumaGattaiQuizData.fromJson(data);
          _validateQuiz(candidateQuiz);
          parsedQuiz = candidateQuiz;
          break;
        } catch (e) {
          lastValidationError = e;
          if (_isQuotaError(e.toString())) rethrow;
          debugPrint('Akuma gattai validation retry $attempt: $e');
        }
      }

      if (parsedQuiz == null) {
        throw Exception('安全な問題を生成できませんでした: $lastValidationError');
      }
      final safeQuiz = parsedQuiz;

      if (mounted) {
        setState(() {
          quiz = safeQuiz;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Akuma gattai quiz generation error: $e');
      final waitSeconds = _retrySecondsFromError(e.toString());
      if (waitSeconds != null) {
        _startCooldown(waitSeconds);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              waitSeconds == null
                  ? 'クイズ生成に失敗しました: $e'
                  : 'APIの利用上限に達しました。$waitSeconds秒後に再試行できます。',
            ),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  String _buildPrompt() {
    return '''
あなたは2つの言葉を不気味に融合させて、QuizKnock風の超難関パズルクイズを作るAIです。
日本語として語感が良く、誰もが「座布団1枚！」と言いたくなるような美しい悪魔合体クイズを1問作成し、指定されたJSON形式のみを出力してください。

【悪魔合体クイズの作成ルール】
1. **「語感の良い合体ワード」の生成**:
   一般的な固有名詞や名詞（歴史人物、文学、科学、地理、アニメ、映画、スポーツ、一般常識など幅広いジャンル）から独立した2つの言葉（wordA、wordB）を選んでください。
   wordAの最後とwordBの最初が「1〜3文字程度」綺麗に重なる（overlap）ように合体させて、1つの美しい新しい答えの単語（answer）と、その読み方（reading）を作ってください。
   必ずリズムが良く、パズルとして成立する綺麗な合体にしてください。

2. **「悪魔合体問題文（question）」の作成ルール（※超重要・ここを厳守）**:
   - **【最重要】架空のSF・ファンタジー・嘘の物語を捏造して問題文にしてはなりません。** あくまで「現実にあるクイズとしての正しい知識」を融合させてください。
   - wordAに関する「現実の正しいクイズ問題文」の要素と、wordBに関する「現実の正しいクイズ問題文」の要素を、1つの文章に絶妙にミックスさせてください。
   - 下記の成功例のように、一方のキーワードをもう一方のパロディ風に入れ替えたり、文章の着地（語尾）をもう一方の要素に繋げることで、高いクイズクリティを実現してください。

3. **【絶対厳守のNGルール（ネタバレ防止）】**:
   - 生成する問題文（question）の中に、合体後の答え（answer）や、元の単語（wordA, wordB）の文字そのものを絶対に入れてはなりません。（例：「銀河鉄道の夜」や「鉄棒」という単語そのものを問題文に書くのは完全にNGです。別の表現や世界観に言い換えてください。）

【最高のお手本（成功例）】
＜例1: クイズ知識パロディ系＞
- wordA: 銀河鉄道の夜（ぎんがてつどうのよる）
- wordB: 鉄棒（てつぼう）
- answer: 銀河鉄棒の夜（ぎんがてつぼうのよる）
- reading: ぎんがてつぼうのよる
- overlap: てつ
- question: 主人公の「ミヤチ」が夢の中で親友の「オノ」とともに宇宙を旅するといえば、いずれもどんな宮沢賢治の技？
- explanation: 宮沢賢治の童話『銀河鉄道の夜』の要素（宇宙を旅する、主人公ジョバンニをミヤチ・カムパネルラをオノに変形）と、体操器具の『鉄棒』の要素（技）を悪魔合体させた問題です。

＜例2: 語感・ダジャレひらめき系＞
- wordA: 富士山（ふじさん）
- wordB: サンタクロース（さんたくろーす）
- answer: 富士山タクロース（ふじさんたくろーす）
- reading: ふじさんたくろーす
- overlap: さん
- question: 日本一高い標高を誇り、クリスマスになると良い子にプレゼントを配ってまわる山は何？
- explanation: 日本最高峰の『富士山』と、クリスマスにプレゼントを配る『サンタクロース』が「さん」の部分で融合した問題です。

【出力形式】
{
  "question": "2つの現実の要素をミックスした、嘘の物語ではない自然なクイズ問題文",
  "wordA": "元の言葉A",
  "wordB": "元の言葉B",
  "answer": "悪魔合体した答えの単語（漢字・カタカナ交じり等、正式な表記）",
  "reading": "答えの読み仮名（すべてひらがな）",
  "overlap": "重なっている文字（例: てつ、さん）",
  "explanation": "なぜその問題文になるのか、元の2つの要素を解説する文章"
}

上記のJSONのみを出力してください。Markdown、コードブロック、補足説明、挨拶は禁止です。
成功例と同じ題材は使わず、新しい1問を作ってください。
''';
  }

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
          final text = response.text;
          if (text == null || text.trim().isEmpty) {
            throw Exception('AIから空の応答が返りました。');
          }
          return text;
        } catch (error) {
          final message = error.toString();
          debugPrint('model=$modelName attempt=$attempt error=$message');

          if (_isQuotaError(message)) {
            rethrow;
          }

          if (attempt < maxRetry && _isTemporaryServerError(message)) {
            await Future.delayed(Duration(seconds: 2 * attempt));
            continue;
          }

          break;
        }
      }
    }

    throw Exception('すべてのモデルでクイズ生成に失敗しました。');
  }

  Map<String, dynamic> _parseJsonObject(String responseText) {
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(responseText);
    if (jsonMatch == null) {
      throw FormatException('JSON形式の応答ではありません。', responseText);
    }
    final decoded = jsonDecode(jsonMatch);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSONのルートがオブジェクトではありません。');
    }
    return decoded;
  }

  void _validateQuiz(AkumaGattaiQuizData data) {
    final requiredValues = [
      data.question,
      data.wordA,
      data.wordB,
      data.answer,
      data.reading,
      data.overlap,
      data.explanation,
    ];
    if (requiredValues.any((value) => value.trim().isEmpty)) {
      throw Exception('AIの応答に必要な項目が足りません。');
    }

    final normalizedQuestion = _normalizeForJudge(data.question);
    final spoilers = [data.answer, data.wordA, data.wordB]
        .map(_normalizeForJudge)
        .where((value) => value.isNotEmpty);
    if (spoilers.any(normalizedQuestion.contains)) {
      throw Exception('問題文に答えや元の言葉が含まれていたため、生成をやり直してください。');
    }
  }

  void _checkAnswer() {
    final currentQuiz = quiz;
    if (currentQuiz == null) return;

    final userAnswer = _normalizeForJudge(_controller.text);
    final acceptedAnswers = {
      _normalizeForJudge(currentQuiz.answer),
      _normalizeForJudge(currentQuiz.reading),
    };

    setState(() {
      _isCorrect = userAnswer.isNotEmpty && acceptedAnswers.contains(userAnswer);
      _isAnswered = true;
    });
  }

  String _normalizeForJudge(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      var code = rune;
      if (code >= 0x30A1 && code <= 0x30F6) {
        code -= 0x60;
      }
      final char = String.fromCharCode(code).toLowerCase();
      if (RegExp(r'[ぁ-んa-z0-9一-龥々〆ヵヶー]').hasMatch(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  bool _isTemporaryServerError(String message) {
    return message.contains('503') ||
        message.contains('UNAVAILABLE') ||
        message.contains('high demand') ||
        message.contains('currently experiencing high demand');
  }

  bool _isQuotaError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('quota') ||
        lower.contains('rate limit') ||
        lower.contains('you exceeded') ||
        lower.contains('please retry in');
  }

  int? _retrySecondsFromError(String message) {
    if (!_isQuotaError(message)) return null;

    final retryMatch = RegExp(
      r'Please retry in ([0-9]+(?:\.[0-9]+)?)s',
      caseSensitive: false,
    ).firstMatch(message);
    if (retryMatch == null) return 60;

    return double.tryParse(retryMatch.group(1) ?? '')?.ceil() ?? 60;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F1),
      appBar: AppBar(
        title: const Text(
          '悪魔合体クイズ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF141118),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isLoading || _isCooldownActive()) ? null : _generateQuiz,
            tooltip: _isCooldownActive()
                ? '再試行まで残り $_cooldownRemaining 秒'
                : '新しい問題',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B1E2D)),
                  SizedBox(height: 20),
                  Text(
                    'AIが言葉を合体中...',
                    style: TextStyle(
                      color: Color(0xFF5D5558),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (quiz != null) ...[
                    _QuestionCard(question: quiz!.question),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      enabled: !_isAnswered,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_isAnswered) _checkAnswer();
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '合体ワードを入力',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E2D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isAnswered ? null : _checkAnswer,
                        icon: const Icon(Icons.check),
                        label: const Text(
                          '回答する',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_isAnswered) ...[
                      const SizedBox(height: 24),
                      _ResultPanel(
                        isCorrect: _isCorrect,
                        quiz: quiz!,
                        userAnswer: _controller.text,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: (_isLoading || _isCooldownActive())
                            ? null
                            : _generateQuiz,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('次の悪魔合体へ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B1E2D),
                          side: const BorderSide(color: Color(0xFF8B1E2D)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF141118),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8B1E2D), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFD7B46A)),
              SizedBox(width: 8),
              Text(
                '問題',
                style: TextStyle(
                  color: Color(0xFFD7B46A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.isCorrect,
    required this.quiz,
    required this.userAnswer,
  });

  final bool isCorrect;
  final AkumaGattaiQuizData quiz;
  final String userAnswer;

  @override
  Widget build(BuildContext context) {
    final accent = isCorrect ? const Color(0xFF237A57) : const Color(0xFF8B1E2D);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCorrect ? Icons.verified : Icons.lightbulb, color: accent),
              const SizedBox(width: 8),
              Text(
                isCorrect ? '正解' : '答え合わせ',
                style: TextStyle(
                  color: accent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            quiz.answer,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF141118),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quiz.reading,
            style: const TextStyle(color: Color(0xFF5D5558), fontSize: 16),
          ),
          const Divider(height: 28),
          _InfoRow(label: '元の言葉A', value: quiz.wordA),
          _InfoRow(label: '元の言葉B', value: quiz.wordB),
          _InfoRow(label: '重なり', value: quiz.overlap),
          if (userAnswer.trim().isNotEmpty)
            _InfoRow(label: 'あなたの回答', value: userAnswer),
          const SizedBox(height: 10),
          Text(
            quiz.explanation,
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B1E2D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
