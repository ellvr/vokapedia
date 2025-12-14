// ignore_for_file: prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/screen/article_reading_screen.dart';
import 'package:vokapedia/screen/home_screen.dart';
import 'package:vokapedia/utils/color_constants.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';

const String _apkDownloadLink = 'https://clips.id/VokaPediaApps';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Future<Article> _articleFuture;
  Article? _articleData;
  bool _isArticleSaved = false;
  String _currentUserRole = 'user';

  @override
  void initState() {
    super.initState();
    _articleFuture = _fetchArticleDetailAndUserState();
  }

  Future<Article> _fetchArticleDetailAndUserState() async {
    final doc = await FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.articleId)
        .get();
    if (!doc.exists) {
      throw Exception("Article not found in database.");
    }
    final article = Article.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );

    final user = FirebaseAuth.instance.currentUser;
    bool isSaved = false;
    String role = 'user';

    if (user != null) {
      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('readingHistory') // Konsisten dengan readingHistory
            .doc(widget.articleId)
            .get(),
        FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      ]);

      final savedDoc = futures[0];
      final userDoc = futures[1];

      isSaved = savedDoc.exists;

      if (userDoc.exists && userDoc.data()!.containsKey('role')) {
        role = userDoc['role'];
      }
    }

    if (mounted) {
      setState(() {
        _isArticleSaved = isSaved;
        _currentUserRole = role;
        _articleData = article;
      });
    }

    return article;
  }

  String _getArticleContentPreview(Article article, {int wordLimit = 50}) {
    String fullContent = '';

    if (article.abstractContent != null &&
        article.abstractContent!.isNotEmpty) {
      fullContent += '${article.abstractContent!}\n\n';
    }

    for (var section in article.sections) {
      fullContent +=
          (section['sectionTitle'] ?? '') +
          ' ' +
          (section['content'] ?? '') +
          ' ';
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

  void _shareArticle(Article article) {
    final String shareText =
        'Yuk, baca artikel menarik dari VokaPedia: "${article.title}" oleh ${article.author}.'
        '\n\nInstall Aplikasi VokaPedia untuk membaca konten lengkapnya!'
        '\n$_apkDownloadLink';

    Share.share(shareText, subject: 'Artikel VocaPedia: ${article.title}');
  }

  Future<void> _toggleLibraryStatus(Article article) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk menyimpan artikel.'),
        ),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingHistory')
        .doc(article.id);

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
        'articleId': article.id,
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
          backgroundColor: AppColors.primaryBlue,
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
          builder: (context) =>
              HomeScreen(initialIndex: 2, userRole: _currentUserRole),
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
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.black),
            onPressed: _articleData != null
                ? () => _shareArticle(_articleData!)
                : null,
          ),
        ],
      ),
      body: FutureBuilder<Article>(
        future: _articleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error memuat artikel: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || _articleData == null) {
            return const Center(child: Text('Artikel tidak ditemukan.'));
          }

          final article = _articleData!;

          return _buildDetailBody(context, article);
        },
      ),
    );
  }

  Widget _buildDetailBody(BuildContext context, Article article) {
    final buttonIcon = _isArticleSaved ? Icons.check : Icons.add;
    final buttonText = _isArticleSaved ? 'Saved' : 'Library';

    final Color buttonColor = _isArticleSaved
        ? AppColors.black
        : AppColors.black;
    final Color borderColor = _isArticleSaved
        ? AppColors.black
        : AppColors.black;
    final Color backgroundColor = _isArticleSaved
        ? Colors.grey.shade300
        : Colors.transparent;

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
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryBlue,
                                ),
                              ),
                            );
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

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Preview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    _getArticleContentPreview(article, wordLimit: 70),

                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.darkGrey,
                    ),
                    textAlign: TextAlign.justify,
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
                      foregroundColor: buttonColor, // Warna teks/ikon
                      side: BorderSide(
                        color: borderColor,
                        width: 2,
                      ), // Warna border
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: backgroundColor, // Warna latar belakang
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
