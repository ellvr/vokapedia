import 'package:flutter/material.dart';
import 'package:vokapedia/utils/color_constants.dart';

class ContentItem {
  final String imagePath;
  final String title;
  final String? subtitle;

  ContentItem({required this.imagePath, required this.title, this.subtitle});
}

final List<ContentItem> _libraryContent = [
  ContentItem(
    imagePath: 'assets/img/reading_1.png',
    title: '12 Methodologies Every Developer Must Master in 2025',
  ),
  ContentItem(
    imagePath: 'assets/img/reading_2.png',
    title: 'Data-Driven or Intuition-Base Decision',
  ),
  ContentItem(
    imagePath: 'assets/img/reading_3.png',
    title: 'What does it really take to reach the top 1% in 2025',
  ),
  ContentItem(
    imagePath: 'assets/img/pick_1.png',
    title: 'All about product manager! What is t..',
  ),
  ContentItem(
    imagePath: 'assets/img/pick_2.png',
    title: 'Data-Driven or Intuition-Base Dec..',
  ),
];

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Library',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Available Offline',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 15),
            _buildContentGrid(context),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildContentGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 18.0,
        mainAxisSpacing: 25.0,
        childAspectRatio: 0.65,
      ),
      itemCount: _libraryContent.length,
      itemBuilder: (context, index) {
        final item = _libraryContent[index];
        return _buildGridCard(item);
      },
    );
  }

  Widget _buildGridCard(ContentItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Gambar hilang',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: AppColors.darkGrey),
                        ),
                      );
                    },
                  ),
                  const Positioned(
                    right: 8,
                    bottom: 8,
                    child: Icon(
                      Icons.file_download_done,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}