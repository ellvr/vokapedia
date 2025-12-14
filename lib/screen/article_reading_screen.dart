// ignore_for_file: use_build_context_synchronously, deprecated_member_use, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/utils/color_constants.dart';
import 'dart:async';
import 'dart:convert'; // Wajib untuk Base64
import 'dart:typed_data'; // Wajib untuk Uint8List

enum ReadingTheme { light, dark, sepia }

class ThemeColors {
  final Color background;
  final Color text;
  final Color appbar;
  final Color icon;

  const ThemeColors({
    required this.background,
    required this.text,
    required this.appbar,
    required this.icon,
  });
}

const Map<ReadingTheme, ThemeColors> themeMap = {
  ReadingTheme.light: ThemeColors(
    background: AppColors.white,
    text: AppColors.black,
    appbar: AppColors.white,
    icon: AppColors.black,
  ),
  ReadingTheme.dark: ThemeColors(
    background: AppColors.black,
    text: AppColors.white,
    appbar: AppColors.black,
    icon: AppColors.white,
  ),
  ReadingTheme.sepia: ThemeColors(
    background: Color(0xFFFAF0E6),
    text: AppColors.black,
    appbar: Color(0xFFFAF0E6),
    icon: AppColors.black,
  ),
};

class ArticleReadingScreen extends StatefulWidget {
  final String articleId;
  final String articleTitle;
  final String articleAuthor;
  final String imagePath;
  final double initialProgress;

  const ArticleReadingScreen({
    super.key,
    required this.articleId,
    required this.articleTitle,
    required this.articleAuthor,
    required this.imagePath,
    this.initialProgress = 0.0,
  });

  @override
  State<ArticleReadingScreen> createState() => _ArticleReadingScreenState();
}

class _ArticleReadingScreenState extends State<ArticleReadingScreen> {
  ReadingTheme _currentTheme = ReadingTheme.light;
  bool _isThemeSelectorVisible = false;

  int _currentPageIndex = 0;
  final int _wordsPerPage = 800;

  int _totalPages = 1;

  ThemeColors get _colors => themeMap[_currentTheme]!;

  @override
  void initState() {
    super.initState();
    // Inisialisasi halaman berdasarkan progress awal
    if (widget.initialProgress > 0 && widget.initialProgress < 1.0) {
      // Kita perlu menghitung _totalPages terlebih dahulu dari konten
      // Namun karena _fetchArticleDetail bersifat async, kita akan update _currentPageIndex
      // di dalam FutureBuilder _buildArticleContent setelah _totalPages dihitung.
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  // ================================
  // ⚙️ FUNGSI UNTUK MENANGANI LOGIKA GAMBAR (DIAMBIL DARI SEBELUMNYA)
  // ================================
  Widget _buildArticleImage(String imagePath, {double? width, double? height}) {
    bool isNetworkUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    bool isBase64Data = imagePath.length > 100 && !isNetworkUrl;

    Widget imageWidget;

    if (isNetworkUrl) {
      imageWidget = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.backgroundLight,
            child: const Center(
              child: Text(
                'Gagal memuat cover',
                style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
              ),
            ),
          );
        },
      );
    } else if (isBase64Data) {
      try {
        String base64String = imagePath.contains(',')
            ? imagePath.split(',').last
            : imagePath;

        Uint8List imageBytes = base64Decode(base64String);

        imageWidget = Image.memory(
          imageBytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } catch (e) {
        debugPrint('Base64 Decode Error in Reading Screen: $e');
        imageWidget = Container(
          color: AppColors.backgroundLight,
          child: const Center(
            child: Icon(Icons.error_outline, size: 40, color: AppColors.darkGrey),
          ),
        );
      }
    } else {
      imageWidget = Container(
        color: AppColors.backgroundLight,
        child: const Center(
          child: Text(
            'Cover Image Placeholder',
            style: TextStyle(color: AppColors.darkGrey),
          ),
        ),
      );
    }
    return imageWidget;
  }
  // =========================================================

