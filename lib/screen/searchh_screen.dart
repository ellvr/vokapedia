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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} hari lalu";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} jam lalu";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} menit lalu";
    } else {
      return "Baru saja";
    }
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

  String extractSnippet(String fullText, String query) {
    final lowerText = fullText.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index != -1) {
      const int contextLength = 50;
      int start = index - contextLength;
      int end = index + lowerQuery.length + contextLength;

      if (start < 0) start = 0;
      if (end > fullText.length) end = fullText.length;

      String snippet = fullText.substring(start, end);

      if (start > 0) snippet = "...$snippet";
      if (end < fullText.length) snippet = "$snippet...";

      return snippet.trim();
    }
    return fullText.substring(0, fullText.length > 200 ? 200 : fullText.length);
  }

  Widget _buildTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBlue, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  Widget _buildArticleListItem(
    Article item, {
    bool showSnippet = false,
    String query = '',
  }) {
    bool isNetworkUrl =
        item.imagePath.startsWith('http://') ||
        item.imagePath.startsWith('https://');
    bool isBase64Data = item.imagePath.length > 100 && !isNetworkUrl;

    Widget imageWidget;

    if (isNetworkUrl) {
      imageWidget = Image.network(
        item.imagePath,
        width: 84,
        height: 108,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 40,
              color: AppColors.darkGrey,
            ),
          );
        },
      );
    } else if (isBase64Data) {
      try {
        String base64String = item.imagePath.contains(',')
            ? item.imagePath.split(',').last
            : item.imagePath;

        Uint8List imageBytes = base64Decode(base64String);

        imageWidget = Image.memory(
          imageBytes,
          width: 84,
          height: 108,
          fit: BoxFit.cover,
        );
      } catch (e) {
        debugPrint('Base64 Decode Error: $e');
        imageWidget = const Center(
          child: Icon(Icons.error_outline, size: 40, color: AppColors.darkGrey),
        );
      }
    } else {
      imageWidget = const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: AppColors.darkGrey,
        ),
      );
    }

    String fullText = '';
    if (showSnippet) {
      final sectionsText = item.sections
          .map((s) {
            final head = s["heading"] ?? "";
            final paras = s["paragraphs"] is List
                ? (s["paragraphs"] as List).join(" ")
                : (s["paragraphs"] ?? "");
            return "$head $paras";
          })
          .join(" ");

      fullText =
          "${item.title} ${item.author} ${item.abstractContent ?? ""} $sectionsText";
    }

    final DateTime articleDate = item.createdAt?.toDate() ?? DateTime.now();

    final List<String> displayTags = [];

    if (item.kelas != null && item.kelas!.isNotEmpty) {
      displayTags.add(item.kelas!.toUpperCase());
    }

    if (item.tags != null) {
      if (item.tags is String && (item.tags as String).isNotEmpty) {
        final optionalTags = (item.tags as String)
            .split(RegExp(r'[,\s]+'))
            .where(
              (tag) =>
                  tag.isNotEmpty &&
                  tag.toUpperCase() != item.kelas?.toUpperCase(),
            )
            .toList();
        displayTags.addAll(optionalTags);
      } else if (item.tags is List) {
        final List<String> tagsList = (item.tags as List)
            .whereType<String>()
            .toList();

        final optionalTags = tagsList
            .where(
              (tag) =>
                  tag.isNotEmpty &&
                  tag.toUpperCase() != item.kelas?.toUpperCase(),
            )
            .toList();
        displayTags.addAll(optionalTags);
      }
    }

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
                child: imageWidget,
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
                    text: showSnippet
                        ? highlightText(item.title, query)
                        : TextSpan(
                            text: item.title,
                            style: const TextStyle(
                              fontSize: 16,
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
                    text: showSnippet
                        ? highlightText(item.author, query)
                        : TextSpan(
                            text: item.author,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkGrey,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),

                  if (showSnippet)
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: highlightText(
                        extractSnippet(fullText, query),
                        query,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: displayTags
                          .map((tag) => _buildTag(tag))
                          .toList(),
                    ),

                  const SizedBox(height: 6),

                  Text(
                    "Diunggah: ${_formatDate(articleDate)}",
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
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              onChanged: (value) {
                setState(() => searchText = value);
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),

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

          Expanded(
            child: searchText.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
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

                      Expanded(
                        child: StreamBuilder<List<Article>>(
                          stream: getLatestArticles(),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: latest.length,
                              itemBuilder: (context, index) {
                                final item = latest[index];
                                return _buildArticleListItem(
                                  item,
                                  showSnippet: false,
                                );
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
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        );
                      }

                      final results = snapshot.data!;
                      if (results.isEmpty) {
                        return const Center(
                          child: Text("Tidak ada artikel yang ditemukan."),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return _buildArticleListItem(
                            item,
                            showSnippet: true,
                            query: searchText,
                          );
                        },
                      );
                    },
                  ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
