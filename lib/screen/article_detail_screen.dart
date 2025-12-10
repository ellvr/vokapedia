// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/screen/article_reading_screen.dart';
import 'package:vokapedia/screen/home_screen.dart';
import 'package:vokapedia/utils/color_constants.dart';
import 'dart:async';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;

  const ArticleDetailScreen({
    super.key,
    required this.articleId,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final bool _isAbstractExpanded = false;
  bool _isArticleSaved = false; 

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final doc = await FirebaseFirestore.instance
        .collection('saved_articles')
        .doc(widget.articleId)
        .get();
    
    if (mounted) {
      setState(() {
        _isArticleSaved = doc.exists;
      });
    }
  }

  Future<Article> _fetchArticleDetail() async {
    final doc = await FirebaseFirestore.instance.collection('articles').doc(widget.articleId).get();
    if (!doc.exists) {
      throw Exception("Article not found in database.");
    }
    return Article.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  
  String _getArticleContentPreview(Article article, {int wordLimit = 50}) {
    String fullContent = '';
    
    if (article.abstractContent != null && article.abstractContent!.isNotEmpty) {
      fullContent += article.abstractContent! + '\n\n';
    }

    for (var section in article.sections) {
       fullContent += (section['sectionTitle'] ?? '') + ' ' + (section['content'] ?? '') + ' ';
    }
    
    if (fullContent.trim().isEmpty) {
      return 'Konten artikel belum tersedia.';
    }

    final words = fullContent.trim().split(RegExp(r'\s+'));
    
    if (words.length <= wordLimit) {
      return fullContent.trim();
    }
    
    final preview = words.sublist(0, wordLimit).join(' ');
    
    return '$preview...';
  }

  Future<void> _toggleLibraryStatus(Article article) async {
    final docRef = FirebaseFirestore.instance.collection('saved_articles').doc(article.id);
    
    if (_isArticleSaved) {
      await docRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dihapus dari Library.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      await docRef.set({
        'title': article.title,
        'author': article.author,
        'imagePath': article.imagePath,
        'savedAt': FieldValue.serverTimestamp(),
        'readingProgress': 0.0,
      }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil ditambahkan ke Library!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    setState(() {
      _isArticleSaved = !_isArticleSaved;
    });

    if (_isArticleSaved) {
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 2),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share, color: AppColors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: AppColors.black), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<Article>(
        future: _fetchArticleDetail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error memuat artikel: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Artikel tidak ditemukan.'));
          }

          final article = snapshot.data!;
          
          return _buildDetailBody(context, article);
        },
      ),
    );
  }

  Widget _buildDetailBody(BuildContext context, Article article) {
    final buttonIcon = _isArticleSaved ? Icons.check : Icons.add;
    final buttonText = _isArticleSaved ? 'Saved' : 'Library';
    final buttonColor = _isArticleSaved ? AppColors.black : AppColors.black;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
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
                          color: AppColors.darkGrey,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          article.imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue)));
                          },
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      article.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      top: 8.0,
                      bottom: 15.0,
                      right: 20.0,
                    ),
                    child: Text(
                      article.author,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),
                const Divider(
                  color: AppColors.darkGrey,
                  thickness: 1.0,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 15),

                // --- GANTI JUDUL DENGAN "PREVIEW" ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    _isAbstractExpanded 
                        ? _getArticleContentPreview(article, wordLimit: 99999) 
                        : _getArticleContentPreview(article, wordLimit: 70),
                    
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.darkGrey,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
                
                // // Tombol "Read more" hanya muncul jika belum expanded DAN konten artikel > 50 kata
                // if (!_isAbstractExpanded && fullContentWords > 50)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 10.0, top: 5.0),
                //     child: TextButton(
                //       onPressed: _toggleAbstractExpansion,
                //       child: const Text(
                //         'Read more',
                //         style: TextStyle(
                //           color: AppColors.primaryBlue,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //     ),
                //   ),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleReadingScreen(
                            articleId: article.id,
                            articleTitle: article.title,
                            articleAuthor: article.author,
                            imagePath: article.imagePath,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                    onPressed: () => _toggleLibraryStatus(article),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: buttonColor,
                      side: BorderSide(
                        color: buttonColor,
                        width: 2,
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: _isArticleSaved ? AppColors.black.withOpacity(0.1) : AppColors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(buttonIcon, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          buttonText,
                          style: const TextStyle(
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
    );
  }
}