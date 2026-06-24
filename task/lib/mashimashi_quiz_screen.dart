import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:task/services/generative_service.dart';

// カスタム選択肢のデータを管理するクラス
class CustomOption {
  final String id;
  final String label;

  CustomOption({required this.id, required this.label});

  factory CustomOption.fromJson(Map<String, dynamic> json) {
    return CustomOption(id: json['id'] ?? '', label: json['label'] ?? '');
  }
}

// 難易度マシマシクイズの初期データを管理するクラス
class MashimashiQuizData {
  final String genre;
  final String originalQuestion;
  final String answer;
  final List<CustomOption> availableCustoms;

  MashimashiQuizData({
    required this.genre,
    required this.originalQuestion,
    required this.answer,
    required this.availableCustoms,
  });

  factory MashimashiQuizData.fromJson(Map<String, dynamic> json) {
    final list = json['availableCustoms'] as List? ?? [];
    final customs = list
        .map((i) => CustomOption.fromJson(i as Map<String, dynamic>))
        .toList();

    return MashimashiQuizData(
      genre: json['genre'] ?? '',
      originalQuestion: json['originalQuestion'] ?? '',
      answer: json['answer'] ?? '',
      availableCustoms: customs,
    );
  }
}

class MashimashiQuizScreen extends StatefulWidget {
  const MashimashiQuizScreen({super.key});

  @override
  State<MashimashiQuizScreen> createState() => _MashimashiQuizScreenState();
}

class _MashimashiQuizScreenState extends State<MashimashiQuizScreen> {
  MashimashiQuizData? quizData;
  String? displayedQuestion; // 画面に表示される（マシマシに変換された）問題文

  bool _isLoading = true;
  bool _isTransforming = false; // マシマシ変換中のフラグ
  bool _isAnswered = false;
  bool _isCustomApplied = false; // カスタムが適用されたかどうか

  final TextEditingController _controller = TextEditingController();

  // プレイヤーが選択したカスタムIDを管理するマップ
  final Map<String, bool> _selectedCustoms = {};

  @override
  void initState() {
    super.initState();
    _generateBaseQuiz();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 1. 最初のクイズ生成
  Future<void> _generateBaseQuiz() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isTransforming = false;
      _isAnswered = false;
      _isCustomApplied = false;
      displayedQuestion = null;
      _selectedCustoms.clear();
      _controller.clear();
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('APIキーが未設定です。.envファイルを確認してください。');
      }

      // プロンプトから「英語交じり」の文言を完全に排除
      // 1. 最初のクイズ生成プロンプトの該当部分を修正
      final prompt = '''
あなたはQuizKnockの「難易度マシマシクイズ」を作成するAIです。
幅広い分野から一般的な知識を問うクイズを1問作成し、指定されたJSON形式のみを出力してください。

【ジャンル選定のルール】
毎回同じジャンル（歴史など）ばかりに偏るのを絶対に避けてください。
[科学、自然、地理、スポーツ、文学・芸術、エンタメ、歴史、生活雑学、テクノロジー] などの幅広い分野から、毎回異なるジャンルを自由に選定してクイズを作成してください。

【ルール】
1. 選定したジャンルに関する一般的な知識を問うクイズを1問作成してください。
2. その問題文の記述内容を分析し、回答者がトッピング（カスタム）を選んで難易度を上げられるような、**その問題文に存在する要素に応じたカスタム選択肢（3〜4個）**を動的に考えて提示してください。

【カスタム選択肢の考え方ルール】
- 問題文に具体的な数値（例：3776m、4年に1度、12個）が含まれる場合 ➔ {"id": "suuji", "label": "数字抜き"} を必ず含める。
- 問題文に具体的な国名、都市名、川や山の名前が含まれる場合 ➔ {"id": "chimei", "label": "地名抜き"} を必ず含める。
- 問題文に人物やグループ、キャラクターの名前が含まれる場合 ➔ {"id": "jinmei", "label": "人名抜き"} を必ず含める。
- **【重要】** もし数字・地名・人名が問題文にない、または足りない場合は、代わりに以下の汎用項目から選んで、合計3〜4個の選択肢を維持してください。
  - {"id": "daku", "label": "濁点マシマシ"} (※これは文章を難読化させるため、毎回必ず含めてください)
  - {"id": "kana", "label": "ひらがな化"} (※漢字をすべてひらがなにして可読性を下げる)
  - {"id": "kata", "label": "カタカナ化"} (※逆にすべてカタカナにして読みにくくする)
- ※「英語交じり」など、上記以外のトッピングは絶対に生成しないでください。

【出力形式】
{
  "genre": "選んだクイズのジャンル（例: 科学、スポーツ、地理 など短く）",
  "originalQuestion": "ベースとなる正しい問題文",
  "answer": "クイズの答え",
  "availableCustoms": [
    {"id": "カスタムID", "label": "画面に表示するトッピング名（例: 地名抜き）"}
  ]
}
''';

      final responseText = await _callGemini(apiKey, prompt);

