import 'package:flutter/material.dart';
import 'package:vokapedia/utils/color_constants.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'FAQ & Panduan',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _FAQItem(
            question: 'Apa itu VokaPedia?',
            answer:
                'VokaPedia adalah platform pembelajaran Bahasa Indonesia berbasis arsip digital yang membantu pengguna mengakses, membaca, dan menyimpan materi pembelajaran dengan lebih mudah dan terstruktur.',
          ),
          _FAQItem(
            question: 'Bagaimana cara membaca dan menjelajahi materi?',
            answer:
                'Kamu bisa menjelajahi materi melalui halaman Beranda atau Library. Pilih artikel yang ingin dibaca, lalu scroll untuk menikmati isi materi secara lengkap sekaligus penanda terakhir dibaca.',
          ),
          _FAQItem(
            question: 'Apakah data saya aman?',
            answer:
                'Ya. Data pribadi Anda disimpan secara aman dan hanya digunakan '
                'untuk keperluan aplikasi sesuai dengan kebijakan privasi.',
          ),
          _FAQItem(
            question: 'Apa fungsi bookmark pada artikel?',
            answer:
                'Fitur bookmark memungkinkan kamu menandai kalimat atau bagian penting dalam artikel agar lebih mudah diingat dan dipelajari kembali.',
          ),
          _FAQItem(
            question: 'Apakah progres membaca saya akan tersimpan?',
            answer:
                'Ya. VokaPedia secara otomatis menyimpan progres membaca, sehingga kamu bisa melanjutkan membaca artikel dari bagian terakhir yang kamu baca.',
          ),
          _FAQItem(
            question: 'Apakah saya bisa mengubah data profil saya?',
            answer:
                'Tentu. Kamu dapat mengubah data diri seperti nama dan informasi lainnya melalui menu Profil → Data Diri. Perubahan akan tersimpan secara otomatis di akunmu.',
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          textAlign: TextAlign.justify,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
