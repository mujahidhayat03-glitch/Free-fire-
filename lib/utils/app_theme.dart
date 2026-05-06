// lib/utils/app_theme.dart — FF PRO ARENA PK — Enhanced Free Fire Theme
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background    = Color(0xFF050A0E);
  static const Color surface       = Color(0xFF0D1117);
  static const Color surfaceLight  = Color(0xFF161B22);
  static const Color cardBg        = Color(0xFF0F1419);
  static const Color neonGreen     = Color(0xFF00FF88);
  static const Color neonGreenDark = Color(0xFF00CC6A);
  static const Color neonBlue      = Color(0xFF00D4FF);
  static const Color gold          = Color(0xFFFFD700);
  static const Color goldDark      = Color(0xFFB8860B);
  static const Color silver        = Color(0xFFC0C0C0);
  static const Color accent        = Color(0xFFFF6B00);
  static const Color accentPurple  = Color(0xFF7C4DFF);
  static const Color danger        = Color(0xFFFF3D3D);
  static const Color warning       = Color(0xFFFFAA00);
  static const Color textPrimary   = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textMuted     = Color(0xFF3D4D5C);
  static const Color divider       = Color(0xFF1E2936);
  static const Color online        = Color(0xFF00FF88);
  static const Color offline       = Color(0xFF3D4D5C);

  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonGreen, neonBlue],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFFF6B00), Color(0xFFFFD700), Color(0xFFFF3D3D)],
    begin: Alignment.bottomLeft, end: Alignment.topRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFFD700)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0F1419), Color(0xFF0A0F14)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF050A0E), Color(0xFF080E14), Color(0xFF050A0E)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF050A0E), Color(0xFF0A1520), Color(0xFF001A0A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static List<BoxShadow> neonGlow = [
    BoxShadow(color: neonGreen.withOpacity(0.4), blurRadius: 24, spreadRadius: 2),
    BoxShadow(color: neonGreen.withOpacity(0.15), blurRadius: 48, spreadRadius: 8),
  ];
  static List<BoxShadow> fireGlow = [
    BoxShadow(color: accent.withOpacity(0.5), blurRadius: 24, spreadRadius: 2),
    BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.2), blurRadius: 48, spreadRadius: 8),
  ];
  static List<BoxShadow> goldGlow = [
    BoxShadow(color: gold.withOpacity(0.5), blurRadius: 24, spreadRadius: 2),
    BoxShadow(color: gold.withOpacity(0.2), blurRadius: 48, spreadRadius: 8),
  ];
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> blueGlow = [
    BoxShadow(color: neonBlue.withOpacity(0.4), blurRadius: 24, spreadRadius: 2),
    BoxShadow(color: neonBlue.withOpacity(0.15), blurRadius: 48, spreadRadius: 8),
  ];

  static TextStyle get heading1 => GoogleFonts.rajdhani(
        fontSize: 32, fontWeight: FontWeight.w800,
        color: textPrimary, letterSpacing: 2.0);
  static TextStyle get heading2 => GoogleFonts.rajdhani(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: textPrimary, letterSpacing: 1.5);
  static TextStyle get heading3 => GoogleFonts.rajdhani(
        fontSize: 17, fontWeight: FontWeight.w600,
        color: textPrimary, letterSpacing: 1.0);
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, color: textPrimary, fontWeight: FontWeight.w500);
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, color: textPrimary);
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12, color: textSecondary);
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11, color: textMuted, letterSpacing: 0.5);
  static TextStyle get neonLabel => GoogleFonts.rajdhani(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: neonGreen, letterSpacing: 1.5);
  static TextStyle get goldLabel => GoogleFonts.rajdhani(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: gold, letterSpacing: 1.5);
  static TextStyle get fireLabel => GoogleFonts.rajdhani(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: accent, letterSpacing: 1.5);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: neonGreen,
        colorScheme: const ColorScheme.dark(
          primary: neonGreen, secondary: gold,
          surface: surface, background: background, error: danger,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface, elevation: 0,
          iconTheme: const IconThemeData(color: textPrimary),
          titleTextStyle: GoogleFonts.rajdhani(
            color: textPrimary, fontSize: 20,
            fontWeight: FontWeight.w700, letterSpacing: 1.2,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: neonGreen,
          unselectedItemColor: textMuted,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: surfaceLight,
          hintStyle: const TextStyle(color: textMuted, fontSize: 13),
          labelStyle: GoogleFonts.rajdhani(color: textSecondary, fontWeight: FontWeight.w600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: divider, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: neonGreen, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: danger)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonGreen, foregroundColor: background,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 1.2),
            elevation: 0,
          ),
        ),
        cardTheme: CardTheme(
          color: cardBg, elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: divider, width: 0.5),
          ),
        ),
        dividerTheme: const DividerThemeData(color: divider, thickness: 0.5),
        iconTheme: const IconThemeData(color: textSecondary),
      );
}

class AppConstants {
  static const String appName    = 'FF PRO ARENA PK';
  static const String appVersion = '2.0.0';

  // Admin credentials (for local UI routing + Firebase check)
  static const String adminPhone    = '03180640250';
  static const String adminPassword = '007123';

  static const String usersCol        = 'users';
  static const String tournamentsCol  = 'tournaments';
  static const String messagesCol     = 'messages';
  static const String transactionsCol = 'transactions';
  static const String notificationsCol = 'notifications';
  static const String roomInfoCol     = 'room_info';

  static const List<String> ffMaps = [
    'Bermuda', 'Purgatory', 'Kalahari', 'Alpine', 'Neextarra'
  ];
  static const List<String> gameModes = ['Solo', 'Duo', 'Squad'];

  static const String roleUser  = 'user';
  static const String roleVip   = 'vip';
  static const String roleAdmin = 'admin';

  static const String walletDeposit    = 'deposit';
  static const String walletWithdrawal = 'withdrawal';
  static const String walletWinning    = 'winning';
  static const String walletBonus      = 'bonus';
  static const String walletDeduction  = 'deduction';

  static const String statusPending  = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  static const String tournamentUpcoming = 'upcoming';
  static const String tournamentLive     = 'live';
  static const String tournamentEnded    = 'ended';
}
