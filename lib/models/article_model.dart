import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String author;
  final String imagePath;
  final String topic;
  final String? abstractContent;
  final List<Map<String, dynamic>> sections;
  final bool isFeatured;
  final bool isTopPick;
  final double? readingProgress;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final List<String>? tags;
  final String? kelas;

  Article({
    required this.id,
    required this.title,
    required this.author,
    required this.imagePath,
    required this.topic,
    required this.sections,
    required this.isFeatured,
    required this.isTopPick,
    this.createdAt,
    this.abstractContent,
    this.readingProgress,
    this.updatedAt,
    this.tags,
    this.kelas,
  });

  factory Article.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<String>? rawTags;
    if (data['tags'] is List) {
      rawTags = List<String>.from(data['tags']);
    } else if (data['tags'] is String) {
      rawTags = (data['tags'] as String)
          .split(RegExp(r'[,\s]+'))
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    List<dynamic> rawSections = data['sections'] ?? [];

    return Article(
      id: documentId,
      title: data['title'] as String? ?? 'Untitled',
      author: data['author'] as String? ?? 'Unknown Author',
      imagePath: data['imagePath'] as String? ?? '',
      topic: data['topic'] as String? ?? 'Umum',
      abstractContent: data['abstractContent'] as String?,
      kelas: data['kelas'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isTopPick: data['isTopPick'] as bool? ?? false,
      readingProgress: (data['readingProgress'] as num?)?.toDouble(),
      tags: rawTags,
      sections: rawSections
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'imagePath': imagePath,
      'topic': topic,
      'abstractContent': abstractContent,
      'sections': sections,
      'isFeatured': isFeatured,
      'isTopPick': isTopPick,
      'tags': tags,
      'kelas': kelas,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
