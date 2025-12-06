import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarkItem {
  final String id;
  final String articleId; 
  final String articleTitle;
  final String highlightedText;
  final DateTime dateSaved;
  final String author; 

  BookmarkItem({
    required this.id,
    required this.articleId,
    required this.articleTitle,
    required this.highlightedText,
    required this.dateSaved,
    this.author = 'Unknown Author',
  });

  factory BookmarkItem.fromFirestore(Map<String, dynamic> data, String documentId) {
    Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    return BookmarkItem(
      id: documentId,
      articleId: data['articleId'] as String? ?? '',
      articleTitle: data['articleTitle'] as String? ?? 'Untitled Article',
      highlightedText: data['highlightedText'] as String? ?? 'No highlight text.',
      dateSaved: timestamp.toDate(),
      author: data['articleAuthor'] as String? ?? 'User Highlight',
    );
  }
}