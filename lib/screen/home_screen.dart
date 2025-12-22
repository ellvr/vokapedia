// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/screen/all_quizzes_screen.dart';
import 'package:vokapedia/screen/quiz_play_screen.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/models/quiz_model.dart';
import 'package:vokapedia/screen/article_detail_screen.dart';
import 'package:vokapedia/screen/bookmark_screen.dart';
import 'package:vokapedia/screen/library_screen.dart';
import 'package:vokapedia/screen/profile_screen.dart';
import 'package:vokapedia/screen/searchh_screen.dart';
import '../widget/custom_bottom_navbar.dart';
import '../utils/color_constants.dart';

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
  List<String> _userInterests = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _listenUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  void _listenUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snap) {
            if (snap.exists && mounted) {
              Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
              bool hasSetInterests = data['hasSetInterests'] ?? false;
              setState(() {
                _userName = data['name']?.split(' ')[0] ?? 'Pengguna';
                _userPhotoUrl = user.photoURL;
                _userInterests = List<String>.from(data['interests'] ?? []);
              });
              if (!hasSetInterests) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) _showInterestDialog();
                });
              }
            }
          });
    }
  }

  void _showInterestDialog() {
    List<String> tempSelected = List.from(_userInterests);
    final List<String> categories = [
      "Materi Belajar",
      "Sastra",
      "Artikel Populer",
      "Artikel Ilmiah",
    ];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Apa minatmu?",
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Pilih topik favoritmu untuk rekomendasi terbaik.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSel = tempSelected.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSel,
                        onSelected: (val) {
                          setDialogState(() {
                            val
                                ? tempSelected.add(cat)
                                : tempSelected.remove(cat);
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                        checkmarkColor: AppColors.primaryBlue,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primaryBlue
                                : Colors.grey.shade300,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.primaryBlue : Colors.black87,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .update({'hasSetInterests': true});
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Nanti saja",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .update({
                          'interests': tempSelected,
                          'hasSetInterests': true,
                        });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Stream<List<Quiz>> _getActiveQuizzesStream() {
    return FirebaseFirestore.instance
        .collection('quizzes')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(2)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Quiz.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Article>> _getTopPicksStream() {
    if (_userInterests.isEmpty) {
      return FirebaseFirestore.instance
          .collection('articles')
          .limit(10)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => Article.fromFirestore(doc.data(), doc.id))
                .toList(),
          );
    } else {
      return FirebaseFirestore.instance
          .collection('articles')
          .where('topic', whereIn: _userInterests)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => Article.fromFirestore(doc.data(), doc.id))
                .toList(),
          );
    }
  }

  Stream<List<Article>> _getContinueReadingStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingHistory')
        .where('readingProgress', isLessThan: 1.0)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Article.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHome = _currentIndex == 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isHome ? _buildHomeAppBar() : null,
      body: isHome ? _buildHomeBody(context) : _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  AppBar _buildHomeAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo $_userName!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Siap baca apa hari ini?',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => setState(() => _currentIndex = 4),
              borderRadius: BorderRadius.circular(22),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.softBlue,
                backgroundImage: _userPhotoUrl != null
                    ? NetworkImage(_userPhotoUrl!)
                    : null,
                child: _userPhotoUrl == null
                    ? const Icon(Icons.person, color: AppColors.primaryBlue)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildFeaturedContent(),
            _buildQuizSection(),
            _buildSectionTitle(title: 'Top picks for you', showSeeAll: true),
            _buildHorizontalArticles(stream: _getTopPicksStream()),
            _buildSectionTitle(title: 'Continue reading', showSeeAll: false),
            _buildHorizontalArticles(stream: _getContinueReadingStream()),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('articles')
          .where('isFeatured', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        final featuredList = docs
            .map(
              (doc) => Article.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                itemCount: featuredList.length,
                onPageChanged: (i) => _pageNotifier.value = i,
                itemBuilder: (context, index) {
                  final item = featuredList[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleDetailScreen(articleId: item.id),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildArticleImage(item.imagePath),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 15,
                              left: 15,
                              right: 15,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                 
                                  const SizedBox(height: 5),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
            const SizedBox(height: 10),
            ValueListenableBuilder<int>(
              valueListenable: _pageNotifier,
              builder: (context, value, _) => _DotIndicator(
                count: featuredList.length,
                currentIndex: value,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuizSection() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title: 'Latihan Kuis', showSeeAll: true),
        StreamBuilder<List<Quiz>>(
          stream: _getActiveQuizzesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            final quizzes = snapshot.data ?? [];
            if (quizzes.isEmpty)
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Tidak ada kuis aktif.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                bool isOverdue = DateTime.now().isAfter(quiz.deadline);
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quiz_submissions')
                      .where('quizID', isEqualTo: quiz.id)
                      .where('studentID', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, subSnap) {
                    bool isAnswered =
                        subSnap.hasData && subSnap.data!.docs.isNotEmpty;
                    String statusLabel = isAnswered
                        ? "Selesai"
                        : (isOverdue ? "Terlambat" : "Ditugaskan");
                    Color statusColor = isAnswered
                        ? Colors.green
                        : (isOverdue ? Colors.red : AppColors.primaryBlue);
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPlayScreen(quiz: quiz),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 12,
                                        color: isOverdue && !isAnswered
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAnswered
                                            ? "Sudah dikerjakan"
                                            : "Deadline: ${quiz.deadline.day}/${quiz.deadline.month}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isOverdue && !isAnswered
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalArticles({required Stream<List<Article>> stream}) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<List<Article>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final articles = snapshot.data ?? [];
          if (articles.isEmpty)
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Belum ada artikel",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            );
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: articles.length,
            itemBuilder: (context, index) =>
                _buildContentCard(item: articles[index]),
          );
        },
      ),
    );
  }

  Widget _buildContentCard({required Article item}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(articleId: item.id),
        ),
      ),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                width: 150,
                color: AppColors.softBlue,
                child: _buildArticleImage(item.imagePath),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
            Text(
              item.author,
              style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleImage(String imagePath) {
    if (imagePath.isEmpty) return const Icon(Icons.image_not_supported);
    if (imagePath.startsWith('http'))
      return Image.network(imagePath, fit: BoxFit.cover, gaplessPlayback: true);
    try {
      return Image.memory(
        base64Decode(imagePath.split(',').last),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } catch (e) {
      return const Icon(Icons.error);
    }
  }

  Widget _buildSectionTitle({required String title, bool showSeeAll = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
              if (title == 'Top picks for you')
                IconButton(
                  icon: const Icon(
                    Icons.tune,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () => _showInterestDialog(),
                ),
            ],
          ),
          if (showSeeAll)
            GestureDetector(
              onTap: () => title == 'Latihan Kuis'
                  ? Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllQuizzesScreen(),
                      ),
                    )
                  : setState(() => _currentIndex = 1),
              child: const Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  final List<Widget> _screens = [
    const SizedBox(),
    const SearchhScreen(),
    const LibraryScreen(),
    const BookmarkScreen(),
    const ProfileScreen(),
  ];
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  const _DotIndicator({required this.count, required this.currentIndex});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          width: index == currentIndex ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: index == currentIndex
                ? AppColors.primaryBlue
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
