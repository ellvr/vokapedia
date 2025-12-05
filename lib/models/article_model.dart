class Article {
  final String id;
  final String title;
  final String author;
  final String imagePath;
  final String? abstractContent;
  final List<Map<String, dynamic>> sections;
  final bool isFeatured;
  final bool isTopPick;
  final num? readingProgress;

  Article({
    required this.id,
    required this.title,
    required this.author,
    required this.imagePath,
    required this.sections,
    required this.isFeatured,
    required this.isTopPick,
    this.abstractContent,
    this.readingProgress,
  });

  factory Article.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<dynamic> rawSections = data['sections'] ?? [];

    return Article(
      id: documentId,
      title: data['title'] as String? ?? 'Untitled',
      author: data['author'] as String? ?? 'Unknown Author',
      imagePath: data['imagePath'] as String? ?? '',
      abstractContent: data['abstractContent'] as String?,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isTopPick: data['isTopPick'] as bool? ?? false,
      sections: rawSections
          .map((item) => item as Map<String, dynamic>)
          .toList(),
      readingProgress: data['readingProgress'] as num?,
    );
  }
}
