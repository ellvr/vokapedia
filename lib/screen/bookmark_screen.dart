// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vokapedia/utils/color_constants.dart';
import 'package:vokapedia/models/bookmark_model.dart'; 

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  static final List<BookmarkItem> _bookmarkItems = [
    BookmarkItem(
      articleTitle: '12 Software Engineering Methodologies Every Developer Must Master in 2025',
      author: 'Taufik Rahmat',
      highlightedText: 'The software development landscape has evolved dramatically over the past decade.',
      dateSaved: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BookmarkItem(
      articleTitle: 'What is Scrum and Why Use It?',
      author: 'Jane Doe',
      highlightedText: 'Scrum is a framework within which people can address complex adaptive problems, while productively and creatively delivering products of the highest possible value.',
      dateSaved: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static void addBookmark(BookmarkItem item) {
    _bookmarkItems.add(item);
  }

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<BookmarkItem> get _bookmarkItems => BookmarkScreen._bookmarkItems;

  void _removeBookmark(BookmarkItem item) {
    setState(() {
      _bookmarkItems.remove(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Highlight dihapus.'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Bookmarks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _bookmarkItems.isEmpty
          ? const Center(
              child: Text(
                'Belum ada teks yang ditandai (highlight).',
                style: TextStyle(color: AppColors.darkGrey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              itemCount: _bookmarkItems.length,
              itemBuilder: (context, index) {
                final item = _bookmarkItems[index];
                return _buildBookmarkCard(item);
              },
            ),
    );
  }

  Widget _buildBookmarkCard(BookmarkItem item) {
    return Card(
      color: AppColors.backgroundLight,
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.highlightedText,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: AppColors.black,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.articleTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${item.author}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _removeBookmark(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}