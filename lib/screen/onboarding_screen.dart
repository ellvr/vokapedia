import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import '../utils/color_constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/img/onboard1.svg",
      "title": "Halo, Selamat Datang di VokaPedia",
      "desc":
          "Platform pembelajaran yang menyediakan materi Bahasa Indonesia dalam arsip digital yang lebih mudah diakses.",
    },
    {
      "image": "assets/img/onboard2.svg",
      "title": "Highlight Bagian Penting, Simpan untuk Nanti",
      "desc":
          "Sorot kalimat yang menurutmu penting, lalu simpan ke bookmark agar kamu bisa kembali ke bagian tersebut tanpa perlu mencari ulang.",
    },
    {
      "image": "assets/img/onboard3.svg",
      "title": "Yuk Bangun Ruang Belajarmu Sendiri!",
      "desc":
          "Simpan materi favoritmu dan buka kembali kapan saja. Yuk mulai perjalanan belajar sesuai dengan ritmemu.",
    },
  ];

  void nextPage() {
    if (currentPage < onboardingData.length - 1) {
      _controller.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void prevPage() {
    if (currentPage > 0) {
      _controller.animateToPage(
        currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),

          const Center(
            child: Text(
              "VokaPedia",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 40),

          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() => currentPage = index);
              },
              itemBuilder: (_, i) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Image
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: SvgPicture.asset(
                          onboardingData[i]["image"]!,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // TITLE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          onboardingData[i]["title"]!,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // DESCRIPTION
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          onboardingData[i]["desc"]!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.darkGrey,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
            child: Row(
              children: [
                GestureDetector(
                  onTap: prevPage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                ),

                const SizedBox(width: 16),

                Row(
                  children: List.generate(
                    onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentPage == index ? 10 : 6,
                      height: currentPage == index ? 10 : 6,
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? Colors.black
                            : Colors.black26,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),
                GestureDetector(
                  onTap: nextPage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),

                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    "Lewati",
                    style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
