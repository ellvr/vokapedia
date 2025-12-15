// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vokapedia/screen/article_reading_screen.dart';
import 'package:vokapedia/utils/color_constants.dart';
import 'package:vokapedia/models/bookmark_model.dart';
import 'package:intl/intl.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  Stream<List<BookmarkItem>> _getBookmarksStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookmarkItem.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  void _removeBookmark(BuildContext context, String bookmarkId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk menghapus bookmark.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
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

  void _navigateToArticle(BuildContext context, BookmarkItem item) async {
    try {
      final articleDoc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(item.articleId)
          .get();

      if (!articleDoc.exists) {
        throw Exception("Article not found in articles collection.");
      }

      final articleData = articleDoc.data()!;
      final String correctImagePath = articleData['imagePath'] ?? '';

      final user = FirebaseAuth.instance.currentUser;
      double initialProgress = 0.0;
      if (user != null) {
        final historyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('readingHistory')
            .doc(item.articleId)
            .get();
        if (historyDoc.exists) {
          initialProgress =
              historyDoc.data()?['readingProgress']?.toDouble() ?? 0.0;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleReadingScreen(
            articleId: item.articleId,
            articleTitle: item.articleTitle,
            articleAuthor: item.author,
            imagePath: correctImagePath,
            initialProgress: initialProgress,
            highlightedTextToFind: item.highlightedText,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat artikel: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                'Belum ada teks yang ditandai. Yuk mulai highlight',
                style: TextStyle(color: AppColors.darkGrey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
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
    final formattedDate = item.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt!.toDate())
        : 'Unknown Date';

    return InkWell(
      onTap: () => _navigateToArticle(context, item),
      child: Card(
        color: AppColors.backgroundLight,
        margin: const EdgeInsets.only(bottom: 12.0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
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
