// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vokapedia/models/quiz_model.dart';
import 'package:vokapedia/screen/quiz_play_screen.dart';
import 'package:vokapedia/utils/color_constants.dart';

class AllQuizzesScreen extends StatelessWidget {
  const AllQuizzesScreen({super.key});

  Stream<List<Quiz>> _getAllQuizzesStream() {
    return FirebaseFirestore.instance
        .collection('quizzes')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Quiz.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Semua Latihan Kuis",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Quiz>>(
        stream: _getAllQuizzesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Tidak ada kuis"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final quizzes = snapshot.data ?? [];
          if (quizzes.isEmpty) {
            return const Center(
              child: Text(
                "Tidak ada kuis",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              bool isOverdue = DateTime.now().isAfter(quiz.deadline);

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('quiz_submissions')
                    .where('quizID', isEqualTo: quiz.id)
                    .where('studentID', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, subSnap) {
                  bool isAnswered =
                      subSnap.hasData && subSnap.data!.docs.isNotEmpty;
                  String statusLabel = "Ditugaskan";
                  Color statusColor = AppColors.primaryBlue;

                  if (isAnswered) {
                    statusLabel = "Selesai";
                    statusColor = Colors.green;
                  } else if (isOverdue) {
                    statusLabel = "Terlambat";
                    statusColor = Colors.red;
                  }

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizPlayScreen(quiz: quiz),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.assignment_outlined,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quiz.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAnswered
                                      ? "Sudah dikerjakan"
                                      : "Batas waktu: ${quiz.deadline.day}/${quiz.deadline.month}/${quiz.deadline.year}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOverdue && !isAnswered
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
