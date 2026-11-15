import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/education_model.dart';
import '../../services/sirkula_repository.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akademi Pilah Mas JOS Jogja'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: const Color(0xFF78909C),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: '5 Aksi Mas JOS'),
            Tab(icon: Icon(Icons.quiz), text: 'Kuis Evaluasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MasJosModulesTab(),
          _MasJosQuizTab(),
        ],
      ),
    );
  }
}

class _MasJosModulesTab extends StatelessWidget {
  const _MasJosModulesTab();

  @override
  Widget build(BuildContext context) {
    final modules = EducationModule.masJosModules;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.volunteer_activism, color: AppTheme.primaryGreen, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Gerakan Mas JOS (Masyarakat Jogja Olah Sampah)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Aplikasi SIRKULA-JOGJA terintegrasi penuh dengan 5 pilar aksi persampahan Pemerintah Kota Yogyakarta untuk mengurangi timbulan residu dari tingkat rumah tangga.',
                style: TextStyle(fontSize: 12, color: Color(0xFF37474F), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Modules Expandable List
        ...modules.map((mod) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 22),
              ),
              title: Text(mod.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: Text(mod.actionNumber, style: const TextStyle(fontSize: 11, color: AppTheme.primaryMedium, fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const Divider(),
                Text(mod.fullContent, style: const TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF455A64))),
                const SizedBox(height: 12),
                const Text('Tips Praktis di Rumah:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGreen)),
                const SizedBox(height: 4),
                ...mod.practicalTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                      Expanded(child: Text(tip, style: const TextStyle(fontSize: 12, color: Color(0xFF37474F)))),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Rujukan: ${mod.jogjaPolicyRef}',
                    style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF757575)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MasJosQuizTab extends StatefulWidget {
  const _MasJosQuizTab();

  @override
  State<_MasJosQuizTab> createState() => _MasJosQuizTabState();
}

class _MasJosQuizTabState extends State<_MasJosQuizTab> {
  final List<QuizQuestion> _questions = QuizQuestion.sampleQuestions;
  final Map<int, int> _selectedAnswers = {};
  bool _quizSubmitted = false;
  int _score = 0;

  void _calculateScore() {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctIndex) {
        correct++;
      }
    }
    final finalScore = ((correct / _questions.length) * 100).round();
    setState(() {
      _score = finalScore;
      _quizSubmitted = true;
    });

    final repo = SirkulaRepository();
    repo.recordQuizScore('quiz_masjos_01', finalScore);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kuis selesai! Skor Anda: $finalScore. Bonus +50 Poin ditambahkan ke dompet Anda.'),
        backgroundColor: AppTheme.primaryMedium,
      ),
    );
  }

  void _resetQuiz() {
    setState(() {
      _selectedAnswers.clear();
      _quizSubmitted = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quiz Header Score Banner
        if (_quizSubmitted) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _score >= 75
                    ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                    : [const Color(0xFFE65100), const Color(0xFFBF360C)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Hasil Pemahaman Kuis Mas JOS', style: TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 4),
                Text('$_score%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                Text(
                  _score >= 75
                      ? 'Luar biasa! Anda memahami 5 Aksi Mas JOS dengan sangat baik.'
                      : 'Bagus! Pelajari kembali materi modul di atas untuk memperdalam pemahaman.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _resetQuiz,
                  child: const Text('Ulangi Kuis'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        const Text(
          'Evaluasi Pemahaman Pemilahan Sampah',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen),
        ),
        const Text(
          'Jawab pertanyaan berikut untuk menguji pemahaman Anda dan dapatkan bonus 50 poin!',
          style: TextStyle(fontSize: 12, color: Color(0xFF616161)),
        ),
        const SizedBox(height: 14),

        // Questions
        ...List.generate(_questions.length, (qIndex) {
          final q = _questions[qIndex];
          final isAnswered = _selectedAnswers.containsKey(qIndex);
          final userChoice = _selectedAnswers[qIndex];
          final isCorrect = userChoice == q.correctIndex;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primaryGreen,
                        child: Text('${qIndex + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q.question,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(q.options.length, (optIndex) {
                    final isSelected = userChoice == optIndex;
                    Color? tileColor;
                    if (_quizSubmitted) {
                      if (optIndex == q.correctIndex) {
                        tileColor = const Color(0xFFE8F5E9);
                      } else if (isSelected && !isCorrect) {
                        tileColor = const Color(0xFFFFEBEE);
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: RadioListTile<int>(
                        value: optIndex,
                        groupValue: userChoice,
                        activeColor: AppTheme.primaryGreen,
                        dense: true,
                        title: Text(q.options[optIndex], style: const TextStyle(fontSize: 12)),
                        onChanged: _quizSubmitted
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedAnswers[qIndex] = val!;
                                });
                              },
                      ),
                    );
                  }),
                  if (_quizSubmitted) ...[
                    const Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? AppTheme.primaryGreen : Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            q.explanation,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF455A64), fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        if (!_quizSubmitted) ...[
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _selectedAnswers.length == _questions.length ? _calculateScore : null,
            child: const Text('Kirim Jawaban Kuis'),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
