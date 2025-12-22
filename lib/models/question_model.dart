class Question {
  final String id;
  final String quizID;
  final String questionText;
  final int minLength;
  final int maxLength;

  Question({
    required this.id,
    required this.quizID,
    required this.questionText,
    required this.minLength,
    required this.maxLength,
  });

  factory Question.fromFirestore(Map<String, dynamic> data, String id) {
    return Question(
      id: id,
      quizID: data['quizID'] ?? '',
      questionText: data['question'] ?? '',
      minLength: data['minLength'] ?? 0,
      maxLength: data['maxLength'] ?? 500,
    );
  }
}
