import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/screen/auth/login_screen.dart';
import 'package:vokapedia/screen/home_screen.dart';
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
    _startAnimation();
  }

  Future<String> _fetchUserRole(String uid) async {
    try {
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (snap.exists && (snap.data() as Map).containsKey("role")) {
        return snap["role"];
      }
      return "user";
    } catch (e) {
      return "user";
    }
  }

  void _startAnimation() {
    Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (index < fullText.length) {
        if (mounted) {
          setState(() {
            currentText += fullText[index];
            index++;
          });
        }
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 800), _checkAuthStatus);
      }
    });

    Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (mounted) {
        setState(() {
          showCursor = !showCursor;
        });
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    Widget destinationScreen;
    String userRole = 'user';

    if (user != null) {
      userRole = await _fetchUserRole(user.uid);
      destinationScreen = HomeScreen(userRole: userRole);
    } else {
      destinationScreen = const LoginScreen();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinationScreen),
      );
    }
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