import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadii {
  static const control = 12.0;
  static const card = 16.0;
  static const pill = 999.0;
}

abstract final class AppSizes {
  static const minimumTouchTarget = 48.0;
  static const navigationHeight = 72.0;
}

abstract final class AppInsets {
  static double bottomScrollPadding(
    BuildContext context, {
    double extra = AppSpacing.lg,
  }) {
    return extra + MediaQuery.paddingOf(context).bottom;
  }

  static double bottomNavigationScrollPadding(
    BuildContext context, {
    double extra = AppSpacing.lg,
  }) {
    return AppSizes.navigationHeight +
        extra +
        MediaQuery.paddingOf(context).bottom;
  }

  static EdgeInsets screenScrollPadding(
    BuildContext context, {
    double left = AppSpacing.md,
    double top = AppSpacing.sm,
    double right = AppSpacing.md,
    double bottom = AppSpacing.lg,
  }) {
    return EdgeInsets.fromLTRB(
      left,
      top,
      right,
      bottomScrollPadding(context, extra: bottom),
    );
  }
}

abstract final class AppColors {
  static const primary = Color(0xFF5656D6);
  static const primaryDark = Color(0xFF8B92FF);
  static const accent = Color(0xFFF97316);

  static const background = Color(0xFFF7F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F0F8);
  static const border = Color(0xFFDCDCE8);
  static const text = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF5F6078);

  static const backgroundDark = Color(0xFF111119);
  static const surfaceDark = Color(0xFF1B1B2D);
  static const surfaceVariantDark = Color(0xFF24243A);
  static const borderDark = Color(0xFF3B3B54);
  static const textDark = Color(0xFFF4F4FF);
  static const textSecondaryDark = Color(0xFFB6B6CC);

  static const success = Color(0xFF15803D);
  static const successDark = Color(0xFF4ADE80);
  static const warning = Color(0xFFB45309);
  static const warningDark = Color(0xFFFBBF24);
  static const danger = Color(0xFFB91C1C);
  static const dangerDark = Color(0xFFF87171);
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color success;
  final Color warning;
  final Color danger;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppSemanticColors lerp(
    covariant ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static SystemUiOverlayStyle systemOverlayStyle(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final iconBrightness = dark ? Brightness.light : Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: surface,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: surface,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor:
          dark ? AppColors.borderDark : AppColors.border,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? AppColors.primaryDark : AppColors.primary;
    final background = dark ? AppColors.backgroundDark : AppColors.background;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant =
        dark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final border = dark ? AppColors.borderDark : AppColors.border;
    final text = dark ? AppColors.textDark : AppColors.text;
    final secondaryText =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer:
          dark ? const Color(0xFF30305F) : const Color(0xFFE8E8FF),
      onPrimaryContainer: dark ? AppColors.textDark : AppColors.text,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer:
          dark ? const Color(0xFF4A2B18) : const Color(0xFFFFE7D5),
      onSecondaryContainer: text,
      error: dark ? AppColors.dangerDark : AppColors.danger,
      onError: Colors.white,
      errorContainer: dark ? const Color(0xFF4D2027) : const Color(0xFFFFE1E1),
      onErrorContainer: text,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: secondaryText,
      outline: border,
      outlineVariant: border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? AppColors.surface : AppColors.surfaceDark,
      onInverseSurface: dark ? AppColors.text : AppColors.textDark,
      inversePrimary: dark ? AppColors.primary : AppColors.primaryDark,
    );

    final baseTextTheme = Typography.material2021().black;
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: TextStyle(
        color: text,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: text,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: text,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: text,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(color: secondaryText, fontSize: 14, height: 1.45),
      bodySmall: TextStyle(color: secondaryText, fontSize: 12, height: 1.4),
      labelLarge: TextStyle(
        color: text,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: primary.withOpacity(0.18),
      hoverColor: primary.withOpacity(0.08),
      splashFactory: InkSparkle.splashFactory,
      extensions: [
        AppSemanticColors(
          success: dark ? AppColors.successDark : AppColors.success,
          warning: dark ? AppColors.warningDark : AppColors.warning,
          danger: dark ? AppColors.dangerDark : AppColors.danger,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: systemOverlayStyle(brightness),
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navigationHeight,
        backgroundColor: surface,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color:
                states.contains(WidgetState.selected) ? primary : secondaryText,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color:
                states.contains(WidgetState.selected) ? primary : secondaryText,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: TextStyle(color: secondaryText),
        labelStyle: TextStyle(color: secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
              AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
              AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
          foregroundColor: primary,
          side: BorderSide(color: border),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
              AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
          foregroundColor: primary,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
              AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
          foregroundColor: secondaryText,
          focusColor: primary.withOpacity(0.18),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: secondaryText, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.surfaceVariantDark : AppColors.text,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        textStyle: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: BoxDecoration(
          color: dark ? AppColors.textSecondary : AppColors.text,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
      ),
    );
  }
}
