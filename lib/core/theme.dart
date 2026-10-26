import 'package:flutter/material.dart';

/// Editorial travel palette: ivory, clay, charcoal and a quiet sea blue.
class Palette {
  static const paper = Color(0xFFFAF6EE),
      surface = Color(0xFFFFFCF7),
      ink = Color(0xFF2E2C29),
      muted = Color(0xFF71685F),
      terracotta = Color(0xFFE2795F),
      clay = Color(0xFFA64B37),
      sea = Color(0xFF7CA7B3),
      forest = clay,
      gold = Color(0xFFF1D5B5),
      sage = Color(0xFFF4E8DF),
      line = Color(0xFFE6DED3),
      error = Color(0xFFA33F35);
}

ThemeData travelTheme([bool dark = false]) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Palette.terracotta,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: dark ? const Color(0xFFF2A58E) : Palette.clay,
        onPrimary: dark ? Palette.ink : Colors.white,
        primaryContainer: dark ? const Color(0xFF48332B) : Palette.sage,
        onPrimaryContainer: dark ? const Color(0xFFF7D8C9) : Palette.ink,
        secondary: dark ? const Color(0xFFAFCBD1) : const Color(0xFF4D7480),
        secondaryContainer: dark
            ? const Color(0xFF293B3F)
            : const Color(0xFFE7EFF0),
        onSecondaryContainer: dark ? const Color(0xFFD8E6E8) : Palette.ink,
        surface: dark ? const Color(0xFF292522) : Palette.surface,
        onSurface: dark ? const Color(0xFFF8F0E5) : Palette.ink,
        onSurfaceVariant: dark ? const Color(0xFFC6B9AA) : Palette.muted,
        outline: dark ? const Color(0xFF756A5E) : Palette.line,
        error: dark ? const Color(0xFFFFB4AA) : Palette.error,
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'GolosText',
  );
  TextStyle serif(double size, {FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: 'Cormorant',
        fontSize: size,
        height: 1.12,
        fontWeight: weight,
        color: scheme.onSurface,
        letterSpacing: -.45,
      );
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF211E1B) : Palette.paper,
    textTheme: base.textTheme.copyWith(
      headlineLarge: serif(32),
      headlineMedium: serif(30),
      titleLarge: serif(25, weight: FontWeight.w600),
      titleMedium: serif(23, weight: FontWeight.w600),
      titleSmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: scheme.onSurface),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: .1,
        color: scheme.onSurface,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF211E1B) : Palette.paper,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 4,
      toolbarHeight: 68,
      titleTextStyle: serif(30),
      iconTheme: IconThemeData(size: 22, color: scheme.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.terracotta,
        foregroundColor: Palette.ink,
        disabledBackgroundColor: dark
            ? const Color(0xFF453C35)
            : const Color(0xFFE9DFD4),
        disabledForegroundColor: dark
            ? const Color(0xFFBEAE9C)
            : const Color(0xFF776B60),
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: .1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size(48, 52),
        side: BorderSide(color: dark ? Colors.white24 : Palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? scheme.surface : const Color(0xFFF6F0E7),
      hintStyle: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: dark ? Colors.white10 : Palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: dark ? scheme.surface : const Color(0xFFF3EDE4),
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      dragHandleColor: dark ? Colors.white24 : Palette.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    dividerTheme: DividerThemeData(
      color: dark ? Colors.white12 : Palette.line,
      space: 24,
      thickness: .7,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
