import 'package:flutter/material.dart';
import 'package:vokapedia/utils/color_constants.dart';

class KeamananPrivasiScreen extends StatelessWidget {
  const KeamananPrivasiScreen({super.key});

  Widget _section({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style:  TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Keamanan & Privasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _section(
              icon: Icons.lock,
              title: 'Keamanan Akun',
              description:
                  'Akun Anda dilindungi dengan sistem autentikasi yang aman. '
                  'Jangan membagikan informasi login kepada siapa pun.',
            ),
            _section(
              icon: Icons.privacy_tip_rounded,
              title: 'Privasi Data',
              description:
                  'Data pribadi hanya digunakan untuk kebutuhan aplikasi dan '
                  'tidak dibagikan kepada pihak lain tanpa persetujuan Anda.',
            ),
            _section(
              icon: Icons.storage,
              title: 'Penyimpanan Data',
              description:
                  'Semua data disimpan secara aman dan dilindungi dengan standar keamanan.',
            ),
            _section(
              icon: Icons.warning,
              title: 'Tanggung Jawab Pengguna',
              description:
                  'Pengguna bertanggung jawab atas aktivitas akun. '
                  'Segera laporkan jika terjadi aktivitas mencurigakan.',
            ),
          ],
        ),
      ),
    );
  }
}
