import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String title;
  final String subject;
  final String desc;
  final String kelas;
  final DateTime deadline;

  Quiz({
    required this.id,
    required this.title,
    required this.subject,
    required this.desc,
    required this.kelas,
    required this.deadline,
  });

  factory Quiz.fromFirestore(Map<String, dynamic> data, String id) {
    return Quiz(
      id: id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      desc: data['desc'] ?? '',
      kelas: data['kelas'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
    );
  }
}
