// ignore_for_file: deprecated_member_use

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InlineSpan highlightText(String text, String query) {
    final lower = text.toLowerCase();
    final q = query.toLowerCase();

    List<InlineSpan> spans = [];
    int start = 0;
    int index;

    while ((index = lower.indexOf(q, start)) != -1) {
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: const TextStyle(color: AppColors.black),
          ),
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
              style: const TextStyle(
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
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: const TextStyle(color: AppColors.black),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            title: TextField(
              controller: _controller,
              onChanged: (value) {
                setState(() => searchText = value);
              },
              decoration: InputDecoration(
                hintText: 'Cari judul, penulis, atau topik...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: searchText.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() => searchText = "");
                        },
                        child: const Icon(Icons.close, size: 20),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            titleSpacing: 0,
          ),
        ),
      ),

      body: searchText.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 8,
                    bottom: 8,
                  ),
                  child: Text(
                    "Artikel Terbaru",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),

                SizedBox(
                  height: 150,
                  child: StreamBuilder<List<Article>>(
                    stream: getLatestArticles(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("Tidak ada artikel terbaru."),
                        );
                      }

                      final latest = snapshot.data!;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: latest.length,
                        itemBuilder: (context, index) {
                          final item = latest[index];
                          return _buildLatestArticleCard(context, item);
                        },
                      );
                    },
                  ),
                ),
              ],
            )
          : StreamBuilder<List<Article>>(
              stream: searchArticles(searchText),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  );
                }

                final results = snapshot.data!;
                if (results.isEmpty) {
                  return const Center(
                    child: Text(
                      "Tidak ada artikel yang cocok dengan pencarian Anda.",
                      style: TextStyle(color: AppColors.darkGrey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];

                    final fullText =
                        "${item.title} ${item.author} ${item.abstractContent ?? ""} "
                        "${item.sections.map((s) {
                          final head = s["heading"] ?? "";
                          final paras = s["paragraphs"] is List ? (s["paragraphs"] as List).join(" ") : (s["paragraphs"] ?? "");
                          return "$head $paras";
                        }).join(" ")}";

                    final snippet = extractSnippet(fullText, searchText);

                    return _buildSearchResultItem(context, item, snippet);
                  },
                );
              },
            ),
    );
  }

  Widget _buildLatestArticleCard(BuildContext context, Article item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(articleId: item.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                item.imagePath,
                height: 80,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  height: 80,
                  width: 160,
                  color: AppColors.backgroundLight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(
    BuildContext context,
    Article item,
    String snippet,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(articleId: item.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.backgroundLight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: highlightText(snippet, searchText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
