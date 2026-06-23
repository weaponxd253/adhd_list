// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'features/home/home_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class AppColors {
  // Brand
  static const primary      = Color(0xFF5B5BD6); // calm indigo
  static const primaryLight = Color(0xFFEEEEFF);
  static const accent       = Color(0xFFF97316); // warm orange (CTAs)

  // Semantic
  static const success      = Color(0xFF16A34A);
  static const successLight = Color(0xFFDCFCE7);
  static const warning      = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger       = Color(0xFFDC2626);
  static const dangerLight  = Color(0xFFFEE2E2);

  // Neutral
  static const bg           = Color(0xFFF5F5FB);
  static const surface      = Color(0xFFFFFFFF);
  static const border       = Color(0xFFE4E4F0);
  static const textHigh     = Color(0xFF1A1A2E);
  static const textMid      = Color(0xFF6B6B8A);
  static const textLow      = Color(0xFFAAAAAA);

  // Dark equivalents
  static const bgDark       = Color(0xFF0F0F1A);
  static const surfaceDark  = Color(0xFF1A1A2E);
  static const borderDark   = Color(0xFF2D2D44);
  static const textHighDark = Color(0xFFF0F0FF);
  static const textMidDark  = Color(0xFF9898B8);
}

// ─── Themes ───────────────────────────────────────────────────────────────────
ThemeData _buildTheme({required bool dark}) {
  final cs = dark
      ? ColorScheme.dark(
          primary: const Color(0xFF818CF8),
          secondary: AppColors.accent,
          surface: AppColors.surfaceDark,
          background: AppColors.bgDark,
          onPrimary: Colors.white,
          onSurface: AppColors.textHighDark,
        )
      : ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          background: AppColors.bg,
          onPrimary: Colors.white,
          onSurface: AppColors.textHigh,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: cs,
    scaffoldBackgroundColor: dark ? AppColors.bgDark : AppColors.bg,

    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.surfaceDark : AppColors.surface,
      foregroundColor: dark ? AppColors.textHighDark : AppColors.textHigh,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        color: dark ? AppColors.textHighDark : AppColors.textHigh,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),

    cardTheme: CardTheme(
      color: dark ? AppColors.surfaceDark : AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: dark ? AppColors.borderDark : AppColors.border,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.surfaceDark : AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? AppColors.borderDark : AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? AppColors.borderDark : AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF818CF8) : AppColors.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: dark ? AppColors.textMidDark : AppColors.textMid),
      hintStyle: TextStyle(color: dark ? AppColors.textMidDark : AppColors.textLow),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: dark ? const Color(0xFF818CF8) : AppColors.primary,
      ),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((s) =>
          s.contains(MaterialState.selected)
              ? (dark ? const Color(0xFF818CF8) : AppColors.primary)
              : Colors.transparent),
      checkColor: MaterialStateProperty.all(Colors.white),
      side: BorderSide(
        color: dark ? AppColors.borderDark : AppColors.border,
        width: 2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: dark ? AppColors.surfaceDark : AppColors.surface,
      selectedItemColor: dark ? const Color(0xFF818CF8) : AppColors.primary,
      unselectedItemColor: dark ? AppColors.textMidDark : AppColors.textLow,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
    ),

    dividerTheme: DividerThemeData(
      color: dark ? AppColors.borderDark : AppColors.border,
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: dark ? const Color(0xFF2D2D44) : AppColors.textHigh,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    ),

    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: dark ? AppColors.textHighDark : AppColors.textHigh,
        fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        color: dark ? AppColors.textHighDark : AppColors.textHigh,
        fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        color: dark ? AppColors.textHighDark : AppColors.textHigh,
        fontSize: 18, fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: dark ? AppColors.textHighDark : AppColors.textHigh,
        fontSize: 16, fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: dark ? AppColors.textHighDark : AppColors.textHigh,
        fontSize: 15,
      ),
      bodyMedium: TextStyle(
        color: dark ? AppColors.textMidDark : AppColors.textMid,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: dark ? AppColors.textMidDark : AppColors.textLow,
        fontSize: 12,
      ),
    ),
  );
}

final lightTheme = _buildTheme(dark: false);
final darkTheme  = _buildTheme(dark: true);

// ─── Entry point ──────────────────────────────────────────────────────────────
void main() {
  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'FocusFlow',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: appState.themeMode,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}