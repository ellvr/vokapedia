// ignore_for_file: use_build_context_synchronously, deprecated_member_use, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/utils/color_constants.dart';
import 'dart:async';

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
  final String? highlightedTextToFind;

  const ArticleReadingScreen({
    super.key,
    required this.articleId,
    required this.articleTitle,
    required this.articleAuthor,
    required this.imagePath,
    this.initialProgress = 0.0,
    this.highlightedTextToFind,
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

  Article? _articleData;
  bool _isLoading = true;
  String? _errorMessage;

  List<String> _allArticleWords = [];

  String? _activeHighlightText;
  int _highlightStartWordIndex = -1;
  int _highlightEndWordIndex = -1;

  ThemeColors get _colors => themeMap[_currentTheme]!;

  @override
  void initState() {
    super.initState();
    _activeHighlightText = widget.highlightedTextToFind;
    _loadArticleAndInitialize();
  }

  @override
  void dispose() {
    _saveActiveHighlightToHistory();
    super.dispose();
  }

  String _cleanWord(String word) {
    // Menghapus tanda baca umum di akhir kata dan mengubah ke huruf kecil
    return word.replaceAll(RegExp(r'[.,:;?!"]$'), '').toLowerCase();
  }

  Future<void> _loadArticleAndInitialize() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .get();
      if (!doc.exists) {
        throw Exception("Article with ID ${widget.articleId} not found.");
      }

      final article = Article.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && widget.highlightedTextToFind == null) {
        final historyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('readingHistory')
            .doc(widget.articleId)
            .get();

        if (historyDoc.exists && historyDoc.data()?['lastHighlight'] != null) {
          _activeHighlightText = historyDoc.data()!['lastHighlight'] as String?;
        }
      }

      _allArticleWords = _getAllWords(article);
      _totalPages = (_allArticleWords.length / _wordsPerPage).ceil();

      _findHighlightAndNavigate();

      if (mounted) {
        setState(() {
          _articleData = article;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load article: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveActiveHighlightToHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _activeHighlightText == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingHistory')
        .doc(widget.articleId)
        .set({'lastHighlight': _activeHighlightText}, SetOptions(merge: true));
  }

  Future<void> _markAsFinishedAndPop() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk menyimpan progres bacaan.'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingHistory')
        .doc(widget.articleId)
        .set({
          'readingProgress': 1.0,
          'articleId': widget.articleId,
          'title': widget.articleTitle,
          'author': widget.articleAuthor,
          'imagePath': widget.imagePath,
          'savedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Anda telah selesai membaca artikel ini! Progress disimpan.',
        ),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _saveBookmark(String selectedText) async {
    if (selectedText.trim().isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk menyimpan bookmark.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .add({
            'articleId': widget.articleId,
            'articleTitle': widget.articleTitle,
            'articleAuthor': widget.articleAuthor,
            'highlightedText': selectedText,
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _activeHighlightText = selectedText;
        _findHighlightAndNavigate();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil disimpan ke Bookmark!'),
          duration: Duration(seconds: 2),
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

  void _findHighlightAndNavigate() {
    if (_activeHighlightText != null && _allArticleWords.isNotEmpty) {
      final String highlight = _activeHighlightText!.trim();
      final List<String> highlightWords = highlight.split(RegExp(r'\s+'));

      bool highlightFound = false;

      if (highlightWords.isNotEmpty) {
        final String cleanFirstHighlightWord = _cleanWord(highlightWords[0]);

        for (int i = 0; i < _allArticleWords.length; i++) {
          if (_cleanWord(_allArticleWords[i]) == cleanFirstHighlightWord) {
            bool match = true;
            for (int j = 1; j < highlightWords.length; j++) {
              final String cleanArticleWord = i + j < _allArticleWords.length
                  ? _cleanWord(_allArticleWords[i + j])
                  : '';

              if (i + j >= _allArticleWords.length ||
                  cleanArticleWord != _cleanWord(highlightWords[j])) {
                match = false;
                break;
              }
            }

            if (match) {
              _highlightStartWordIndex = i;
              _highlightEndWordIndex = i + highlightWords.length;
              highlightFound = true;

              final int pageToNavigate =
                  (_highlightStartWordIndex / _wordsPerPage).floor();

              if (_currentPageIndex != pageToNavigate) {
                setState(() {
                  _currentPageIndex = pageToNavigate.clamp(0, _totalPages - 1);
                });
              }
              break;
            }
          }
        }
      }

      if (!highlightFound) {
        _highlightStartWordIndex = -1;
        _highlightEndWordIndex = -1;
      }
    } else {
      _highlightStartWordIndex = -1;
      _highlightEndWordIndex = -1;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (totalPages > 0) {
      final double progress = (currentPage + 1) / totalPages;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('readingHistory')
          .doc(widget.articleId)
          .set({
            'readingProgress': progress,
            'articleId': widget.articleId,
            'title': widget.articleTitle,
            'author': widget.articleAuthor,
            'imagePath': widget.imagePath,
          }, SetOptions(merge: true));
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
      fullContent +=
          (section['sectionTitle'] ?? '') +
          ' ' +
          (section['content'] ?? '') +
          ' ';
    }

    return fullContent.trim().split(RegExp(r'\s+'));
  }

  Widget _customContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
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
          final selectedText = editableTextState.textEditingValue.text
              .substring(
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

  List<TextSpan> _buildHighlightedTextSpans(
    List<String> words,
    int pageStartIndex,
  ) {
    List<TextSpan> spans = [];

    if (_highlightStartWordIndex == -1) {
      for (final word in words) {
        spans.add(
          TextSpan(
            text: '$word ',
            style: TextStyle(color: _colors.text, fontSize: 16, height: 1.6),
          ),
        );
      }
      return spans;
    }

    Color highlightColor = AppColors.primaryBlue.withOpacity(0.4);

    for (int i = 0; i < words.length; i++) {
      final int wordGlobalIndex = pageStartIndex + i;
      final String word = words[i];

      final bool isHighlighted =
          wordGlobalIndex >= _highlightStartWordIndex &&
          wordGlobalIndex < _highlightEndWordIndex;

      spans.add(
        TextSpan(
          text: '$word ',
          style: TextStyle(
            backgroundColor: isHighlighted
                ? highlightColor
                : Colors.transparent,
            color: _colors.text,
            fontSize: 16,
            height: 1.6,
          ),
        ),
      );
    }
    return spans;
  }

  Widget _buildArticleContent(Article article) {
    final int totalWords = _allArticleWords.length;

    final int startIndex = _currentPageIndex * _wordsPerPage;
    final int endIndex = ((_currentPageIndex + 1) * _wordsPerPage).clamp(
      0,
      totalWords,
    );

    final List<String> wordsToShow = _allArticleWords.sublist(
      startIndex,
      endIndex,
    );

    final double readingProgress = (_totalPages > 0)
        ? (_currentPageIndex + 1) / _totalPages
        : 1.0;

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
                      child: Image.network(
                        article.imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: _colors.text,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      top: 5.0,
                      bottom: 15.0,
                    ),
                    child: Text(
                      article.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: _colors.text.withOpacity(0.6),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        selectionColor: AppColors.primaryBlue.withOpacity(0.4),
                        selectionHandleColor: AppColors.primaryBlue,
                      ),
                    ),
                    child: SelectableText.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: _colors.text,
                        ),
                        children: _buildHighlightedTextSpans(
                          wordsToShow,
                          startIndex,
                        ),
                      ),
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
            onPressed: isFirstPage
                ? null
                : () => _goToPage(_currentPageIndex - 1),
            icon: Icon(
              Icons.arrow_back,
              color: isFirstPage ? AppColors.darkGrey : AppColors.black,
            ),
            label: Text(
              'Previous',
              style: TextStyle(
                color: isFirstPage ? AppColors.darkGrey : AppColors.black,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isFirstPage
                    ? AppColors.darkGrey.withOpacity(0.5)
                    : AppColors.black,
              ),
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
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastPage
                  ? AppColors.primaryBlue
                  : AppColors.black,
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
              ? widget.articleTitle.substring(0, 25) + '...'
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
            onPressed: () {},
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
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else if (_articleData != null)
                  _buildArticleContent(_articleData!)
                else
                  const Center(child: Text('Konten artikel tidak ditemukan.')),

                if (_isThemeSelectorVisible)
                  GestureDetector(
                    onTap: _toggleThemeSelector,
                    child: Container(color: Colors.black54.withOpacity(0.4)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
