import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarkItem {
  final String id;
  final String articleId;
  final String articleTitle;
  final String author;
  final String highlightedText;
  final Timestamp? createdAt;

  BookmarkItem({
    required this.id,
    required this.articleId,
    required this.articleTitle,
    required this.author,
    required this.highlightedText,
    this.createdAt,
  });

  factory BookmarkItem.fromFirestore(Map<String, dynamic> data, String id) {
    return BookmarkItem(
      id: id,
      articleId: data['articleId'] ?? '',
      articleTitle: data['articleTitle'] ?? 'No Title',
      author: data['author'] ?? 'Unknown Author',
      highlightedText: data['highlightedText'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
