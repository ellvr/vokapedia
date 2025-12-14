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
            question: 'Apa itu VocaPedia?',
            answer:
                'VocaPedia adalah platform pembelajaran yang menyediakan materi '
                'Bahasa Indonesia dalam bentuk arsip digital yang mudah diakses '
                'kapan saja dan di mana saja.',
          ),
          _FAQItem(
            question: 'Bagaimana cara mengubah data diri?',
            answer:
                'Anda dapat mengubah data diri melalui menu Profil lalu memilih '
                'Data Diri. Setelah melakukan perubahan, tekan tombol Simpan.',
          ),
          _FAQItem(
            question: 'Apakah data saya aman?',
            answer:
                'Ya. Data pribadi Anda disimpan secara aman dan hanya digunakan '
                'untuk keperluan aplikasi sesuai dengan kebijakan privasi.',
          ),
          _FAQItem(
            question: 'Bagaimana jika lupa akun?',
            answer:
                'Silakan lakukan login ulang menggunakan email yang terdaftar '
                'atau hubungi admin melalui menu Laporkan Masalah.',
          ),
          _FAQItem(
            question: 'Bagaimana cara melaporkan bug?',
            answer:
                'Anda dapat melaporkan bug atau kendala melalui halaman '
                'Laporkan Masalah yang tersedia di menu Profil.',
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
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
