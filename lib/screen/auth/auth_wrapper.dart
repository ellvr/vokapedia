// auth_wrapper.dart (atau di main.dart)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/screen/home_screen.dart';
import 'package:vokapedia/screen/onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return FutureBuilder<String>(
            future: _fetchUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userRole = roleSnapshot.data ?? 'user';

              return HomeScreen(userRole: userRole);
            },
          );
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
