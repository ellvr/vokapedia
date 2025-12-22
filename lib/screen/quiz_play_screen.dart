import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vokapedia/models/quiz_model.dart';
import 'package:vokapedia/models/question_model.dart';
import 'package:vokapedia/utils/color_constants.dart';

class QuizPlayScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizPlayScreen({super.key, required this.quiz});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  Future<void> _submitQuiz(List<Question> questions, bool isLate) async {
    bool allFilled = questions.every(
      (q) => _controllers[q.id]?.text.trim().isNotEmpty ?? false,
    );

    if (!allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi semua jawaban sebelum mengirim!"),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    List<Map<String, dynamic>> answers = questions
        .map(
          (q) => {
            'questionId': q.id,
            'answer': _controllers[q.id]?.text.trim() ?? '',
          },
        )
        .toList();

    await FirebaseFirestore.instance.collection('quiz_submissions').add({
      'quizID': widget.quiz.id,
      'studentID': user?.uid,
      'answers': answers,
      'submittedAt': FieldValue.serverTimestamp(),
      'status': isLate ? 'submitted_late' : 'submitted',
      'score': null,
      'feedback': '',
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLate ? "Kuis dikirim (Terlambat)!" : "Kuis berhasil dikirim!",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isOverdue = DateTime.now().isAfter(widget.quiz.deadline);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz_submissions')
            .where('quizID', isEqualTo: widget.quiz.id)
            .where('studentID', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, subSnap) {
          bool isAnswered = subSnap.hasData && subSnap.data!.docs.isNotEmpty;
          Map<String, String> prevAnswers = {};
          String submissionStatus = '';
          dynamic score;
          String feedback = '';

          if (isAnswered) {
            var data = subSnap.data!.docs.first.data() as Map<String, dynamic>;
            submissionStatus = data['status'] ?? 'submitted';
            score = data['score'];
            feedback = data['feedback'] ?? '';
            List answers = data['answers'] ?? [];
            for (var a in answers) prevAnswers[a['questionId']] = a['answer'];
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('quiz_questions')
                .where('quizID', isEqualTo: widget.quiz.id)
                .orderBy('order')
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final questions = snapshot.data!.docs
                  .map(
                    (doc) => Question.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

              return Column(
                children: [
                  if (isAnswered) ...[
                    Container(
                      width: double.infinity,
                      color: submissionStatus == 'submitted_late'
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        submissionStatus == 'submitted_late'
                            ? "Kuis ini diserahkan terlambat"
                            : "Yayy kamu sudah mengerjakan kuis ini!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: submissionStatus == 'submitted_late'
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (score != null)
                      Container(
                        margin: const EdgeInsets.all(15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Nilai Akhir:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "$score",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            if (feedback.isNotEmpty) ...[
                              const Divider(height: 20),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Feedback Guru:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  feedback,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                  if (!isAnswered && isOverdue)
                    Container(
                      width: double.infinity,
                      color: Colors.red.shade50,
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        "Peringatan: Deadline sudah lewat. Status pengiriman akan tercatat 'Terlambat'.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        if (!isAnswered)
                          _controllers.putIfAbsent(
                            q.id,
                            () => TextEditingController(),
                          );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pertanyaan ${index + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q.questionText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 15),
                            isAnswered
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      prevAnswers[q.id] ?? "-",
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                : TextField(
                                    controller: _controllers[q.id],
                                    maxLines: 5,
                                    decoration: InputDecoration(
                                      hintText:
                                          "Ketik jawaban esai kamu di sini...",
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primaryBlue,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                  ),
                            const SizedBox(height: 30),
                          ],
                        );
                      },
                    ),
                  ),
                  if (!isAnswered)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitQuiz(questions, isOverdue),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOverdue
                                ? Colors.orange
                                : AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  isOverdue
                                      ? "Kirim (Terlambat)"
                                      : "Kirim Jawaban",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
