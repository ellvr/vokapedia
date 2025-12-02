import 'package:flutter/material.dart';
import '../widget/custom_bottom_navbar.dart';
import '../utils/color_constants.dart';

const double _paddingHorizontal = 20.0;
const double _spacingVertical = 20.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(),
              _buildFeaturedContent(),
              _buildSectionTitle(title: 'Top picks for you'),
              _buildHorizontalList(height: 250, count: 5, listType: 'picks'),
              _buildSectionTitle(title: 'Continue reading'),
              _buildHorizontalList(height: 250, count: 5, listType: 'reading'),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(_paddingHorizontal),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text(
                  'Halo Firza!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(
                'https://via.placeholder.com/150'), 
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: const Center(
                  child: Text(
                    'Featured Content',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: _DotIndicator(count: 3, currentIndex: 0),
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHorizontalList({required double height, required int count, required String listType}) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        padding: const EdgeInsets.symmetric(horizontal: _paddingHorizontal),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: SizedBox(
              width: 150,
              child: _buildContentCard(listType: listType),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentCard({required String listType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300)
          ),
          child: const Center(
            child: Text(
              'Area Diagram/Gambar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Judul Konten Placeholder',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        if (listType == 'reading')
            const Text(
            'Part Terakhir Dibaca',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
            color: index == currentIndex ? Colors.blue : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}