  Future<void> _markAsFinishedAndPop() async {
    await FirebaseFirestore.instance
        .collection('saved_articles')
        .doc(widget.articleId)
        .set({'readingProgress': 1.0}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anda telah selesai membaca artikel ini! Progress disimpan.'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _saveBookmark(String selectedText) async {
    if (selectedText.trim().isEmpty) {
      return;
    }

    const String userId = 'user123';

    try {
      await FirebaseFirestore.instance.collection('user_bookmarks').add({
        'userId': userId,
        'articleId': widget.articleId,
        'articleTitle': widget.articleTitle,
        'articleAuthor': widget.articleAuthor,
        'highlightedText': selectedText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil disimpan ke Bookmark!'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.black,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan bookmark: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Article> _fetchArticleDetail() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .get();
      if (!doc.exists) {
        throw Exception("Article with ID ${widget.articleId} not found.");
      }
      return Article.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to load article: $e');
    }
  }

  void _toggleThemeSelector() {
    setState(() {
      _isThemeSelectorVisible = !_isThemeSelectorVisible;
    });
  }

  void _selectTheme(ReadingTheme theme) {
    setState(() {
      _currentTheme = theme;
      _isThemeSelectorVisible = false;
    });
  }

  void _goToPage(int newIndex) {
    if (newIndex >= 0 && newIndex < _totalPages) {
      setState(() {
        _currentPageIndex = newIndex;
        _saveReadingProgress(newIndex, _totalPages);
      });
    }
  }

  Future<void> _saveReadingProgress(int currentPage, int totalPages) async {
    if (totalPages > 0) {
      final double progress = (currentPage + 1) / totalPages;
      await FirebaseFirestore.instance
          .collection('saved_articles')
          .doc(widget.articleId)
          .set({'readingProgress': progress}, SetOptions(merge: true));
    }
  }

  Widget _buildThemeSelectorPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: _colors.appbar,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGrey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Page color',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _colors.text.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: ReadingTheme.values.map((theme) {
              final colors = themeMap[theme]!;
              final isSelected = theme == _currentTheme;

              return GestureDetector(
                onTap: () => _selectTheme(theme),
                child: Container(
                  width: 60,
                  height: 40,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.black
                          : AppColors.darkGrey.withOpacity(0.3),
                      width: isSelected ? 3.0 : 1.0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<String> _getAllWords(Article article) {
    String fullContent = '';

    for (var section in article.sections) {
      // Mengasumsikan struktur section adalah Map dengan 'heading' dan 'paragraphs'/'content'
      fullContent += (section['heading'] ?? '') + ' ';
      
      // Menangani jika konten adalah List (array paragraf) atau String
      final content = section['paragraphs'] ?? section['content'] ?? '';
      if (content is List) {
          fullContent += content.join(' ') + ' ';
      } else {
          fullContent += content.toString() + ' ';
      }
    }

    return fullContent.trim().split(RegExp(r'\s+'));
  }

  Widget _customContextMenuBuilder(
      BuildContext context, EditableTextState editableTextState) {
    final List<ContextMenuButtonItem> buttonItems = [
      ContextMenuButtonItem(
        onPressed: () {
          editableTextState.copySelection(SelectionChangedCause.toolbar);
          editableTextState.hideToolbar();
        },
        type: ContextMenuButtonType.copy,
      ),
      ContextMenuButtonItem(
        onPressed: () {
          editableTextState.selectAll(SelectionChangedCause.toolbar);
        },
        type: ContextMenuButtonType.selectAll,
      ),
      ContextMenuButtonItem(
        onPressed: () {
          final selectedText =
              editableTextState.textEditingValue.text.substring(
            editableTextState.textEditingValue.selection.start,
            editableTextState.textEditingValue.selection.end,
          );
          _saveBookmark(selectedText);
          editableTextState.hideToolbar();
        },
        label: 'Bookmark',
      ),
    ];

    return AdaptiveTextSelectionToolbar.buttonItems(
      buttonItems: buttonItems,
      anchors: editableTextState.contextMenuAnchors,
    );
  }

  Widget _buildArticleContent(Article article) {
    final List<String> allWords = _getAllWords(article);
    final int totalWords = allWords.length;

    // Hitung total halaman dan update state
    final int newTotalPages = (totalWords / _wordsPerPage).ceil();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newTotalPages != _totalPages) {
        setState(() {
          _totalPages = newTotalPages;
          // Pindah ke halaman terakhir yang dibaca jika ada progress awal
          if (widget.initialProgress > 0 && widget.initialProgress < 1.0) {
            _currentPageIndex = ((widget.initialProgress * _totalPages) - 1).round().clamp(0, _totalPages - 1);
          }
        });
      }
    });

    final int startIndex = _currentPageIndex * _wordsPerPage;
    final int endIndex =
        ((_currentPageIndex + 1) * _wordsPerPage).clamp(0, totalWords);

    final List<String> wordsToShow = allWords.sublist(startIndex, endIndex);
    final String pageContent = wordsToShow.join(' ');

    final double readingProgress =
        (_totalPages > 0) ? (_currentPageIndex + 1) / _totalPages : 1.0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: readingProgress.toDouble(),
          backgroundColor: _colors.appbar.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppColors.primaryBlue,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 20,
              left: 10,
              right: 10,
              top: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_currentPageIndex == 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      // 👇 MENGGUNAKAN FUNGSI IMAGE BARU
                      child: _buildArticleImage(
                        article.imagePath,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Text(
                      article.title,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: _colors.text),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, top: 5.0, bottom: 15.0),
                    child: Text(
                      article.author,
                      style: TextStyle(
                          fontSize: 14, color: _colors.text.withOpacity(0.6)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        selectionColor: AppColors.primaryBlue.withOpacity(0.4),
                        selectionHandleColor: AppColors.primaryBlue,
                      ),
                    ),
                    child: SelectableText(
                      pageContent,
                      style: TextStyle(
                          fontSize: 16, height: 1.6, color: _colors.text),
                      textAlign: TextAlign.justify,
                      contextMenuBuilder: _customContextMenuBuilder,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                _buildPaginationButtons(_totalPages),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationButtons(int totalPages) {
    bool isFirstPage = _currentPageIndex == 0;
    bool isLastPage = _currentPageIndex == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: isFirstPage ? null : () => _goToPage(_currentPageIndex - 1),
            icon: Icon(Icons.arrow_back, color: isFirstPage ? AppColors.darkGrey : AppColors.black),
            label: Text(
              'Previous',
              style: TextStyle(color: isFirstPage ? AppColors.darkGrey : AppColors.black),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isFirstPage ? AppColors.darkGrey.withOpacity(0.5) : AppColors.black),
            ),
          ),

          Text(
            'Page ${_currentPageIndex + 1} of $totalPages',
            style: TextStyle(fontSize: 16, color: _colors.text),
          ),

          ElevatedButton.icon(
            onPressed: isLastPage
                ? _markAsFinishedAndPop
                : () => _goToPage(_currentPageIndex + 1),

            icon: Icon(
              isLastPage ? Icons.done : Icons.arrow_forward,
              color: AppColors.white,
            ),
            label: Text(
              isLastPage ? 'Finish' : 'Next',
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastPage ? AppColors.primaryBlue : AppColors.black,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        title: Text(
          widget.articleTitle.length > 25
              ? '${widget.articleTitle.substring(0, 25)}...'
              : widget.articleTitle,
          style: TextStyle(fontSize: 16, color: _colors.icon),
        ),
        backgroundColor: _colors.appbar,
        elevation: _isThemeSelectorVisible ? 0 : 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colors.icon),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.color_lens,
              color: _isThemeSelectorVisible
                  ? AppColors.primaryBlue
                  : _colors.icon,
            ),
            onPressed: _toggleThemeSelector,
          ),
          IconButton(
            icon: Icon(Icons.menu_book, color: _colors.icon),
            onPressed: () {
              // Tambahkan logika untuk membuka menu bookmark/highlight
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Visibility(
              visible: _isThemeSelectorVisible,
              maintainState: true,
              child: _buildThemeSelectorPanel(),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FutureBuilder<Article>(
                  future: _fetchArticleDetail(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Gagal memuat artikel. Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.black),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: Text('Konten artikel tidak ditemukan.'));
                    }

                    return _buildArticleContent(snapshot.data!);
                  },
                ),
                if (_isThemeSelectorVisible)
                  GestureDetector(
                    onTap: _toggleThemeSelector,
                    child: Container(
                      color: Colors.black54.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}