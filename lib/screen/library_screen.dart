// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/utils/color_constants.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Stream<List<Article>> _getLibraryItems() {
    return FirebaseFirestore.instance
        .collection('saved_articles')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Article.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  void _removeItem(BuildContext context, String articleId) {
    FirebaseFirestore.instance
        .collection('saved_articles')
        .doc(articleId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item dihapus dari Library.'),
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
          'Library',
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
      body: StreamBuilder<List<Article>>(
        stream: _getLibraryItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final libraryItems = snapshot.data ?? [];

          if (libraryItems.isEmpty) {
            return const Center(
              child: Text(
                'Library masih kosong. Yuk, tambahkan artikel!',
                style: TextStyle(color: AppColors.darkGrey),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15.0,
                      mainAxisSpacing: 15.0,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: libraryItems.length,
                    itemBuilder: (context, index) {
                      final item = libraryItems[index];
                      return _buildGridCard(context, item);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, Article item) {
    final double progress = item.readingProgress?.toDouble() ?? 0.0;
    
    final bool isFinished = progress >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.darkGrey.withOpacity(0.1),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.darkGrey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFinished ? AppColors.primaryBlue : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    isFinished
                        ? const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppColors.primaryBlue,
                          )
                        : const Icon(
                            Icons.menu_book, 
                            size: 20,
                            color: AppColors.black,
                          ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeItem(context, item.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}