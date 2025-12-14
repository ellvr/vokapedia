import 'package:flutter/material.dart';
import 'package:vokapedia/utils/color_constants.dart';

class TentangVocaPediaScreen extends StatelessWidget {
  const TentangVocaPediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Tentang VokaPedia',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Image.asset('assets/img/Mockup.png'),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'VokaPedia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'VokaPedia adalah platform pembelajaran yang menyediakan materi Bahasa Indonesia dalam bentuk arsip digital yang tersusun rapi, sehingga lebih mudah diakses, dipelajari, dan digunakan oleh pengguna kapan saja dan di mana saja.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 20),
            Text('Versi Aplikasi: 1.0.0'),
          ],
        ),
      ),
    );
  }
}
