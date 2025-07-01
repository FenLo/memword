import 'package:flutter/material.dart';
import 'package:memoword/screens/category_screen.dart';
import 'package:memoword/models/word.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // Define colors from the design system
    const Color primaryPurple = Color(0xFF8B5CF6);
    const Color primaryPink = Color(0xFFEC4899);
    const Color neutralWhite = Color(0xFFFFFFFF);
    const Color neutralLightGray = Color(0xFFF8F9FA);
    const Color neutralMediumGray = Color(0xFF6B7280);
    const Color neutralDarkGray = Color(0xFF374151);

    return MaterialApp(
      title: 'MemoWord',
      theme: ThemeData(
        // Use Material 3
        useMaterial3: true,

        // Color Scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          brightness: Brightness.light,
          primary: primaryPurple,
          secondary: primaryPink,
          surface: neutralWhite,
          onSurface: neutralDarkGray,
          background: neutralLightGray,
          onBackground: neutralDarkGray,
        ),

        // Typography
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: neutralDarkGray),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: neutralDarkGray),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: neutralDarkGray),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: neutralDarkGray),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: neutralMediumGray),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: neutralMediumGray),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: neutralMediumGray),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: neutralWhite), // For buttons
        ),

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: neutralDarkGray,
          ),
        ),

        // Card Theme (Glassmorphic style)
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // large borderRadius
          ),
          color: neutralWhite.withOpacity(0.8), // cardBackground
          shadowColor: Colors.black.withOpacity(0.1), // card shadow color
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), // medium borderRadius
            borderSide: BorderSide.none, // No border by default for filled fields
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryPurple, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: neutralWhite.withOpacity(0.1), // glassmorphic background for inputs
          labelStyle: const TextStyle(color: neutralMediumGray),
          hintStyle: const TextStyle(color: neutralMediumGray),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple, // primary.purple
            foregroundColor: neutralWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0), // circular borderRadius for buttons
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // padding [16, 32]
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), // button typography
            elevation: 8, // floating shadow elevation
            shadowColor: Colors.black.withOpacity(0.15), // floating shadow color
          ),
        ),

        // Floating Action Button Theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryPurple,
          foregroundColor: neutralWhite,
          elevation: 8, // floating shadow elevation
        ),
      ),
      home: CategoryScreen(),
    );
  }
}