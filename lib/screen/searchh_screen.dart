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

  InlineSpan highlightText(String text, String query) {
    // ... (kode highlightText tetap sama)
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

  // ================================
  // ✂️ FUNGSI UNTUK EXTRACT SNIPPET (WAJIB ADA)
  // ================================
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

  // 🏷️ WIDGET TAG
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

  // ================================
  // 📦 WIDGET CARD LIST ARTIKEL (DIUBAH UNTUK HANDLE ERROR IMAGE)
  // ================================
  // ================================
  // 📦 WIDGET CARD LIST ARTIKEL (DIUBAH UNTUK HANDLE BASE64/URL)
  // ================================
  Widget _buildArticleListItem(
    Article item, {
    bool showSnippet = false,
    String query = '',
  }) {
    // 1. Cek apakah ini Base64 String yang Valid (Biasanya Base64 sangat panjang)
    bool isBase64Data =
        item.imagePath.length > 100 && !item.imagePath.startsWith('http');

    // 2. Cek apakah ini Network URL yang Valid
    bool isNetworkUrl =
        item.imagePath.startsWith('http://') ||
        item.imagePath.startsWith('https://');

    Widget imageWidget;

    if (isNetworkUrl) {
      // KASUS 1: Ini adalah Network URL
      imageWidget = Image.network(
        item.imagePath,
        width: 84,
        height: 108,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback jika URL gagal dimuat
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
      // KASUS 2: Ini adalah Base64 String. Lakukan konversi.
      try {
        // Hilangkan 'data:image/png;base64,' jika ada. Asumsi Base64 murni.
        String base64String = item.imagePath.contains(',')
            ? item.imagePath.split(',').last
            : item.imagePath;

        // Konversi string Base64 ke Uint8List
        Uint8List imageBytes = base64Decode(base64String);

        imageWidget = Image.memory(
          imageBytes,
          width: 84,
          height: 108,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // Fallback jika konversi Base64 gagal
        debugPrint('Base64 Decode Error: $e');
        imageWidget = const Center(
          child: Icon(Icons.error_outline, size: 40, color: AppColors.darkGrey),
        );
      }
    } else {
      // KASUS 3: Path kosong atau tidak valid (tampilkan placeholder)
      imageWidget = const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: AppColors.darkGrey,
        ),
      );
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
            // Gambar Artikel
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 84,
                height: 108,
                color: AppColors.softBlue,
                child:
                    imageWidget, // <-- Menggunakan widget gambar yang sudah ditentukan
              ),
            ),
            const SizedBox(width: 12),

            // ... (Sisa konten Artikel, sama seperti sebelumnya)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tampilkan Snippet atau Tags
                  if (showSnippet)
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: highlightText(
                        extractSnippet(
                          "${item.title} ${item.author} ${item.abstractContent ?? ""} ${item.sections.map((s) {
                            final head = s["heading"] ?? "";
                            final paras = s["paragraphs"] is List ? (s["paragraphs"] as List).join(" ") : (s["paragraphs"] ?? "");
                            return "$head $paras";
                          }).join(" ")}",
                          query,
                        ),
                        query,
                      ),
                    )
                  else
                    // Tampilkan Tags jika bukan hasil pencarian (Artikel Terbaru)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        _buildTag('RPL'),
                        _buildTag('XI'),
                        _buildTag('PAPB'),
                      ],
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
          // ------------------------------
          // SEARCH BAR + CLEAR BUTTON (TIDAK BERUBAH)
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
                        padding: const EdgeInsets.only(
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
                        return const Center(child: Text("Tidak ada artikel yan ditemukan."));
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
