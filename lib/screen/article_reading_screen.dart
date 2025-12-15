// ignore_for_file: use_build_context_synchronously, deprecated_member_use, prefer_interpolation_to_compose_strings, unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/utils/color_constants.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart' show parse;

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
  final int _wordsPerPage = 300;

  int _totalPages = 1;

  Article? _articleData;
  bool _isLoading = true;
  String? _errorMessage;

  List<String> _allArticleWords = [];

  List<({int start, int end})> _highlightRanges = [];

  String? _initialHighlightText;
  int _initialHighlightStartWordIndex = -1;
  int _initialHighlightEndWordIndex = -1;

  ThemeColors get _colors => themeMap[_currentTheme]!;

  StreamSubscription? _bookmarkSubscription;

  @override
  void initState() {
    super.initState();
    _initialHighlightText = widget.highlightedTextToFind;
    _loadArticleAndInitialize();
  }

  @override
  void dispose() {
    _bookmarkSubscription?.cancel();
    super.dispose();
  }

  Widget _buildArticleImage(String imagePath, {double? width, double? height}) {
    if (imagePath.isEmpty) {
      return Container(
        height: height,
        color: AppColors.backgroundLight,
        child: const Center(
          child: Text(
            'Cover Image Placeholder',
            style: TextStyle(color: AppColors.darkGrey),
          ),
        ),
      );
    }

    bool isNetworkUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetworkUrl) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            color: AppColors.backgroundLight,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
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
    } else {

      try {
        String base64String = imagePath.contains(',')
            ? imagePath
                  .split(',')
                  .last 
            : imagePath;

        Uint8List imageBytes = base64Decode(base64String);

        return Image.memory(
          imageBytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } catch (e) {
   
        debugPrint('Base64 Decode Error in Reading Screen: $e');
        return Container(
          height: height,
          color: AppColors.backgroundLight,
          child: const Center(
            child: Text(
              'Gagal memuat gambar (Base64 Error)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
            ),
          ),
        );
      }
    }
  }

  String _cleanWord(String word) {
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

      _allArticleWords = _getAllWords(article);
      _totalPages = (_allArticleWords.length / _wordsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;

      _listenToBookmarks();

     
      _findInitialHighlightWordRange();

   
      if (_initialHighlightStartWordIndex != -1) {
     
        final int pageToNavigate =
            (_initialHighlightStartWordIndex / _wordsPerPage).floor();
        _currentPageIndex = pageToNavigate.clamp(0, _totalPages - 1);
      } else if (widget.initialProgress > 0 && _totalPages > 0) {
       
        _currentPageIndex = ((widget.initialProgress * _totalPages) - 1)
            .floor()
            .clamp(0, _totalPages - 1);
      }

   
      if (_currentPageIndex > 0) {
        _saveReadingProgress(_currentPageIndex, _totalPages);
      }

      if (mounted) {
        setState(() {
          _articleData = article;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load article: ' + e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _listenToBookmarks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _bookmarkSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .where('articleId', isEqualTo: widget.articleId)
        .snapshots()
        .listen((snapshot) {
          final List<String> texts = snapshot.docs
              .map((doc) => doc.data()['highlightedText'] as String)
              .toList();

          final List<({int start, int end})> newRanges = [];

          for (final text in texts) {
            final range = _findWordRange(text);
            if (range.start != -1) {
              newRanges.add(range);
            }
          }

          if (mounted) {
            setState(() {
              _highlightRanges = newRanges;
            });
          }
        });
  }

  Future<void> _saveActiveHighlightToHistory() async {}

  Future<void> _markAsFinishedAndPop() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk menyimpan progres bacaan.'),
        ),
      );

      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yeyy selesai membaca artikel ini!'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);

    FirebaseFirestore.instance
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
        }, SetOptions(merge: true))
        .catchError((error) {
          debugPrint('Error saving final progress: $error');
        });
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
            'author': widget.articleAuthor,
            'createdAt': FieldValue.serverTimestamp(),
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
          content: Text('Gagal menyimpan bookmark: ' + e.toString()),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ({int start, int end}) _findWordRange(String highlight) {
    if (_allArticleWords.isEmpty) return (start: -1, end: -1);

    final String trimmedHighlight = highlight.trim();

    final List<String> highlightWords = trimmedHighlight
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (highlightWords.isEmpty) return (start: -1, end: -1);

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
          return (start: i, end: i + highlightWords.length);
        }
      }
    }
    return (start: -1, end: -1);
  }

  void _findInitialHighlightWordRange() {
    if (_initialHighlightText != null && _allArticleWords.isNotEmpty) {
      final range = _findWordRange(_initialHighlightText!);

      _initialHighlightStartWordIndex = range.start;
      _initialHighlightEndWordIndex = range.end;
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

      FirebaseFirestore.instance
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
          }, SetOptions(merge: true))
          .catchError((error) {
            debugPrint('Error saving progress on page change: $error');
          });
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
    final unescape = HtmlUnescape();

    for (var section in article.sections) {
      String rawContent = '';

      final content = section['paragraphs'] ?? section['content'] ?? '';
      if (content is List) {
        rawContent += content.join(' ') + ' ';
      } else {
        rawContent += content.toString() + ' ';
      }

      String unescaped = unescape.convert(rawContent);

      String plainText = parse(unescaped).documentElement!.text;

      fullContent += plainText + ' ';
    }

    return fullContent.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
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

    Color highlightColor = AppColors.primaryBlue.withOpacity(0.4);
    Color initialHighlightColor = Colors.yellow.withOpacity(0.6);

    for (int i = 0; i < words.length; i++) {
      final int wordGlobalIndex = pageStartIndex + i;
      final String word = words[i];

      bool isPermanentHighlighted = _highlightRanges.any(
        (range) =>
            wordGlobalIndex >= range.start && wordGlobalIndex < range.end,
      );

      bool isInitialHighlighted =
          wordGlobalIndex >= _initialHighlightStartWordIndex &&
          wordGlobalIndex < _initialHighlightEndWordIndex;

      spans.add(
        TextSpan(
          text: '$word ',
          style: TextStyle(
            backgroundColor: isInitialHighlighted
                ? initialHighlightColor
                : (isPermanentHighlighted
                      ? highlightColor
                      : Colors.transparent),
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
                      child: _buildArticleImage(
                        article.imagePath,
                        width: double.infinity,
                        height: 200,
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
              color: isFirstPage ? AppColors.darkGrey : _colors.icon,
            ),
            label: Text(
              'Previous',
              style: TextStyle(
                color: isFirstPage ? AppColors.darkGrey : _colors.text,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isFirstPage
                    ? AppColors.darkGrey.withOpacity(0.5)
                    : _colors.text,
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
