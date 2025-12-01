import 'package:flutter/material.dart';

class AppColors {
    static const Color black = Color(0xFF252525);
    static const Color white = Color(0xFFF9F9F9); 
    static const Color darkGrey = Color(0xFF929292); 

    static const Color primaryBlue = Color(0xFF0D6EFD);
    static const Color backgroundLight = Color(0xFFF0F0F0);
    static const Color softBlue = Color(0xFFDBE9FF); 
}

class AppGradients { 
  static const LinearGradient gradientBlue = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    
    colors: [
      Color(0xFF0D6EFD), 
      Color(0xFF3E8CFE),
      Color(0xFF70AAFF),
    ],
    
    stops: [
      0.0, 
      0.54, 
      1.0,
    ],
  );
}