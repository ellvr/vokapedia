import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vokapedia/screen/splash_screen.dart';
import 'package:vokapedia/services/hive_local_storage_services.dart';
import 'firebase_options.dart';

import 'screen/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      // home: SplashScreen(),
      theme: ThemeData(fontFamily: 'PlayfairDisplay', useMaterial3: true),
    );
  }
}
