import 'package:flutter/material.dart';

// --- GLOBAL BRANDING & CONSTANTS ---
const Color nagcarlanWhite = Colors.white; // Primary
const Color nagcarlanGreen = Color(0xFF14532D); // Secondary: Deep green
const Color nagcarlanYellow = Color(0xFFFACC15); // Tertiary: Vibrant yellow accent

const BoxDecoration nagcarlanGradient = BoxDecoration(
  gradient: LinearGradient(
    colors: [nagcarlanWhite, Color(0xFFF8F9FA), Color(0xFFF1F3F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
);
