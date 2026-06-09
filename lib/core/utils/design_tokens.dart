import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF1E40AF);
  static const accent = Color(0xFF3B82F6);
  static const ink = Color(0xFF101828);
  static const inkMuted = Color(0xFF6B7280);
  static const background = Color(0xFFF4F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFD8E1F0);
  static const success = Color(0xFF17B26A);
  static const warning = Color(0xFFF79009);
  static const danger = Color(0xFFEF4444);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 30.0;
}
