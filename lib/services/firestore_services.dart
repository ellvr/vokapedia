import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/models/article_model.dart';

Stream<List<Article>> getContinueReadingArticles() {
  return FirebaseFirestore.instance
      .collection('saved_articles')
      .where('readingProgress', isLessThan: 1.0) 
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) {
          return Article.fromFirestore(doc.data(), doc.id);
        })
        .toList();
  });
}

Stream<List<Article>> getArticlesByFeature({required String field, required bool value}) {
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