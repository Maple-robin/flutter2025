import 'package:flutter/material.dart';

class AnswerPage extends StatelessWidget {
  const AnswerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('正解・解説', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF8B0000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text('正解は...', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text(
              '北岳',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF8B0000)),
            ),
            const Divider(height: 60, thickness: 2, indent: 30, endIndent: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('【解説】', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(
                    '山梨県南アルプス市にある標高3,193mの山です。富士山に次いで日本で2番目に高い山として知られています。',
                    style: TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8B0000)),
                foregroundColor: const Color(0xFF8B0000),
              ),
              child: const Text('問題に戻る'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}