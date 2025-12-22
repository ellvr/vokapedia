// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vokapedia/services/firestore_services.dart';
import 'package:vokapedia/models/article_model.dart';
import 'package:vokapedia/screen/article_detail_screen.dart';
import '../utils/color_constants.dart';

class SearchhScreen extends StatefulWidget {
  const SearchhScreen({super.key});

  @override
  State<SearchhScreen> createState() => _SearchhScreenState();
}

class _SearchhScreenState extends State<SearchhScreen> {
  String searchText = "";
  final TextEditingController _controller = TextEditingController();

  final List<String> categories = [
    "Materi Belajar",
    "Sastra",
    "Artikel Populer",
    "Artikel Ilmiah",
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 7) return "${date.day}/${date.month}/${date.year}";
    if (difference.inDays > 0) return "${difference.inDays} hari lalu";
    if (difference.inHours > 0) return "${difference.inHours} jam lalu";
    if (difference.inMinutes > 0) return "${difference.inMinutes} menit lalu";
    return "Baru saja";
  }

  Widget _buildArticleImage(String imagePath) {
    if (imagePath.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, color: AppColors.darkGrey),
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 84,
        height: 108,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBlue,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      try {
        String base64String = imagePath.contains(',')
            ? imagePath.split(',').last
            : imagePath;
        Uint8List imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          width: 84,
          height: 108,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
        );
      } catch (e) {
        return const Icon(Icons.error_outline);
      }
    }
  }

  InlineSpan highlightText(String text, String query, TextStyle baseStyle) {
    final lower = text.toLowerCase();
    final q = query.toLowerCase();

    if (q.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    List<InlineSpan> spans = [];
    int start = 0;
    int index;

    while ((index = lower.indexOf(q, start)) != -1) {
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              text.substring(index, index + q.length),
              style: baseStyle.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      start = index + q.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    return TextSpan(children: spans);
  }

  Widget _buildTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildArticleListItem(Article item, {String query = ''}) {
    final List<String> displayTags = [];
    displayTags.add(item.topic.toUpperCase());
    if (item.tags != null) displayTags.addAll(item.tags!);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(articleId: item.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 84,
                height: 108,
                color: AppColors.softBlue,
                child: _buildArticleImage(item.imagePath),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: highlightText(
                      item.title,
                      query,
                      const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: highlightText(
                      item.author,
                      query,
                      const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                        fontFamily: 'PlayfairDisplay',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: displayTags
                        .take(3)
                        .map((tag) => _buildTag(tag))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Diunggah: ${_formatDate(item.createdAt?.toDate() ?? DateTime.now())}",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => searchText = value),
              decoration: InputDecoration(
                hintText: 'Cari artikel atau topik...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => searchText = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected =
                    searchText.toLowerCase() == cat.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _controller.text = cat;
                          searchText = cat;
                        } else {
                          _controller.clear();
                          searchText = "";
                        }
                      });
                    },
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: const Color.fromARGB(255, 238, 245, 255),
                    shape: StadiumBorder(side: BorderSide.none),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.black,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: searchText.isEmpty
                ? _buildLatestSection()
                : _buildResultsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            "Artikel Terbaru",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Article>>(
            stream: getLatestArticles(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) =>
                    _buildArticleListItem(snapshot.data![index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return StreamBuilder<List<Article>>(
      stream: searchArticles(searchText),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(child: Text("Tidak ada hasil ditemukan."));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          itemBuilder: (context, index) =>
              _buildArticleListItem(results[index], query: searchText),
        );
      },
    );
  }
}
