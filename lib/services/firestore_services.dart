// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vokapedia/models/article_model.dart';

Stream<List<Article>> getArticlesByFeature({
  required String field,
  required bool value,
}) {
  return FirebaseFirestore.instance
      .collection('articles')
      .where(field, isEqualTo: value)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Article.fromFirestore(doc.data(), doc.id))
            .toList(),
      );
}


Future<void> writeBookmarkToFirestore({
  required String articleId,
  required String articleTitle,
  required String highlightedText,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    throw Exception('User not logged in. Cannot save bookmark.');
  }

  final bookmarkData = {
    'userId': userId,
    'articleId': articleId,
    'articleTitle': articleTitle,
    'highlightedText': highlightedText,
    'dateSaved': FieldValue.serverTimestamp(),
  };

  try {
    await FirebaseFirestore.instance.collection('bookmarks').add(bookmarkData);

    print('Bookmark saved successfully for user $userId to Firestore.');
  } catch (e) {
    print('Failed to save bookmark: $e');
    rethrow;
  }
}


Stream<List<Article>> getContinueReadingArticles() {
  // Query Firestore: Ambil semua artikel yang tersimpan (saved_articles)
  // dan filter di mana readingProgress kurang dari 1.0
  return FirebaseFirestore.instance
      .collection('saved_articles')
      .where('readingProgress', isLessThan: 1.0) 
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) {
          // Article model sekarang harus mampu menerima data readingProgress
          // FirestoreServices perlu dikonfigurasi untuk mengakses data artikel utama (jika diperlukan)
          // Untuk penyederhanaan, kita mengasumsikan Article model bisa dibuat dari saved_articles data
          // Dan ia memiliki progress yang bisa diakses
          return Article.fromFirestore(doc.data(), doc.id);
        })
        .toList();
  });
}