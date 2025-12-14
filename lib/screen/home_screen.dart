import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/screen/article_detail_screen.dart';
import 'package:vokapedia/screen/bookmark_screen.dart';
import 'package:vokapedia/screen/library_screen.dart';
import 'package:vokapedia/screen/profile_screen.dart';
import 'package:vokapedia/screen/searchh_screen.dart';
import 'package:vokapedia/services/firestore_services.dart';
import 'package:vokapedia/screen/add_article_screen.dart';
import '../widget/custom_bottom_navbar.dart';
import '../utils/color_constants.dart';

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
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  String _userName = 'Pengguna';
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController.addListener(_onPageChanged);
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? name;
      String? photoUrl;

      name = user.displayName;
      photoUrl = user.photoURL;

      if (name == null || name.isEmpty) {
        try {
          DocumentSnapshot snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (snap.exists && (snap.data() as Map).containsKey('name')) {
            name = snap['name'];
          }
        } catch (e) {}
      }

      if (mounted) {
        setState(() {
          if (name != null && name.isNotEmpty) {
            _userName = name!.split(' ')[0];
          } else if (user.email != null) {
            _userName = user.email!.split('@')[0];
          } else {
            _userName = 'Pengguna';
          }

          _userPhotoUrl = photoUrl;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {}

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

  Widget _buildHomeBody(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            _buildFeaturedContent(),
            _buildSectionTitle(title: 'Top picks for you'),
            _buildArticlesList(
              stream: getArticlesByFeature(field: 'isTopPick', value: true),
              height: 200,
            ),
            _buildSectionTitle(title: 'Continue reading'),
            _buildArticlesList(
              stream: getContinueReadingArticles(),
              height: 220,
              isReadingList: true,
            ),
            const SizedBox(height: 100),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: _paddingHorizontal),
            child: Text('Belum ada artikel di bagian ini.'),
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

  Widget? _buildFab() {
    if (widget.userRole == 'admin') {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddArticleScreen()),
          );
        },
        backgroundColor: AppColors.black,
        child: const Icon(Icons.add, color: AppColors.white),
      );
    }
    return null;
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
      floatingActionButton: isHome ? _buildFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                  const Text(
                    'Siap eksplor bacaan baru untuk belajar?',
                    style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
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
    return StreamBuilder<List<Article>>(
      stream: getArticlesByFeature(field: 'isFeatured', value: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final featuredContent = snapshot.data!;

        return Column(
          children: <Widget>[
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _pageController,
                itemCount: featuredContent.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.softBlue,
                            child: const Center(
                              child: Text(
                                'Gambar tidak ditemukan',
                                style: TextStyle(color: AppColors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: _DotIndicator(
                count: featuredContent.length,
                currentIndex: _currentPage,
              ),
            ),
          ],
        );
      },
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
              child: Image.network(
                item.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Gagal memuat gambar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                    ),
                  );
                },
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
          if (isReadingList)
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
