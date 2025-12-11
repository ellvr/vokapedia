// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../utils/color_constants.dart';  

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String fullText = "VokaPedia";
  String currentText = "";
  int index = 0;
  bool showCursor = true;

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (index < fullText.length) {
        setState(() {
          currentText += fullText[index];
          index++;
        });
      } else {
        timer.cancel();

        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        });
      }
    });

    Timer.periodic(const Duration(milliseconds: 550), (_) {
      setState(() {
        showCursor = !showCursor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentText,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),

            AnimatedOpacity(
              opacity: showCursor ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,     
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
