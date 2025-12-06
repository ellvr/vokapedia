// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:vokapedia/models/article_model.dart';

// class HiveLocalStorageService {
//   static const String articleBoxName = 'articleBox';

//   // Inisialisasi Hive
//   static Future<void> init() async {
//     await Hive.initFlutter();
//     // Daftarkan ArticleAdapter yang dibuat oleh build_runner
//     if (!Hive.isAdapterRegistered(ArticleAdapter().typeId)) {
//       Hive.registerAdapter(ArticleAdapter());
//     }
//     await Hive.openBox<Article>(articleBoxName);
//   }

//   // Simpan artikel ke Hive
//   static Future<void> saveArticle(Article article) async {
//     final box = Hive.box<Article>(articleBoxName);
//     // Gunakan ID artikel sebagai key Hive
//     await box.put(article.id, article); 
//   }

//   // Ambil artikel berdasarkan ID
//   static Article? getArticle(String articleId) {
//     final box = Hive.box<Article>(articleBoxName);
//     return box.get(articleId);
//   }

//   // Hapus artikel (jika pengguna menghapus dari library)
//   static Future<void> deleteArticle(String articleId) async {
//     final box = Hive.box<Article>(articleBoxName);
//     await box.delete(articleId);
//   }
// }