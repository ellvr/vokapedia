import 'package:flutter/material.dart';
import 'package:vokapedia/screen/library_screen.dart';
import '../widget/custom_bottom_navbar.dart';
import '../utils/color_constants.dart';

const double _paddingHorizontal = 15.0;
const double _spacingVertical = 15.0;

class FeaturedItem {
  final String imagePath;
  final String title;

  FeaturedItem({required this.imagePath, this.title = ''});
}

class ContentItem {
  final String imagePath;
  final String title;
  final String? subtitle;

  ContentItem({required this.imagePath, required this.title, this.subtitle});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  final List<FeaturedItem> _featuredContent = [
    FeaturedItem(imagePath: 'assets/img/content1.png'),
    FeaturedItem(imagePath: 'assets/img/content1.png'),
    FeaturedItem(imagePath: 'assets/img/content1.png'),
  ];

  final List<ContentItem> _topPicksContent = [
    ContentItem(
      imagePath: 'assets/img/pick_1.png',
      title: '12 Methodologies Every Developer Must Master in 2025',
    ),
    ContentItem(
      imagePath: 'assets/img/pick_2.png',
      title: 'What does it really take to reach the top 1% in 2025',
    ),
    ContentItem(
      imagePath: 'assets/img/pick_3.png',
      title: 'What is SDLC in Software Engineering?',
    ),
    ContentItem(
      imagePath: 'assets/img/pick_1.png',
      title: 'Rahasia Menjadi Ahli Full-Stack Developer',
    ),
  ];

  final List<ContentItem> _continueReadingContent = [
    ContentItem(
      imagePath: 'assets/img/reading_1.png',
      title: 'Pengenalan React Native dan Redux Toolkit',
      subtitle: 'Part Terakhir Dibaca',
    ),
    ContentItem(
      imagePath: 'assets/img/reading_2.png',
      title: 'Optimasi Database SQL dan Indexing',
      subtitle: 'Part Terakhir Dibaca',
    ),
    ContentItem(
      imagePath: 'assets/img/reading_3.png',
      title: 'Struktur Data dan Algoritma Dasar',
      subtitle: 'Part Terakhir Dibaca',
    ),
    ContentItem(
      imagePath: 'assets/img/reading_1.png',
      title: 'Cara Kerja Serverless Computing',
      subtitle: 'Part Terakhir Dibaca',
    ),
  ];

  final List<Widget> _screens = [
    const SizedBox(),
    const Center(child: Text('Halaman Search')),
    const LibraryScreen(),
    const Center(child: Text('Halaman Bookmark')),
    const Center(child: Text('Halaman Profile')),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildHomeBody(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 10),
              _buildFeaturedContent(),
              _buildSectionTitle(title: 'Top picks for you'),
              _buildHorizontalList(
                height: 200,
                count: _topPicksContent.length,
                listType: 'picks',
              ),
              _buildSectionTitle(title: 'Continue reading'),
              _buildHorizontalList(
                height: 220,
                count: _continueReadingContent.length,
                listType: 'reading',
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHome = _currentIndex == 0;

    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: isHome
          ? AppBar(
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
                        children: const <Widget>[
                          Text(
                            'Halo Firza!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Siap eksplor bacaan baru untuk belajar?',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: _paddingHorizontal),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage('assets/img/pp.jpg'),
                    ),
                  ),
                ],
              ),
              automaticallyImplyLeading: false,
            )
          : null,

      body: isHome ? _buildHomeBody(context) : _screens[_currentIndex],

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _featuredContent.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = _featuredContent[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: const BoxDecoration(color: AppColors.softBlue),
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Gambar tidak ditemukan',
                            style: TextStyle(color: AppColors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: _DotIndicator(
            count: _featuredContent.length,
            currentIndex: _currentPage,
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

  Widget _buildHorizontalList({
    required double height,
    required int count,
    required String listType,
  }) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        padding: const EdgeInsets.symmetric(horizontal: _paddingHorizontal),
        itemBuilder: (context, index) {
          ContentItem item;
          if (listType == 'picks') {
            item = _topPicksContent[index];
          } else {
            item = _continueReadingContent[index];
          }
          return Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: SizedBox(
              width: 150,
              child: _buildContentCard(item: item, listType: listType),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentCard({
    required ContentItem item,
    required String listType,
  }) {
    return Column(
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
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    'Gagal memuat gambar',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
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
        if (listType == 'reading' && item.subtitle != null)
          Text(
            item.subtitle!,
            style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
          ),
      ],
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
