import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/models/article_model.dart';

Stream<List<Article>> getContinueReadingArticles() {
  return FirebaseFirestore.instance
      .collection('saved_articles')
      .where('readingProgress', isLessThan: 1.0)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Article.fromFirestore(doc.data(), doc.id))
            .toList();
      });
}

Stream<List<Article>> getArticlesByFeature({
  required String field,
  required bool value,
}) {
  return FirebaseFirestore.instance
      .collection('articles')
      .where(field, isEqualTo: value)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Article.fromFirestore(doc.data(), doc.id))
            .toList();
      });
}

Stream<List<Article>> getArticlesByTopic(String topicName) {
  return FirebaseFirestore.instance
      .collection('articles')
      .where('topic', isEqualTo: topicName)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Article.fromFirestore(doc.data(), doc.id))
            .toList();
      });
}

Stream<List<Article>> searchArticles(String query) {
  final q = query.toLowerCase().trim();

  return FirebaseFirestore.instance.collection('articles').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs
        .map((doc) => Article.fromFirestore(doc.data(), doc.id))
        .where((article) {
          final title = article.title.toLowerCase();
          final author = article.author.toLowerCase();
          final topic = article.topic.toLowerCase();
          final abstractText = (article.abstractContent ?? "").toLowerCase();

          String extractSectionText(List sections) {
            final buffer = StringBuffer();
            for (var sec in sections) {
              if (sec is Map) {
                final heading = (sec["heading"] ?? "").toString().toLowerCase();
                buffer.write("$heading ");
                final paragraphs = sec["paragraphs"];
                if (paragraphs is List) {
                  buffer.write(
                    paragraphs.map((p) => p.toString().toLowerCase()).join(" "),
                  );
                } else if (paragraphs is String) {
                  buffer.write(paragraphs.toLowerCase());
                }
              }
            }
            return buffer.toString();
          }

          final sectionText = extractSectionText(article.sections);
          final fullText = "$title $author $topic $abstractText $sectionText";

          return fullText.contains(q);
        })
        .toList();
  });
}

String extractSnippet(String fullText, String query) {
  final lower = fullText.toLowerCase();
  final q = query.toLowerCase();

  final index = lower.indexOf(q);
  if (index == -1) return "";

  const snippetLength = 60;

  int start = (index - snippetLength).clamp(0, lower.length);
  int end = (index + q.length + snippetLength).clamp(0, lower.length);

  String snippet = fullText.substring(start, end);
  snippet = snippet.replaceAll("\n", " ");

  if (start > 0) snippet = "...$snippet";
  if (end < lower.length) snippet = "$snippet...";

  return snippet;
}

Stream<List<Article>> getLatestArticles() {
  return FirebaseFirestore.instance
      .collection('articles')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => Article.fromFirestore(doc.data(), doc.id))
            .toList(),
      );
}
