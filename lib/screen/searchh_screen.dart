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

  // ================================
  // 🔍 HIGHLIGHT FUNCTION
  // ================================
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
    return SafeArea(
      child: Column(
        children: [
          // ------------------------------
          // SEARCH BAR + CLEAR BUTTON
          // ------------------------------
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 🔙 BACK BUTTON
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.arrow_back, color: AppColors.black),
                  ),
                ),

                const SizedBox(width: 12),

                // 🔍 SEARCH FIELD
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (value) {
                      setState(() => searchText = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for title or author...',
                      prefixIcon: const Icon(Icons.search),

                      // ❌ CLEAR BUTTON
                      suffixIcon: searchText.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() => searchText = "");
                              },
                              child: const Icon(Icons.close),
                            )
                          : null,

                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: searchText.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================================
                      // 🔵 TITLE: ARTIKEL TERBARU
                      // ================================
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
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

                      // ================================
                      // 🔄 STREAMBUILDER ARTIKEL TERBARU
                      // ================================
                      SizedBox(
                        height: 140,
                        child: StreamBuilder<List<Article>>(
                          stream:
                              getLatestArticles(), // ← pastikan sudah import
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                ),
                              );
                            }

                            final latest = snapshot.data!;

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: latest.length,
                              itemBuilder: (context, index) {
                                final item = latest[index];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ArticleDetailScreen(
                                          articleId: item.id,
                                        ),
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
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          child: Image.network(
                                            item.imagePath,
                                            height: 80,
                                            width: 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
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
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  )
                // ================================
                // 🔍 SEARCH RESULT
                // ================================
                : StreamBuilder<List<Article>>(
                    stream: searchArticles(searchText),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        );
                      }

                      final results = snapshot.data!;
                      if (results.isEmpty) {
                        return const Center(child: Text("No articles found."));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          // ... kode hasil search kamu (tetap sama)
                          final item = results[index];
                          final fullText =
                              "${item.title} ${item.author} ${item.abstractContent ?? ""} "
                              "${item.sections.map((s) {
                                final head = s["heading"] ?? "";
                                final paras = s["paragraphs"] is List ? (s["paragraphs"] as List).join(" ") : (s["paragraphs"] ?? "");
                                return "$head $paras";
                              }).join(" ")}";

                          final snippet = extractSnippet(fullText, searchText);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ArticleDetailScreen(articleId: item.id),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.imagePath,
                                      width: 84,
                                      height: 108,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
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
                                          text: highlightText(
                                            snippet,
                                            searchText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
