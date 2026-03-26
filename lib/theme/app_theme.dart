import 'package:flutter/material.dart';

class AppTheme {
  static Color background = Color(0xFF212121);
  static Color surface = Color(0xFF2F2F2F);
  static Color surfaceAlt = Color(0xFF3A3A3A);
  static Color sidebar = Color(0xFF171717);
  static Color textPrimary = Color(0xFFECECEC);
  static Color textSecondary = Color(0xFF9A9A9A);
  static Color accent = Color(0xFF10A37F);
  static Color accentGlow = Color(0x3310A37F);
  static Color border = Color(0xFF3E3E3E);
  static Color online = Color(0xFF10A37F);
  static Color offline = Color(0xFF6B7280);
  static Color auto_ = Color(0xFFFFA500);

  static Color customAccent = Color(0xFFE50914);
  static String currentTheme = 'Dark';
  static late ThemeData themeData;
  
  // Gradient colors for enhanced visuals
  static Color gradientStart = Color(0xFF10A37F);
  static Color gradientEnd = Color(0xFF0D8A6B);
  static Color gradientMiddle = Color(0xFF0E9574);
  
  // Shadow and elevation
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  
  static List<BoxShadow> glowShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  
  // Helper method to create gradient
  static LinearGradient getGradient() {
    return LinearGradient(
      colors: [gradientStart, gradientMiddle, gradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  // Helper method for accent gradient
  static LinearGradient getAccentGradient() {
    return LinearGradient(
      colors: [accent, accent.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const List<String> availableThemes = [
    'Dark',
    'Light',
    'Midnight',
    'Ocean',
    'Sunset',
    'Cyberpunk',
    'Blossom',
    'Light Blossom',
    'Red Velvet',
    'Light Red Velvet',
  ];

  static void setTheme(String themeName) {
    currentTheme = themeName;
    switch (themeName) {
      case 'Light':
        background = Color(0xFFFAFAFA);
        surface = Color(0xFFFFFFFF);
        surfaceAlt = Color(0xFFF5F5F5);
        sidebar = Color(0xFFF8F8F8);
        textPrimary = Color(0xFF0F172A);
        textSecondary = Color(0xFF64748B);
        accent = Color(0xFF10A37F);
        accentGlow = Color(0x2210A37F);
        border = Color(0xFFE2E8F0);
        online = Color(0xFF10A37F);
        auto_ = Color(0xFFF59E0B);
        gradientStart = Color(0xFF10A37F);
        gradientEnd = Color(0xFF0D8A6B);
        cardShadow = [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))];
        elevatedShadow = [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4))];
        themeData = _buildTheme(Brightness.light);
        break;
      case 'Midnight':
        background = Color(0xFF0D1117);
        surface = Color(0xFF161B22);
        surfaceAlt = Color(0xFF21262D);
        sidebar = Color(0xFF010409);
        textPrimary = Color(0xFFE6EDF3);
        textSecondary = Color(0xFF8B949E);
        accent = Color(0xFF58A6FF);
        accentGlow = Color(0x4458A6FF);
        border = Color(0xFF30363D);
        online = Color(0xFF3FB950);
        auto_ = Color(0xFFFFA657);
        gradientStart = Color(0xFF58A6FF);
        gradientEnd = Color(0xFF388BFD);
        cardShadow = [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))];
        elevatedShadow = [BoxShadow(color: Color(0x44000000), blurRadius: 24, offset: Offset(0, 8))];
        themeData = _buildTheme(Brightness.dark);
        break;
      case 'Ocean':
        background = Color(0xFF0F172A);
        surface = Color(0xFF1E293B);
        surfaceAlt = Color(0xFF334155);
        sidebar = Color(0xFF0B1120);
        textPrimary = Color(0xFFF8FAFC);
        textSecondary = Color(0xFF94A3B8);
        accent = Color(0xFF38BDF8);
        accentGlow = Color(0x4438BDF8);
        border = Color(0xFF475569);
        online = Color(0xFF34D399);
        auto_ = Color(0xFFFBBF24);
        gradientStart = Color(0xFF38BDF8);
        gradientEnd = Color(0xFF0EA5E9);
        cardShadow = [BoxShadow(color: Color(0x44000000), blurRadius: 16, offset: Offset(0, 4))];
        elevatedShadow = [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 8))];
        themeData = _buildTheme(Brightness.dark);
        break;
      case 'Sunset':
        background = Color(0xFF1C1017);
        surface = Color(0xFF2A1B22);
        surfaceAlt = Color(0xFF3D2830);
        sidebar = Color(0xFF140B10);
        textPrimary = Color(0xFFFFF0F5);
        textSecondary = Color(0xFFD4A5B8);
        accent = Color(0xFFFF6B6B);
        accentGlow = Color(0x44FF6B6B);
        border = Color(0xFF5A3848);
        online = Color(0xFF4ADE80);
        auto_ = Color(0xFFFBBF24);
        gradientStart = Color(0xFFFF6B6B);
        gradientEnd = Color(0xFFFF8E53);
        cardShadow = [BoxShadow(color: Color(0x44000000), blurRadius: 16, offset: Offset(0, 4))];
        elevatedShadow = [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 8))];
        themeData = _buildTheme(Brightness.dark);
        break;
      case 'Cyberpunk':
        background = Color(0xFF0A0A0F);
        surface = Color(0xFF14141F);
        surfaceAlt = Color(0xFF1E1E2E);
        sidebar = Color(0xFF06060A);
        textPrimary = Color(0xFFF0F0FF);
        textSecondary = Color(0xFFA0A0C0);
        accent = Color(0xFFBB86FC);
        accentGlow = Color(0x66BB86FC);
        border = Color(0xFF3A3A4E);
        online = Color(0xFF03DAC6);
        auto_ = Color(0xFFE879F9);
        gradientStart = Color(0xFFBB86FC);
        gradientMiddle = Color(0xFF9D6FE8);
        gradientEnd = Color(0xFF6200EE);
        cardShadow = [
          BoxShadow(color: Color(0x60000000), blurRadius: 24, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x33BB86FC), blurRadius: 50, offset: Offset(0, 0)),
          BoxShadow(color: Color(0x2203DAC6), blurRadius: 70, offset: Offset(0, 0)),
        ];
        elevatedShadow = [
          BoxShadow(color: Color(0x70000000), blurRadius: 32, offset: Offset(0, 10)),
          BoxShadow(color: Color(0x44BB86FC), blurRadius: 70, offset: Offset(0, 0)),
          BoxShadow(color: Color(0x3303DAC6), blurRadius: 90, offset: Offset(0, 0)),
        ];
        glowShadow = [
          BoxShadow(color: Color(0x55BB86FC), blurRadius: 40, offset: Offset(0, 0)),
          BoxShadow(color: Color(0x3303DAC6), blurRadius: 60, offset: Offset(0, 0)),
        ];
        themeData = _buildTheme(Brightness.dark);
        break;
      case 'Blossom':
        background = Color(0xFF1A0A14);
        surface = Color(0xFF2A1520);
        surfaceAlt = Color(0xFF3D202E);
        sidebar = Color(0xFF12060E);
        textPrimary = Color(0xFFFFF5FA);
        textSecondary = Color(0xFFE0A5BE);
        accent = Color(0xFFFF69B4);
        accentGlow = Color(0x66FF69B4);
        border = Color(0xFF5A2848);
        online = Color(0xFFFF69B4);
        auto_ = Color(0xFFFFB6C1);
        gradientStart = Color(0xFFFF69B4);
        gradientMiddle = Color(0xFFFF4DA6);
        gradientEnd = Color(0xFFFF1493);
        cardShadow = [
          BoxShadow(color: Color(0x50000000), blurRadius: 20, offset: Offset(0, 5)),
          BoxShadow(color: Color(0x33FF69B4), blurRadius: 40, offset: Offset(0, 0)),
          BoxShadow(color: Color(0x22FF1493), blurRadius: 60, offset: Offset(0, 0)),
        ];
        elevatedShadow = [
          BoxShadow(color: Color(0x60000000), blurRadius: 28, offset: Offset(0, 9)),
          BoxShadow(color: Color(0x44FF69B4), blurRadius: 60, offset: Offset(0, 0)),
          BoxShadow(color: Color(0x33FF1493), blurRadius: 80, offset: Offset(0, 0)),
        ];
        glowShadow = [
          BoxShadow(color: Color(0x55FF69B4), blurRadius: 50, offset: Offset(0, 0)),
        ];
        themeData = _buildTheme(Brightness.dark);
        break;
      case 'Light Blossom':
        background = Color(0xFFFFF8FB);
        surface = Color(0xFFFFFFFF);
        surfaceAlt = Color(0xFFFFE4EE);
        sidebar = Color(0xFFFFF0F7);
        textPrimary = Color(0xFF2D0A1F);
        textSecondary = Color(0xFF9B5A7E);
        accent = Color(0xFFFF69B4);
        accentGlow = Color(0x33FF69B4);
        border = Color(0xFFFFD1E8);
        online = Color(0xFFFF69B4);
        auto_ = Color(0xFFFF85C0);
        gradientStart = Color(0xFFFF69B4);
        gradientEnd = Color(0xFFFF1493);
        cardShadow = [BoxShadow(color: Color(0x0DFF69B4), blurRadius: 16, offset: Offset(0, 2))];
        elevatedShadow = [BoxShadow(color: Color(0x1AFF69B4), blurRadius: 24, offset: Offset(0, 4))];
        themeData = _buildTheme(Brightness.light);
        break;
      case 'Red Velvet':
        background = Color(0xFF1A0505);
        surface = Color(0xFF2A0F0F);
        surfaceAlt = Color(0xFF3D1818);
        sidebar = Color(0xFF120303);
        textPrimary = Color(0xFFFFF5F5);
        textSecondary = Color(0xFFE0A5A5);
        accent = Color(0xFFFF3333);
        accentGlow = Color(0x55FF3333);
        border = Color(0xFF5A1818);
        online = Color(0xFFFF4444);
        auto_ = Color(0xFFFF6666);
        gradientStart = Color(0xFFFF3333);
        gradientEnd = Color(0xFFDC143C);
        cardShadow = [BoxShadow(color: Color(0x44000000), blurRadius: 16, offset: Offset(0, 4)), BoxShadow(color: Color(0x22FF3333), blurRadius: 32, offset: Offset(0, 0))];
        elevatedShadow = [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 8)), BoxShadow(color: Color(0x33FF3333), blurRadius: 48, offset: Offset(0, 0))];
        themeData = _buildTheme(Brightness.dark);
        break;
      case 'Light Red Velvet':
        background = Color(0xFFFFF8F8);
        surface = Color(0xFFFFFFFF);
        surfaceAlt = Color(0xFFFFE4E4);
        sidebar = Color(0xFFFFF0F0);
        textPrimary = Color(0xFF2D0A0A);
        textSecondary = Color(0xFF9B5A5A);
        accent = Color(0xFFFF4444);
        accentGlow = Color(0x33FF4444);
        border = Color(0xFFFFD1D1);
        online = Color(0xFFFF4444);
        auto_ = Color(0xFFFF6666);
        gradientStart = Color(0xFFFF4444);
        gradientEnd = Color(0xFFDC143C);
        cardShadow = [BoxShadow(color: Color(0x0DFF4444), blurRadius: 16, offset: Offset(0, 2))];
        elevatedShadow = [BoxShadow(color: Color(0x1AFF4444), blurRadius: 24, offset: Offset(0, 4))];
        themeData = _buildTheme(Brightness.light);
        break;
      case 'Dark':
        background = Color(0xFF1A1A1A);
        surface = Color(0xFF242424);
        surfaceAlt = Color(0xFF2E2E2E);
        sidebar = Color(0xFF0F0F0F);
        textPrimary = Color(0xFFFAFAFA);
        textSecondary = Color(0xFFA0A0A0);
        accent = Color(0xFF10A37F);
        accentGlow = Color(0x5510A37F);
        border = Color(0xFF3A3A3A);
        online = Color(0xFF10A37F);
        auto_ = Color(0xFFFFA500);
        gradientStart = Color(0xFF10A37F);
        gradientMiddle = Color(0xFF0E9574);
        gradientEnd = Color(0xFF0D8A6B);
        cardShadow = [
          BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x1A10A37F), blurRadius: 40, offset: Offset(0, 0)),
        ];
        elevatedShadow = [
          BoxShadow(color: Color(0x50000000), blurRadius: 28, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x2210A37F), blurRadius: 60, offset: Offset(0, 0)),
        ];
        glowShadow = [
          BoxShadow(color: Color(0x3310A37F), blurRadius: 30, offset: Offset(0, 0)),
        ];
        themeData = _buildTheme(Brightness.dark);
        break;
      default:
        background = Color(0xFF212121);
        surface = Color(0xFF2F2F2F);
        surfaceAlt = Color(0xFF3A3A3A);
        sidebar = Color(0xFF171717);
        textPrimary = Color(0xFFF5F5F5);
        textSecondary = Color(0xFFB0B0B0);
        accent = Color(0xFF10A37F);
        accentGlow = Color(0x4410A37F);
        border = Color(0xFF4E4E4E);
        online = Color(0xFF10A37F);
        auto_ = Color(0xFFFFA500);
        gradientStart = Color(0xFF10A37F);
        gradientEnd = Color(0xFF0D8A6B);
        cardShadow = [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))];
        elevatedShadow = [BoxShadow(color: Color(0x44000000), blurRadius: 24, offset: Offset(0, 8))];
        themeData = _buildTheme(Brightness.dark);
        break;
    }
  }

  static ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: accent,
        surface: surface,
      ),
      fontFamily: 'Segoe UI',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: TextStyle(color: textSecondary),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(border),
        thickness: WidgetStateProperty.all(4),
      ),
    );
  }
}
