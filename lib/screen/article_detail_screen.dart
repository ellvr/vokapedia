import 'package:flutter/material.dart';
import 'package:vokapedia/utils/color_constants.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String articleTitle;
  final String articleAuthor;
  final String imagePath;

  const ArticleDetailScreen({
    super.key,
    required this.articleTitle,
    required this.articleAuthor,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          Container(
            // margin: EdgeInsets.all(12.0, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Container(
                        width: 176,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Color(0xFFD9D9D9),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),

                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: AppColors.backgroundLight,
                                child: const Center(
                                  child: Text(
                                    'Cover Image Placeholder',
                                    style: TextStyle(color: AppColors.darkGrey),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      articleTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        top: 8.0,
                        bottom: 15.0,
                      ),
                      child: Text(
                        articleAuthor,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.darkGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: <Widget>[
                          _buildChip(label: 'RPL'),
                          _buildChip(label: 'XI'),
                          _buildChip(label: 'PAPB'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Divider(
                    color: AppColors.darkGrey,
                    thickness: 1.0,
                    height: 1, 
                    indent: 20, 
                    endIndent: 20,
                  ),
                  const SizedBox(height: 25),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Abstract',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'The software development landscape has evolved dramatically over the past decade. What worked in 2015 might not be the best approach today. Modern development teams need to understand various methodologies to choose the right one for their projects. Here\'s a detailed look at twelve methodologies that are shaping software development in 2025. Waterfall remains relevant for projects with well-defined requirements and minimal expected changesxxxxxx The software development landscape has evolved dramatically over the past decade. What worked in 2015 might not be the best approach today. Modern development teams need to understand various methodologies to choose the right one for their projects. Here\'s a detailed look at twelve methodologies that are shaping software development in 2025. Waterfall remains relevant for projects with well-defined requirements and minimal expected changesxxxxxxxxxxxxxxxxxxxx',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.darkGrey,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, top: 5.0),
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Read more',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGrey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: 20,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.menu_book, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Read',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.black,
                        side: const BorderSide(
                          color: AppColors.black,
                          width: 2,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Library',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBlue),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.black),
      ),
    );
  }
}
