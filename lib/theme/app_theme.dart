import 'package:flutter/material.dart';

/// audistine 앱 전체 톤앤매너 (고전적이고 차분한 한지/먹빛/비취/황동 톤)
class AppColors {
  // 배경색 (따뜻하고 깊이 있는 미색/한지 톤)
  static const Color bgDeep = Color(0xFFF7F5F0);
  static const Color bgPanel = Color(0xFFFFFFFF);
  static const Color bgPanel2 = Color(0xFFF1EFEA);
  static const Color bgCardWarm = Color(0xFFFAF8F5);

  // 라인 / 구분선
  static const Color inkLine = Color(0xFFE5DFD5);
  static const Color inkLineLight = Color(0xFFEFEBE4);

  // 포인트 / 강조색
  static const Color accentBrass = Color(0xFFB08A5A); // 고전적인 황동/골드
  static const Color accentBrassSoft = Color(0xFFD4B996);
  static const Color accentJade = Color(0xFF437865); // 차분한 비취/쑥색
  static const Color accentNavy = Color(0xFF2B3A4A); // 깊은 먹색/남색
  static const Color accentVermilion = Color(0xFFBD4A3C); // 단청 주홍색

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF2C2825);
  static const Color textSecondary = Color(0xFF5E574F);
  static const Color textMuted = Color(0xFF8E867C);
  static const Color textDim = Color(0xFFB5ADA2);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'GowunDodum',
    scaffoldBackgroundColor: AppColors.bgDeep,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accentBrass,
      surface: AppColors.bgDeep,
      primary: AppColors.accentBrass,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDeep,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgPanel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.inkLine),
      ),
    ),
  );
}