      String jsonString = responseText.trim();
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(jsonString);
      if (jsonMatch != null) jsonString = jsonMatch;

      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (mounted) {
        setState(() {
          quizData = MashimashiQuizData.fromJson(data);
          displayedQuestion = quizData!.originalQuestion;

          for (var custom in quizData!.availableCustoms) {
            _selectedCustoms[custom.id] = false;
          }
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Base Quiz Generation Error: $e\n$st');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showErrorSnackBar('クイズの初期生成に失敗しました: $e');
      });
    }
  }

  // 2. 選んだカスタムに応じて問題文を安全にマシマシに変形する
  Future<void> _applyMashimashiCustom() async {
    if (quizData == null || !mounted) return;

    final activeCustomIds = quizData!.availableCustoms
        .where((c) => _selectedCustoms[c.id] == true)
        .map((c) => c.id)
        .toList();

    setState(() {
      _isTransforming = true;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      final bool hasSuuji = activeCustomIds.contains('suuji');
      final bool hasChimei = activeCustomIds.contains('chimei');
      final bool hasJinmei = activeCustomIds.contains('jinmei');
      final bool hasKana = activeCustomIds.contains('kana'); // ← これ
      final bool hasKata = activeCustomIds.contains('kata'); // ← これ
      final bool hasDaku =
          activeCustomIds.contains('daku') || _selectedCustoms['daku'] == true;

      // AIには「消すべき対象の単語」だけを徹底して抽出させる
      final prompt =
          '''
あなたはクイズのテキスト加工アシスタントです。
提供された問題文を分析・加工し、指定されたJSON形式のみを出力してください。
※絶対に解説やMarkdownの装飾をせず、純粋なJSONのみを返してください。

【元の問題文】
"${quizData!.originalQuestion}"

【現在のフラグ状態】
- 数字抜きフラグ: $hasSuuji
- 地名抜きフラグ: $hasChimei
- 人名抜きフラグ: $hasJinmei
- ひらがな化フラグ: $hasKana
- カタカナ化フラグ: $hasKata

【処理ルール】
1. ひらがな化フラグが【true】の場合、問題文の漢字部分をできる限り「ひらがな」に変換した文章を「transformedBaseText」に格納してください。（例: 「1862年に発表した」→「1862ねんにはっぴょうした」）
2. カタカナ化フラグが【true】の場合、問題文をできる限り「カタカナ」に変換した文章を「transformedBaseText」に格納してください。（例: 「1862年に発表した」→「1862ネンニハッピョウシタ」）
3. どちらのフラグも【false】の場合は、元の問題文を一言一句変えずにそのまま「transformedBaseText」に格納してください。
4. 地名抜き(true)、人名抜き(true)、数字抜き(true)に該当する具体的な【単語そのもの（例: フランス、ユーゴー、1862年）】を問題文から正確に抽出し、それらを「wordsToRemove」の配列にすべて格納してください。

【出力形式】
{
  "transformedBaseText": "指示に従って変形（または維持）した問題文のベース",
  "wordsToRemove": ["削除対象となる具体的なキーワードのリスト"]
}
''';

      final responseText = await _callGemini(apiKey!, prompt);
      String jsonString = responseText.trim();
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(jsonString);
      if (jsonMatch != null) jsonString = jsonMatch;

      final Map<String, dynamic> transformResult = jsonDecode(jsonString);

      // AIがひらがな化、またはカタカナ化してくれたベーステキストを正しく受け取る
      String resultText =
          transformResult['transformedBaseText'] ?? quizData!.originalQuestion;

      // AIが生成したかもしれない変な後付け濁点コードをここで完全に消滅させる
      resultText = resultText.replaceAll(RegExp(r'[\u3099\u309A]'), '');

      // 1. 【文字抜きの処理】選ばれたチェックボックスの要素だけを確実に狙い撃ちして消す
      final List<dynamic> wordsToRemove =
          transformResult['wordsToRemove'] ?? [];
      for (var word in wordsToRemove) {
        String targetWord = word.toString().trim();
        if (targetWord.isEmpty) continue;

        // --- 【超重要】数字抜きの処理 ---
        if (hasSuuji) {
          // ターゲットの単語から「数字だけ」を抽出（例: 「1862年」→「1862」）
          final onlyDigits = RegExp(r'[0-9０-９]+').stringMatch(targetWord) ?? '';
          if (onlyDigits.isNotEmpty) {
            resultText = resultText.replaceAll(onlyDigits, '');
          }
          // 数字抜きのときは、この単語がアルファベットや漢字（人名など）だった場合に下の処理に流れて消されるのを防ぐ
          continue;
        }

        // --- 地名抜きの処理（チェックが入っている時だけ実行） ---
        if (hasChimei) {
          // AIが抽出した地名リストに含まれる単語（例: フランス、中国など）をピンポイント消去
          // ※人名まで巻き込まないように、AIのリストをそのまま鵜呑みにせずhasChimeiの時だけ動かす
          resultText = resultText.replaceAll(targetWord, '');
        }

        // --- 人名抜きの処理（チェックが入っている時だけ実行） ---
        if (hasJinmei) {
          // AIが抽出した人名（例: ユーゴー、ジャン・バルジャンなど）をピンポイント消去
          resultText = resultText.replaceAll(targetWord, '');
        }
      }

      // バックアップ用の全角・半角数字の強制詰め処理（数字抜きがONのときだけ稼働）
      if (hasSuuji) {
        resultText = resultText.replaceAll(RegExp(r'[0-9０-９]'), '');
      }
      // 隙間のスペースや空白を完全にデリートして密着させる
      resultText = resultText.replaceAll(' ', '').replaceAll('　', '');

      // 2. 【濁点マシマシの処理】
      if (hasDaku) {
        // 安全に濁点文字へ置き換えるための変換テーブル
        final Map<String, String> dakuMap = {
          'は': 'ば',
          'ひ': 'び',
          'ふ': 'ぶ',
          'へ': 'べ',
          'ほ': 'ぼ',
          'か': 'が',
          'き': 'ぎ',
          'く': 'ぐ',
          'け': 'げ',
          'こ': 'ご',
          'さ': 'ざ',
          'し': 'じ',
          'す': 'ず',
          'せ': 'ぜ',
          'そ': 'ぞ',
          'た': 'だ',
          'ち': 'ぢ',
          'つ': 'づ',
          'て': 'で',
          'と': 'ど',
          'う': 'ゔ',
        };

        StringBuffer buffer = StringBuffer();
        final random = Random();

        for (int i = 0; i < resultText.length; i++) {
          String char = resultText[i];
          // 変換マップにあり、かつ80%の確率で置換を行う
          if (dakuMap.containsKey(char) && random.nextDouble() < 0.8) {
            buffer.write(dakuMap[char]);
          } else {
            buffer.write(char);
          }
        }
        resultText = buffer.toString();
      }

      if (mounted) {
        setState(() {
          displayedQuestion = resultText;
          _isCustomApplied = true;
          _isTransforming = false;
        });
      }
    } catch (e, st) {
      debugPrint('Mashimashi Custom Application Error: $e\n$st');
      _showErrorSnackBar('マシマシ変換に失敗しました: $e');
      setState(() => _isTransforming = false);
    }
  }

  // 複数モデル候補フォールバック通信ロジック
  Future<String> _callGemini(String apiKey, String prompt) async {
    return await GenerativeService.generate(prompt);
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UIのリストを作る段階で「英語交じり」を確実に弾き出す防壁ロジック
    final displayCustoms =
        quizData?.availableCustoms
            .where(
              (c) =>
                  c.id != 'english' &&
                  c.id != 'english_mix' &&
                  !c.label.contains('英語'),
            )
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '難易度マシマシクイズ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE60012),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isTransforming ? null : _generateBaseQuiz,
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
                    'AIが特製スープと麺（問題）を準備中...',
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
                crossAxisAlignment:
                    CrossAxisAlignment.start, // ← タイポ箇所を綺麗に修正しました
                children: [
                  if (quizData != null) ...[
                    // ジャンル表示
                    Chip(
                      avatar: const Text('🏷️'),
                      label: Text(
                        'ジャンル: ${quizData!.genre}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.black87,
                    ),
                    const SizedBox(height: 12),

                    // 問題文カード
                    if (_isCustomApplied || _isTransforming) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.deepOrange,
                            width: 2.5,
                          ),
                        ),
                        child: _isTransforming
                            ? const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      'トッピングをスープに混ぜています...',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                displayedQuestion ?? '',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange[900],
                                  height: 1.5,
                                ),
                              ),
                      ),
                      const SizedBox(height: 25),
                    ],

                    // トッピング選択フェーズ（コール前）
                    if (!_isCustomApplied) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text('🔒', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Text(
                              '問題文はコール後に開示されます！',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        '🍜 コール（マシマシカスタムを選択してください）',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: displayCustoms.map((custom) {
                            return CheckboxListTile(
                              title: Text(
                                custom.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              activeColor: Colors.deepOrange,
                              value: _selectedCustoms[custom.id] ?? false,
                              onChanged: (bool? value) {
                                setState(() {
                                  _selectedCustoms[custom.id] = value ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isTransforming
                              ? null
                              : _applyMashimashiCustom,
                          child: const Text(
                            'これで注文する（マシマシにする）',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // 回答フェーズ（コール決定後）
                    if (_isCustomApplied) ...[
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
                      if (!_isAnswered)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE60012),
                            ),
                            onPressed: () => setState(() => _isAnswered = true),
                            child: const Text(
                              '回答する',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      if (_isAnswered) ...[
                        const SizedBox(height: 30),
                        const Divider(thickness: 2),
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0x0DFF0000),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0x33FF0000),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '【元の正しい問題文】',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                quizData!.originalQuestion,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '【正解】',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                quizData!.answer,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE60012),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                            ),
                            onPressed: _generateBaseQuiz,
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                            label: const Text(
                              '次のラーメン（問題）へ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
