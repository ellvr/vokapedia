// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/screen/article_detail_screen.dart';
import 'package:vokapedia/screen/bookmark_screen.dart';
import 'package:vokapedia/screen/library_screen.dart';
import 'package:vokapedia/screen/profile_screen.dart';
import 'package:vokapedia/screen/searchh_screen.dart';
import '../widget/custom_bottom_navbar.dart';
import '../utils/color_constants.dart';
import 'package:rxdart/rxdart.dart';

const double _paddingHorizontal = 15.0;
const double _spacingVertical = 15.0;

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  final String userRole;

  const HomeScreen({super.key, this.initialIndex = 0, required this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ValueNotifier<int> _pageNotifier = ValueNotifier(0);

  String _userName = 'Pengguna';
  String? _userPhotoUrl;
  String? _currentUserClass;

  List<Article> _featuredArticles = [];
  bool _isFeaturedLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUserData();
    _loadFeaturedArticles();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? name;
      String? photoUrl;
      String? userClass;

      name = user.displayName;
      photoUrl = user.photoURL;

      try {
        DocumentSnapshot snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (snap.exists && (snap.data() as Map).containsKey('name')) {
          name = snap['name'];
        }
        if (snap.exists && (snap.data() as Map).containsKey('kelas')) {
          userClass = snap['kelas'];
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          if (name != null && name.isNotEmpty) {
            _userName = name.split(' ')[0];
          } else if (user.email != null) {
            _userName = user.email!.split('@')[0];
          } else {
            _userName = 'Pengguna';
          }
          _userPhotoUrl = photoUrl;
          _currentUserClass = userClass;
        });
      }
    }
  }

  Future<void> _loadFeaturedArticles() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('isFeatured', isEqualTo: true)
          .get();

      final data = snapshot.docs
          .map((doc) => Article.fromFirestore(doc.data(), doc.id))
          .toList();

      if (mounted) {
        setState(() {
          _featuredArticles = data;
          _isFeaturedLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured articles: $e');
      if (mounted) {
        setState(() {
          _isFeaturedLoading = false;
        });
      }
    }
  }

  Stream<List<Article>> _getRecommendedArticlesStream(String userClass) {
    final userRole = widget.userRole;

    if (userRole == 'admin') {
      return FirebaseFirestore.instance
          .collection('articles')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Article.fromFirestore(doc.data(), doc.id))
                .toList(),
          );
    } else {
      String classFilter;
      if (userClass == '10') {
        classFilter = 'Kelas X';
      } else if (userClass == '11') {
        classFilter = 'Kelas XI';
      } else if (userClass == '12') {
        classFilter = 'Kelas XII';
      } else {
        return Stream.value([]);
      }

      final streamSpecific = FirebaseFirestore.instance
          .collection('articles')
          .where('kelas', isEqualTo: classFilter)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Article.fromFirestore(doc.data(), doc.id))
                .toList(),
          );

      final streamGeneral = FirebaseFirestore.instance
          .collection('articles')
          .where('kelas', isEqualTo: 'Umum')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Article.fromFirestore(doc.data(), doc.id))
                .toList(),
          );

      return Rx.combineLatest2(streamSpecific, streamGeneral, (
        List<Article> specific,
        List<Article> general,
      ) {
        final combined = [...specific, ...general];

        final uniqueArticles = <String, Article>{};
        for (var article in combined) {
          uniqueArticles[article.id] = article;
        }
        return uniqueArticles.values.toList();
      });
    }
  }

  Stream<List<Article>> _getContinueReadingStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingHistory')
        .where('readingProgress', isLessThan: 1.0)
        .orderBy('readingProgress')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Article.fromFirestore(data, doc.id);
          }).toList();
        });
  }

  final List<Widget> _screens = [
    const SizedBox(),
    const SearchhScreen(),
    const LibraryScreen(),
    const BookmarkScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.backgroundLight,
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 30,
                color: AppColors.darkGrey,
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
        debugPrint('Base64 Decode Error in Home: $e');
        imageWidget = Container(
          color: AppColors.backgroundLight,
          child: const Center(
            child: Icon(
              Icons.error_outline,
              size: 30,
              color: AppColors.darkGrey,
            ),
          ),
        );
      }
    } else {
      imageWidget = Container(
        color: AppColors.backgroundLight,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 30,
            color: AppColors.darkGrey,
          ),
        ),
      );
    }
    return imageWidget;
  }

  Widget _buildHomeBody(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            _buildFeaturedContent(),
            _buildSectionTitle(
              title: widget.userRole == 'admin'
                  ? 'All article'
                  : 'Top picks for you',
            ),

            if (_currentUserClass == null && widget.userRole == 'siswa')
              const SizedBox(
                height: 210,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                  ),
                ),
              )
            else
              _buildArticlesList(
                stream: _getRecommendedArticlesStream(_currentUserClass ?? ''),
                height: 210,
              ),
            const SizedBox(height: 10),
            _buildSectionTitle(title: 'Continue reading'),
            _buildArticlesList(
              stream: _getContinueReadingStream(),
              height: 210,
              isReadingList: true,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesList({
    required Stream<List<Article>> stream,
    required double height,
    bool isReadingList = false,
  }) {
    return StreamBuilder<List<Article>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Stream Error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: _paddingHorizontal),
            child: Text(
              'Error memuat data: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: _paddingHorizontal),
            child: Text(
              isReadingList
                  ? 'Semua artikel sudah dibaca. Yuk tambah librarymu!'
                  : widget.userRole == 'admin'
                  ? 'Belum ada artikel di database.'
                  : 'Belum ada artikel yang sesuai dengan kelas Anda.',
              style: const TextStyle(color: AppColors.darkGrey),
            ),
          );
        }

        final articles = snapshot.data!;

        return SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            padding: const EdgeInsets.symmetric(horizontal: _paddingHorizontal),
            itemBuilder: (context, index) {
              final item = articles[index];
              return Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: SizedBox(
                  width: 150,
                  child: _buildContentCard(
                    item: item,
                    isReadingList: isReadingList,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHome = _currentIndex == 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: isHome ? _buildHomeAppBar() : null,
      body: isHome ? _buildHomeBody(context) : _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  AppBar _buildHomeAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2.0,
      shadowColor: AppColors.darkGrey.withOpacity(0.3),
      toolbarHeight: 80,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 2.0,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: _paddingHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Halo $_userName!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userRole == 'admin'
                        ? 'Anda login sebagai Administrator.'
                        : 'Siap eksplor bacaan baru untuk belajar?',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: _paddingHorizontal),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                setState(() {
                  _currentIndex = 4;
                });
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.backgroundLight,
                backgroundImage:
                    _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                    ? NetworkImage(_userPhotoUrl!)
                    : null,
                child: _userPhotoUrl == null || _userPhotoUrl!.isEmpty
                    ? const Icon(Icons.person, color: AppColors.darkGrey)
                    : null,
              ),
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildFeaturedContent() {
    if (_isFeaturedLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
          ),
        ),
      );
    }

    if (_featuredArticles.isEmpty) {
      return const SizedBox.shrink();
    }
    final featuredContent = _featuredArticles;

    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: featuredContent.length,
            onPageChanged: (index) {
              _pageNotifier.value = index;
            },
            itemBuilder: (context, index) {
              final item = featuredContent[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArticleDetailScreen(articleId: item.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        _buildArticleImage(
                          item.imagePath,
                          width: double.infinity,
                          height: double.infinity,
                        ),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.9),
                                  Colors.black.withOpacity(0.4),
                                  Colors.black.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Teks Judul
                        Positioned(
                          bottom: 8,
                          left: 12,
                          right: 12,
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: ValueListenableBuilder<int>(
            valueListenable: _pageNotifier,
            builder: (context, value, _) {
              return _DotIndicator(
                count: featuredContent.length,
                currentIndex: value,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required String title}) {
    return Padding(
      padding: const EdgeInsets.only(
        left: _paddingHorizontal,
        right: _paddingHorizontal,
        top: _spacingVertical,
        bottom: _spacingVertical / 2,
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildContentCard({
    required Article item,
    required bool isReadingList,
  }) {
    final double progress = item.readingProgress?.toDouble() ?? 0.0;
    final int percentage = (progress * 100).toInt();

    final String subtitleText = isReadingList && progress > 0
        ? 'Progress: $percentage%'
        : item.author;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(articleId: item.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkGrey.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildArticleImage(
                item.imagePath,
                width: double.infinity,
                height: double.infinity,
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
          Text(
            subtitleText,
            style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _DotIndicator({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentIndex
                ? AppColors.primaryBlue
                : AppColors.darkGrey.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
