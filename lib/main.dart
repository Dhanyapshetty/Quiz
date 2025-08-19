import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final quizState = QuizState();
  await quizState.loadBestScore(); // load best score before UI starts
  runApp(MyApp(state: quizState));
}

/// ------------------ DATA & STATE ------------------

class Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  const Question({
    required this.text,
    required this.options,
    required this.correctIndex,
  });
}

class QuizState {
  final List<Question> questions = const [
    Question(
      text: 'Which widget provides the basic Material Design page layout?',
      options: ['Container', 'Scaffold', 'Column', 'MaterialApp'],
      correctIndex: 1,
    ),
    Question(
      text: 'Which keyword makes a widget rebuild when its state changes?',
      options: ['StatelessWidget', 'final', 'setState', 'const'],
      correctIndex: 2,
    ),
    Question(
      text: 'Which file lists your dependencies in Flutter?',
      options: [
        'pubspec.yaml',
        'build.gradle',
        'main.dart',
        'AndroidManifest.xml'
      ],
      correctIndex: 0,
    ),
  ];

  List<int?> selected;
  int bestScore = 0;

  QuizState() : selected = List<int?>.filled(3, null);

  int get score {
    int s = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selected[i] == questions[i].correctIndex) s++;
    }
    return s;
  }

  Future<void> loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    bestScore = prefs.getInt('bestScore') ?? 0;
  }

  Future<void> updateBestScoreIfNeeded() async {
    if (score > bestScore) {
      bestScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bestScore', bestScore);
    }
  }

  void reset() {
    selected = List<int?>.filled(questions.length, null);
  }
}

/// ------------------ APP ROOT ------------------

class MyApp extends StatelessWidget {
  final QuizState state;
  const MyApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: QuestionScreen(state: state, index: 0),
    );
  }
}

/// ------------------ QUESTION SCREEN ------------------

class QuestionScreen extends StatefulWidget {
  final QuizState state;
  final int index;
  const QuestionScreen({super.key, required this.state, required this.index});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  @override
  Widget build(BuildContext context) {
    final q = widget.state.questions[widget.index];
    final isFirst = widget.index == 0;
    final isLast = widget.index == widget.state.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Question ${widget.index + 1}/${widget.state.questions.length}'),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                  'Best: ${widget.state.bestScore}/${widget.state.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(q.text,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: q.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  return RadioListTile<int>(
                    title: Text(q.options[i]),
                    value: i,
                    groupValue: widget.state.selected[widget.index],
                    onChanged: (val) {
                      setState(() {
                        widget.state.selected[widget.index] = val;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isFirst)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuestionScreen(
                                state: widget.state, index: widget.index - 1),
                          ),
                        );
                      },
                      child: const Text('Previous'),
                    ),
                  ),
                if (!isFirst) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Check if option selected
                      if (widget.state.selected[widget.index] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please select an option before proceeding.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      if (isLast) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ResultScreen(state: widget.state)),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuestionScreen(
                                state: widget.state, index: widget.index + 1),
                          ),
                        );
                      }
                    },
                    child: Text(isLast ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------ RESULT SCREEN ------------------

class ResultScreen extends StatefulWidget {
  final QuizState state;
  const ResultScreen({super.key, required this.state});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.state.updateBestScoreIfNeeded();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.state.questions.length;
    final score = widget.state.score;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Result'),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Best: ${widget.state.bestScore}/$total',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0.5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Score',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('$score / $total',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: total,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final q = widget.state.questions[i];
                  final sel = widget.state.selected[i];
                  final selectedText =
                      sel == null ? 'Not answered' : q.options[sel];
                  final correct = q.options[q.correctIndex];
                  final isCorrect =
                      sel != null && sel == q.correctIndex;

                  return ListTile(
                    tileColor: Colors.grey.shade50,
                    title: Text('Q${i + 1}. ${q.text}'),
                    subtitle: Text(
                        'Your answer: $selectedText\nCorrect answer: $correct'),
                    trailing: Icon(isCorrect
                        ? Icons.check_circle
                        : Icons.cancel),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                QuestionScreen(state: widget.state, index: i)),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                QuestionScreen(state: widget.state, index: 0)),
                      );
                    },
                    child: const Text('Review Answers'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.state.reset();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                QuestionScreen(state: widget.state, index: 0)),
                        (route) => false,
                      );
                    },
                    child: const Text('Retake Quiz'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
