// ignore_for_file: unused_import

import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String author;
  final String imagePath;
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
    required this.sections,
    required this.isFeatured,
    required this.isTopPick,
    required this.createdAt,
    this.abstractContent,
    this.readingProgress,
    this.updatedAt,
    this.tags,
    this.kelas,
  });

  factory Article.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<dynamic> rawSections = data['sections'] ?? [];
    List<String>? rawTags;

    if (data['tags'] is List) {
      rawTags = List<String>.from(data['tags']);
    } else if (data['tags'] is String) {
      rawTags = (data['tags'] as String)
          .split(RegExp(r'[,\s]+'))
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    return Article(
      id: documentId,
      createdAt: data['createdAt'] as Timestamp?,
      title: data['title'] as String? ?? 'Untitled',
      author: data['author'] as String? ?? 'Unknown Author',
      imagePath: data['imagePath'] as String? ?? '',
      abstractContent: data['abstractContent'] as String?,
      kelas: data['kelas'] as String?,
      updatedAt: data['updatedAt'] as Timestamp?,

      isFeatured: data['isFeatured'] as bool? ?? false,
      isTopPick: data['isTopPick'] as bool? ?? false,

      sections: rawSections
          .map((item) => item as Map<String, dynamic>)
          .toList(),

      readingProgress: (data['readingProgress'] as num?)?.toDouble(),
      tags: rawTags,
    );
  }
}
