import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarkItem {
  final String id;
  final String articleId;
  final String articleTitle;
  final String author;
  final String highlightedText;
  final DateTime dateSaved;

  BookmarkItem({
    required this.id,
    required this.articleId,
    required this.articleTitle,
    required this.author,
    required this.highlightedText,
    required this.dateSaved,
  });

  factory BookmarkItem.fromFirestore(Map<String, dynamic> data, String documentId) {
    return BookmarkItem(
      id: documentId,
      articleId: data['articleId'] as String? ?? '',
      articleTitle: data['articleTitle'] as String? ?? 'Untitled Article',
      author: data['articleAuthor'] as String? ?? 'Unknown Author',
      highlightedText: data['highlightedText'] as String? ?? '',
      dateSaved: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}