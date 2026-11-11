import 'package:flutter/material.dart';

const kBlue = Color(0xFF1A56DB);
const kGreen = Color(0xFF16A34A);
const kBg = Color(0xFFF5F8FC);
const kText = Color(0xFF14213D);
const kMuted = Color(0xFF6B7A90);
const kBorder = Color(0xFFE3E9F2);
const kBlueSoft = Color(0xFFE8F0FF);
const kRed = Color(0xFFDC2626);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: kBlue, primary: kBlue),
      scaffoldBackgroundColor: kBg,
      appBarTheme: const AppBarTheme(
          backgroundColor: kBg, foregroundColor: kText, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBlue, width: 1.5)),
      ),
    );
