import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/screen/article_reading_screen.dart';
import 'package:vokapedia/utils/color_constants.dart';
import 'package:vokapedia/models/bookmark_model.dart'; 
import 'package:intl/intl.dart'; 

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  Stream<List<BookmarkItem>> _getBookmarksStream() {
    const String userId = 'user123'; 
    
    return FirebaseFirestore.instance
        .collection('user_bookmarks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookmarkItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  void _removeBookmark(BuildContext context, String bookmarkId) {
    FirebaseFirestore.instance
        .collection('user_bookmarks')
        .doc(bookmarkId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Highlight dihapus.'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToArticle(BuildContext context, BookmarkItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleReadingScreen(
          articleId: item.articleId, 
          articleTitle: item.articleTitle,
          articleAuthor: item.author,
          imagePath: '', 
        ),
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
      body: StreamBuilder<List<BookmarkItem>>(
        stream: _getBookmarksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookmarkItems = snapshot.data ?? [];

          if (bookmarkItems.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada teks yang ditandai (highlight).',
                style: TextStyle(color: AppColors.darkGrey),
              ),
            );
          }

          return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              itemCount: bookmarkItems.length,
              itemBuilder: (context, index) {
                final item = bookmarkItems[index];
                return _buildBookmarkCard(context, item);
              },
            );
        },
      ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context, BookmarkItem item) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(item.dateSaved);

    return InkWell(
      onTap: () => _navigateToArticle(context, item), 
      child: Card(
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
                          'by ${item.author} | Saved: $formattedDate',
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
                    onPressed: () => _removeBookmark(context, item.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}