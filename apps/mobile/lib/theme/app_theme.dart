import 'package:flutter/material.dart';

/// Design tokens and Material 3 theme configuration for the PLANT Agricultural Platform.
/// Engineered for smallholder farmers and agricultural extension officers:
/// - High outdoor legibility and contrast under sunlight
/// - Accessible touch target baselines (min 48dp)
/// - Organic, trust-inducing agricultural palette (Deep Forest, Emerald, Wheat & Earth)
class AppTheme {
  // --- Core Brand Colors (Forest & Agricultural Earth) ---
  static const Color primaryGreen = Color(0xFF1B4332);      // Deep Forest Green
  static const Color mediumGreen = Color(0xFF2D6A4F);       // Lush Foliage
  static const Color lightGreen = Color(0xFF52B788);        // Sprout Green / Emerald
  static const Color paleGreen = Color(0xFFD8F3DC);         // Soft Mint Tint
  static const Color surfaceGreen = Color(0xFFE8F5E9);      // Muted Leaf Surface
  static const Color earthYellow = Color(0xFFD4A373);       // Harvest Wheat / Clay
  static const Color earthBrown = Color(0xFF8B5A2B);        // Rich Loam Soil
  
  // --- Functional & Semantic Status Colors ---
  static const Color warningOrange = Color(0xFFE76F51);     // Urgent Pest Alert / Error
  static const Color cautionAmber = Color(0xFFF4A261);      // Moderate Advisory Warning
  static const Color infoBlue = Color(0xFF2A9D8F);          // Water / Weather / Guidance
  static const Color successGreen = Color(0xFF2E7D32);      // Healthy Crop / Success

  // --- Surfaces, Neutrals & High-Contrast Outdoor Legibility ---
  static const Color surfaceBg = Color(0xFFF9FBF9);         // Pristine Field Canvas
  static const Color cardBg = Colors.white;                 // Crisp White Container
  static const Color darkText = Color(0xFF1C1917);          // High-contrast Deep Onyx
  static const Color mediumText = Color(0xFF4A5568);        // Slate Secondary Text
  static const Color subtleText = Color(0xFF718096);        // Accessible Muted Details
  static const Color borderLight = Color(0xFFE2E8F0);       // Soft Divider & Card Border

  // --- Geometry & Elevation Tokens ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;
  static const double minTouchTarget = 48.0;

  /// Semantic Card Decoration for custom container styling across dashboard cards
  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double borderRadius = radiusLarge,
    double elevation = 1,
  }) {
    return BoxDecoration(
      color: color ?? cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? borderLight, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: elevation * 0.04),
          blurRadius: elevation * 4 + 2,
          offset: Offset(0, elevation * 1.5 + 1),
        ),
      ],
    );
  }

  /// Banner / Hero Gradient for Headers & Action Highlights
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, mediumGreen],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        onPrimary: Colors.white,
        primaryContainer: paleGreen,
        onPrimaryContainer: primaryGreen,
        secondary: mediumGreen,
        onSecondary: Colors.white,
        secondaryContainer: surfaceGreen,
        onSecondaryContainer: primaryGreen,
        tertiary: earthYellow,
        onTertiary: darkText,
        surface: surfaceBg,
        onSurface: darkText,
        error: warningOrange,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: surfaceBg,

      // Typography designed for clarity & outdoor sunlight readability
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: darkText,
          letterSpacing: -0.5,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkText,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkText,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkText,
          letterSpacing: 0.1,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkText,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: mediumText,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkText,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: mediumText,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: subtleText,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Card Theme with subtle border and crisp elevation
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
      ),

      // Button Themes ensuring >= 48dp height for outdoor field touch targets
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 1,
          shadowColor: primaryGreen.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme for forms, text fields, and logins
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: mediumGreen, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: warningOrange, width: 1.5),
        ),
        labelStyle: const TextStyle(color: mediumText),
        hintStyle: const TextStyle(color: subtleText, fontSize: 14),
      ),

      // Navigation Bar (Material 3 bottom navigation)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black12,
        indicatorColor: paleGreen,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 24);
          }
          return const IconThemeData(color: mediumText, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mediumText,
          );
        }),
      ),

      // Chip Theme for Crop Pickers & Filter Badges
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        disabledColor: borderLight,
        selectedColor: paleGreen,
        secondarySelectedColor: paleGreen,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 13, color: darkText, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.bold),
        side: const BorderSide(color: borderLight, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Divider & Progress Indicators
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightGreen,
        linearTrackColor: paleGreen,
        circularTrackColor: paleGreen,
      ),
    );
  }
}
